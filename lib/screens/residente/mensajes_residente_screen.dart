import 'package:comunidad_activa/models/administrador_model.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/mensaje_model.dart';
import '../../models/residente_model.dart';
import '../../services/mensaje_service.dart';
import '../../services/firestore_service.dart';
import '../../services/unread_messages_service.dart';
import '../../widgets/unread_messages_badge.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class MensajesResidenteScreen extends StatefulWidget {
  final UserModel currentUser;

  const MensajesResidenteScreen({Key? key, required this.currentUser})
    : super(key: key);

  @override
  _MensajesResidenteScreenState createState() =>
      _MensajesResidenteScreenState();
}

class _MensajesResidenteScreenState extends State<MensajesResidenteScreen> {
  final MensajeService _mensajeService = MensajeService();
  final FirestoreService _firestoreService = FirestoreService();
  final UnreadMessagesService _unreadService = UnreadMessagesService();
  bool _comunicacionEntreResidentesHabilitada = false;
  bool _permitirMensajesResidentes = true;
  String? _chatGrupalId;
  String? _chatConserjeriaId;
  String? _chatAdministradorId;

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
    _cargarChatsIds();
  }

  @override
  void dispose() {
    _unreadService.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguraciones() async {
    try {
      final comunicacionHabilitada = await _mensajeService
          .esComunicacionEntreResidentesHabilitada(
            widget.currentUser.condominioId.toString(),
          );

      final permiteMensajes = await _mensajeService.residentePermiteMensajes(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _comunicacionEntreResidentesHabilitada = comunicacionHabilitada;
          _permitirMensajesResidentes = permiteMensajes;
        });
      }
    } catch (e) {
      print('❌ Error al cargar configuraciones: $e');
    }
  }

  Future<void> _cargarChatsIds() async {
    try {
      // Cargar chat grupal
      final chatGrupalId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Cargar chat conserjería
      final chatConserjeriaId = await _mensajeService.crearOObtenerChatConserjeria(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );

      // Cargar chat administrador
      final administrador = await _firestoreService.getAdministradorData(
        widget.currentUser.condominioId.toString(),
      );
      
      String? chatAdministradorId;
      if (administrador != null) {
        chatAdministradorId = await _mensajeService.crearOObtenerChatPrivado(
          condominioId: widget.currentUser.condominioId.toString(),
          usuario1Id: widget.currentUser.uid,
          usuario2Id: administrador.uid,
          tipo: 'admin-residente',
        );
      }

      if (mounted) {
        setState(() {
          _chatGrupalId = chatGrupalId;
          _chatConserjeriaId = chatConserjeriaId;
          _chatAdministradorId = chatAdministradorId;
        });
      }
    } catch (e) {
      print('❌ Error al cargar IDs de chats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mensajes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_comunicacionEntreResidentesHabilitada)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _mostrarConfiguracionMensajes,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat grupal del condominio
          _buildChatGrupalCard(),
          const SizedBox(height: 4),

          // Chat con conserjería
          _buildChatConserjeriaCard(),
          const SizedBox(height: 4),

          // ✅ NUEVO: Chat con administrador
          _buildChatAdministradorCard(),
          const SizedBox(height: 8),

          if (_comunicacionEntreResidentesHabilitada &&
              _permitirMensajesResidentes) ...[
            Padding(
              padding: EdgeInsets.all(0),
              child: Text(
                'Chats con Residentes',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Lista de chats
            Expanded(
              child: StreamBuilder<List<MensajeModel>>(
                stream: _mensajeService.obtenerChatsUsuario(
                  condominioId: widget.currentUser.condominioId.toString(),
                  usuarioId: widget.currentUser.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar chats: ${snapshot.error}'),
                    );
                  }

                  final chats = snapshot.data ?? [];
                  // CORREGIR: Incluir chats con conserjería y otros residentes
                  final chatsPrivados = chats
                      .where(
                        (chat) =>
                            !chat.participantes.contains('GRUPO_CONDOMINIO') &&
                            chat.tipo != 'grupal' &&
                            chat.tipo != 'conserjeria' &&
                            chat.tipo != 'admin-residente',
                      )
                      .toList();

                  if (chatsPrivados.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No tienes conversaciones aún.\nUsa el botón + para iniciar una conversación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    );
                  }
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Chats con Residentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatsPrivados.length,
                    itemBuilder: (context, index) {
                      final chat = chatsPrivados[index];
                      final otroParticipante = chat.participantes
                          .where((p) => p != widget.currentUser.uid)
                          .firstOrNull;

                      // Solo mostrar el chat si hay otro participante válido
                      if (otroParticipante == null) {
                        return const SizedBox.shrink(); // No mostrar nada si no hay otro participante
                      }
                      return _buildChatCard(chat, otroParticipante);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _comunicacionEntreResidentesHabilitada
          ? FloatingActionButton(
              onPressed: _mostrarModalBuscarResidentes,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
    );
  }

  // Agregar después del chat con conserjería
  Widget _buildChatAdministradorCard() {
    if (_chatAdministradorId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 1),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: _chatAdministradorId!,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: const Text(
            'Administrador',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Chat con el administrador del condominio',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.all(16),
          onTap: _abrirChatAdministrador,
        ),
      ),
    );
  }

  // Método para abrir chat con administrador
  Future<void> _abrirChatAdministrador() async {
    try {
      // Obtener datos del administrador
      final admin = await _firestoreService.getAdministradorData(
        widget.currentUser.condominioId.toString(),
      );

      if (admin == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo encontrar al administrador'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: admin.uid,
        tipo: 'admin-residente', // ✅ Usar el mismo tipo que usa el admin
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: admin.nombre,
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con administrador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NUEVO: Widget para chat con conserjería
  Widget _buildChatConserjeriaCard() {
    if (_chatConserjeriaId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200, width: 2),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: _chatConserjeriaId!,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          leading: CircleAvatar(
            backgroundColor: Colors.orange[100],
            radius: 25,
            child: Icon(
              Icons.security,
              color: Colors.orange[700],
              size: 28,
            ),
          ),
          title: const Text(
            'Conserjería',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Chat con el personal de conserjería',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.all(16),
          onTap: () => _abrirChatConserjeria(),
        ),
      ),
    );
  }

  // NUEVO: Método para abrir chat con conserjería
  Future<void> _abrirChatConserjeria() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatConserjeria(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: 'Conserjería',
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con conserjería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildChatGrupalCard() {
    if (_chatGrupalId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: _chatGrupalId!,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment, color: Colors.white, size: 28),
          ),
          title: const Text(
            'Chat del Condominio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: const Text(
            'Chat general con todos los residentes',
            style: TextStyle(fontSize: 14),
          ),
          contentPadding: const EdgeInsets.all(16),
          onTap: () => _abrirChatGrupal(),
        ),
      ),
    );
  }

  Widget _buildChatCard(MensajeModel chat, String otroParticipante) {
    // Chat con otro residente o administrador
    print('Participantes: ${chat.participantes}');
    print('Residente ID: ${widget.currentUser.uid}');
    print('Otro participante: $otroParticipante');

    return FutureBuilder<ResidenteModel?>(
      future: _firestoreService.getResidenteData(otroParticipante),
      builder: (context, residenteSnapshot) {
        if (residenteSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Cargando...'),
            ),
          );
        }

        if (residenteSnapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.error, color: Colors.red),
              title: Text('Error al cargar usuario'),
              subtitle: Text('${residenteSnapshot.error}'),
            ),
          );
        }

        print('Residente: ${residenteSnapshot.data}');
        print('Residente nombre: ${residenteSnapshot.data?.nombre}');

        // Obtener el nombre del residente y la descripción de la vivienda
        final residente = residenteSnapshot.data;

        // Si no se encuentra el residente, intentar buscar como administrador
        if (residente == null) {
          return FutureBuilder<AdministradorModel?>(
            future: _firestoreService.getAdministradorData(
              widget.currentUser.condominioId.toString(),
            ),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Cargando...'),
                  ),
                );
              }

              final admin = adminSnapshot.data;
              final nombreUsuario = admin?.nombre ?? 'Usuario Desconocido';
              final tipoUsuario = admin != null ? 'Administrador' : 'Usuario';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  elevation: 4,
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade200, width: 2),
                  ),
                  child: UnreadMessagesListTile(
                    condominioId: widget.currentUser.condominioId.toString(),
                    chatId: chat.id,
                    usuarioId: widget.currentUser.uid,
                    unreadService: _unreadService,
                    leading: CircleAvatar(
                      backgroundColor: admin != null
                          ? Colors.red[100]
                          : Colors.grey[100],
                      radius: 25,
                      child: Icon(
                        admin != null
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: admin != null
                            ? Colors.red[700]
                            : Colors.grey[700],
                        size: 28,
                      ),
                    ),
                    title: Text(
                      nombreUsuario,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tipoUsuario,
                      style: const TextStyle(fontSize: 12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                     onTap: () => _abrirChatPrivado(chat, nombreUsuario),
                  ),
                ),
              );
            },
          );
        }

        final nombreResidente = residente.nombre;
        final vivienda = residente.descripcionVivienda;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: 4,
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade200, width: 2),
            ),
            child: UnreadMessagesListTile(
              condominioId: widget.currentUser.condominioId.toString(),
              chatId: chat.id,
              usuarioId: widget.currentUser.uid,
              unreadService: _unreadService,
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                radius: 25,
                child: Icon(Icons.person, color: Colors.green[700], size: 28),
              ),
              title: Text(
                nombreResidente,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                vivienda ?? 'Sin vivienda asignada',
                style: const TextStyle(fontSize: 12),
              ),
              contentPadding: const EdgeInsets.all(16),
              onTap: () => _abrirChatPrivado(chat, nombreResidente),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirChatGrupal() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: 'Chat General del Condominio',
              esGrupal: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat grupal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para abrir chat privado con otro residente
  Future<void> _abrirChatPrivado(MensajeModel chat, String nombreResidente) async {
    try {
      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chat.id,
        usuarioId: widget.currentUser.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chat.id,
              nombreChat: nombreResidente,
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirChat(String chatId, String nombreChat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUser,
          chatId: chatId,
          nombreChat: nombreChat,
          esGrupal: false,
        ),
      ),
    );
  }

  void _mostrarModalBuscarResidentes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BuscarResidentesModal(
        currentUser: widget.currentUser,
        mensajeService: _mensajeService,
        onChatCreado: (chatId, nombreResidente) {
          Navigator.pop(context);
          _abrirChat(chatId, nombreResidente);
        },
      ),
    );
  }

  void _mostrarConfiguracionMensajes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Mensajes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Permitir mensajes de otros residentes'),
              subtitle: const Text(
                'Otros residentes podrán enviarte mensajes privados',
              ),
              value: _permitirMensajesResidentes,
              onChanged: (value) async {
                try {
                  await _mensajeService.actualizarConfiguracionMensajes(
                    condominioId: widget.currentUser.condominioId.toString(),
                    residenteId: widget.currentUser.uid,
                    permitirMensajes: value,
                  );

                  setState(() {
                    _permitirMensajesResidentes = value;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuración actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
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

// Modal para buscar residentes
class _BuscarResidentesModal extends StatefulWidget {
  final UserModel currentUser;
  final MensajeService mensajeService;
  final Function(String chatId, String nombreResidente) onChatCreado;

  const _BuscarResidentesModal({
    Key? key,
    required this.currentUser,
    required this.mensajeService,
    required this.onChatCreado,
  }) : super(key: key);

  @override
  _BuscarResidentesModalState createState() => _BuscarResidentesModalState();
}

class _BuscarResidentesModalState extends State<_BuscarResidentesModal> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<ResidenteModel> _residentes = [];
  List<ResidenteModel> _residentesFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarResidentes();
    _searchController.addListener(_filtrarResidentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarResidentes() async {
    try {
      final residentes = await _firestoreService.obtenerResidentesCondominio(
        widget.currentUser.condominioId.toString(),
      );

      // Filtrar el usuario actual
      final residentesFiltrados = residentes
          .where((r) => r.uid != widget.currentUser.uid)
          .toList();

      if (mounted) {
        setState(() {
          _residentes = residentesFiltrados;
          _residentesFiltrados = residentesFiltrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar residentes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filtrarResidentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.descripcionVivienda.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle del modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Título
          const Text(
            'Buscar Residente',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o vivienda...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de residentes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _residentesFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron residentes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _residentesFiltrados.length,
                    itemBuilder: (context, index) {
                      final residente = _residentesFiltrados[index];
                      return _buildResidenteCard(residente);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenteCard(ResidenteModel residente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.person, color: Colors.blue[700]),
        ),
        title: Text(
          residente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          residente.descripcionVivienda,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => _crearChat(residente),
      ),
    );
  }

  Future<void> _crearChat(ResidenteModel residente) async {
    try {
      // Verificar si ambos usuarios permiten mensajes
      final otroResidentePermite = await widget.mensajeService
          .residentePermiteMensajes(
            condominioId: widget.currentUser.condominioId.toString(),
            residenteId: residente.uid,
          );

      if (!otroResidentePermite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este residente no permite recibir mensajes de otros residentes',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final chatId = await widget.mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residente.uid,
        tipo: 'entreResidentes',
      );

      widget.onChatCreado(chatId, residente.nombre);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
