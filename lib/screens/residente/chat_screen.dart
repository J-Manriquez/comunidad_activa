import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/mensaje_model.dart';
import '../../services/mensaje_service.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final String chatId;
  final String nombreChat;
  final bool esGrupal;

  const ChatScreen({
    Key? key,
    required this.currentUser,
    required this.chatId,
    required this.nombreChat,
    required this.esGrupal,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MensajeService _mensajeService = MensajeService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, String> _nombresUsuarios = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarNombresUsuarios();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombresUsuarios() async {
    try {
      if (widget.esGrupal) {
        // Cargar nombres de todos los residentes y administrador
        final residentes = await _firestoreService
            .obtenerResidentesCondominio(widget.currentUser.condominioId.toString());
        final admin = await _firestoreService
            .getAdministradorData(widget.currentUser.condominioId.toString());

        Map<String, String> nombres = {};
        for (final residente in residentes) {
          nombres[residente.uid] = residente.nombre;
        }
        if (admin != null) {
          nombres[admin.uid] = '${admin.nombre} (Admin)';
        }

        if (mounted) {
          setState(() {
            _nombresUsuarios = nombres;
          });
        }
      }
    } catch (e) {
      print('❌ Error al cargar nombres de usuarios: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreChat,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: StreamBuilder<List<ContenidoMensajeModel>>(
              stream: _mensajeService.obtenerMensajesChat(
                condominioId: widget.currentUser.condominioId.toString(),
                chatId: widget.chatId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar mensajes: ${snapshot.error}'),
                  );
                }

                final mensajes = snapshot.data ?? [];

                if (mensajes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún.\n¡Envía el primer mensaje!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Marcar mensajes como leídos
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _marcarMensajesComoLeidos(mensajes);
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    return _buildMensajeCard(mensaje);
                  },
                );
              },
            ),
          ),
          // Campo de entrada de mensaje
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMensajeCard(ContenidoMensajeModel mensaje) {
    final esMiMensaje = mensaje.autorUid == widget.currentUser.uid;
    final nombreAutor = widget.esGrupal 
        ? _nombresUsuarios[mensaje.autorUid] ?? 'Usuario'
        : null;
    
    return Align(
      alignment: esMiMensaje ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: esMiMensaje ? Colors.blue[100] : Colors.grey[100],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar nombre del autor en chats grupales
                if (widget.esGrupal && !esMiMensaje && nombreAutor != null) ...[
                  Text(
                    nombreAutor,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                // Contenido del mensaje
                Text(
                  mensaje.texto ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Información del mensaje
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(
                        DateTime.parse(mensaje.fechaHoraCreacion),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (esMiMensaje) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _mostrarInfoLectura(mensaje),
                        child: Icon(
                          _esMensajeLeido(mensaje) 
                              ? Icons.done_all 
                              : Icons.done,
                          size: 16,
                          color: _esMensajeLeido(mensaje) 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue[700],
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _enviarMensaje,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _mensajeService.enviarMensaje(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: widget.chatId,
        texto: texto,
        autorUid: widget.currentUser.uid,
      );

      _messageController.clear();
      
      // Scroll al final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarMensajesComoLeidos(List<ContenidoMensajeModel> mensajes) async {
    try {
      final residente = await _firestoreService.getResidenteData(
        widget.currentUser.uid,
      );
      
      if (residente == null) return;

      for (final mensaje in mensajes) {
        // Solo marcar como leído si no es mi mensaje y no está marcado como leído
        if (mensaje.autorUid != widget.currentUser.uid &&
            (mensaje.isRead == null || 
             !mensaje.isRead!.containsKey(widget.currentUser.uid))) {
          await _mensajeService.marcarMensajeComoLeido(
            condominioId: widget.currentUser.condominioId.toString(),
            chatId: widget.chatId,
            contenidoId: mensaje.id,
            usuarioId: widget.currentUser.uid,
            nombreUsuario: residente.nombre,
          );
        }
      }
    } catch (e) {
      print('❌ Error al marcar mensajes como leídos: $e');
    }
  }

  bool _esMensajeLeido(ContenidoMensajeModel mensaje) {
    if (mensaje.isRead == null) return false;
    
    // En chat privado, verificar si el otro usuario lo leyó
    if (!widget.esGrupal) {
      return mensaje.isRead!.keys.any((key) => key != widget.currentUser.uid);
    }
    
    // En chat grupal, verificar si al menos alguien lo leyó
    return mensaje.isRead!.isNotEmpty;
  }

  void _mostrarInfoLectura(ContenidoMensajeModel mensaje) {
    if (mensaje.isRead == null || mensaje.isRead!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensaje no leído'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Lectura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: mensaje.isRead!.entries.map((entry) {
            final userId = entry.key;
            final readInfo = entry.value as Map<String, dynamic>;
            final nombre = readInfo['nombre'] ?? 'Usuario';
            final fechaHora = readInfo['fechaHora'] ?? '';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.done_all, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (fechaHora.isNotEmpty)
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(
                              DateTime.parse(fechaHora),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}