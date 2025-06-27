import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/mensaje_model.dart';
import '../../models/residente_model.dart';
import '../../services/mensaje_service.dart';
import '../../services/firestore_service.dart';
import '../residente/chat_screen.dart';
import 'package:intl/intl.dart';

class MensajesAdminScreen extends StatefulWidget {
  final UserModel currentUser;

  const MensajesAdminScreen({super.key, required this.currentUser});

  @override
  _MensajesAdminScreenState createState() => _MensajesAdminScreenState();
}

class _MensajesAdminScreenState extends State<MensajesAdminScreen> {
  final MensajeService _mensajeService = MensajeService();
  final NotificationService _notificationService = NotificationService();

  final FirestoreService _firestoreService = FirestoreService();
  bool _comunicacionEntreResidentesHabilitada = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
  }

  Future<void> _cargarConfiguraciones() async {
    try {
      final comunicacionHabilitada = await _mensajeService
          .esComunicacionEntreResidentesHabilitada(
            widget.currentUser.condominioId.toString(),
          );

      if (mounted) {
        setState(() {
          _comunicacionEntreResidentesHabilitada = comunicacionHabilitada;
        });
      }
    } catch (e) {
      print('❌ Error al cargar configuraciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Chat del Condominio (destacado)
          _buildChatCondominioCard(),
          const SizedBox(height: 4),

          // Chat con Conserjería
          _buildChatConserjeriaCard(),
          const SizedBox(height: 4),

          // Lista de chats con residentes
          Expanded(child: _buildChatsResidentes()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalBuscarResidente(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildChatCondominioCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
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
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue,
            size: 25,
          ),
          onTap: () => _abrirChatCondominio(),
        ),
      ),
    );
  }

  Widget _buildChatConserjeriaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200, width: 2),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 24),
          ),
          title: const Text(
            'Conserjería',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: const Text(
            'Chat con el personal de conserjería',
            style: TextStyle(fontSize: 13),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.orange[400],
            size: 25,
          ),
          onTap: () => _abrirChatConserjeria(),
        ),
      ),
    );
  }

  Widget _buildChatsResidentes() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                'Chats con Residentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final chats = snapshot.data ?? [];
                // CORREGIR: Filtrar correctamente para mostrar solo chats con residentes
                final chatsPrivados = chats
                    .where(
                      (chat) =>
                          chat.participantes.length == 2 &&
                          !chat.participantes.contains('GRUPO_CONDOMINIO') &&
                          chat.tipo != 'grupal' &&
                          chat.tipo != 'conserjeria',
                    )
                    .toList();

                if (chatsPrivados.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes chats privados aún.\nUsa el botón + para iniciar una conversación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chatsPrivados.length,
                  itemBuilder: (context, index) {
                    final chat = chatsPrivados[index];
                    final otroParticipante = chat.participantes.firstWhere(
                      (p) => p != widget.currentUser.uid,
                    );

                    return FutureBuilder<ResidenteModel?>(
                      future: _firestoreService.getResidenteData(
                        otroParticipante,
                      ),
                      builder: (context, residenteSnapshot) {
                        if (residenteSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (residenteSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${residenteSnapshot.error}'),
                          );
                        }
                        final residente = residenteSnapshot.data;
                        final nombreResidente = residente?.nombre ?? 'Usuario';
                        final vivienda = residente?.descripcionVivienda;

                        return Container(
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 4,
                            color: Colors.green.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.green.shade200,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                radius: 25,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.green[700],
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                nombreResidente,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                vivienda!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ✅ NUEVO: Contador de mensajes no leídos
                                  FutureBuilder<int>(
                                    future: _mensajeService
                                        .contarMensajesNoLeidos(
                                          condominioId: widget
                                              .currentUser
                                              .condominioId
                                              .toString(),
                                          chatId: chat.id,
                                          usuarioId: widget.currentUser.uid,
                                        ),
                                    builder: (context, unreadSnapshot) {
                                      final unreadCount =
                                          unreadSnapshot.data ?? 0;
                                      if (unreadCount > 0) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  Text(
                                    DateFormat('dd/MM').format(
                                      DateTime.parse(chat.fechaRegistro),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _abrirChatPrivado(
                                otroParticipante,
                                nombreResidente,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _abrirChatCondominio() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // ✅ NUEVO: Borrar notificaciones de mensajes del condominio para este chat
        await _notificationService.borrarNotificacionesMensajeCondominio(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: chatId,
        );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: 'Chat del Condominio',
              esGrupal: true,
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

  void _abrirChatConserjeria() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: 'conserjeria',
        tipo: 'admin-conserjeria',
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
            content: Text('Error al abrir chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirChatPrivado(String residenteId, String nombreResidente) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residenteId,
        tipo: 'admin-residente',
      );

      // ✅ NUEVO: Borrar notificaciones de mensajes del condominio para este chat
      await _notificationService.borrarNotificacionesMensajeCondominio(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
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

  void _mostrarModalBuscarResidente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalBuscarResidente(
        currentUser: widget.currentUser,
        onResidenteSeleccionado: (residente) {
          Navigator.pop(context);
          _abrirChatPrivado(residente.uid, residente.nombre);
        },
      ),
    );
  }
}

class _ModalBuscarResidente extends StatefulWidget {
  final UserModel currentUser;
  final Function(ResidenteModel) onResidenteSeleccionado;

  const _ModalBuscarResidente({
    required this.currentUser,
    required this.onResidenteSeleccionado,
  });

  @override
  _ModalBuscarResidenteState createState() => _ModalBuscarResidenteState();
}

class _ModalBuscarResidenteState extends State<_ModalBuscarResidente> {
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

      if (mounted) {
        setState(() {
          _residentes = residentes;
          _residentesFiltrados = residentes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filtrarResidentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.viviendaSeleccionada.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle del modal
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Buscar Residente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o vivienda...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
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
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _residentesFiltrados.length,
                    itemBuilder: (context, index) {
                      final residente = _residentesFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade600,
                            child: Text(
                              residente.nombre.isNotEmpty
                                  ? residente.nombre[0].toUpperCase()
                                  : 'R',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            residente.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            residente.descripcionVivienda,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: const Icon(Icons.chat),
                          onTap: () =>
                              widget.onResidenteSeleccionado(residente),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
