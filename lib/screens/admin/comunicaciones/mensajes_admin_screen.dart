import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/mensaje_model.dart';
import '../../../models/residente_model.dart';
import '../../../models/trabajador_model.dart';
import '../../../models/comite_model.dart';
import '../../../services/mensaje_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/unread_messages_service.dart';
import '../../../widgets/unread_messages_badge.dart';
import '../../chat_screen.dart';
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
  final UnreadMessagesService _unreadService = UnreadMessagesService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _comunicacionEntreResidentesHabilitada = false;
  
  // IDs de chats específicos
  String? _chatGrupalId;
  String? _chatConserjeriaId;

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

  Future<void> _cargarChatsIds() async {
    try {
      // Cargar ID del chat grupal
      final chatGrupalId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );
      
      // Cargar ID del chat de conserjería
      final chatConserjeriaId = await _mensajeService.crearOObtenerChatConserjeria(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );
      
      if (mounted) {
        setState(() {
          _chatGrupalId = chatGrupalId;
          _chatConserjeriaId = chatConserjeriaId;
        });
      }
    } catch (e) {
      print('❌ Error al cargar IDs de chats: $e');
    }
  }

  Future<void> _cargarConfiguraciones() async {
    try {
      final condominio = await _firestoreService.getCondominioData(
        widget.currentUser.condominioId.toString(),
      );

      if (mounted && condominio != null) {
        setState(() {
          _comunicacionEntreResidentesHabilitada = condominio.gestionFunciones.chatEntreRes;
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Chat del Condominio (destacado)
            _buildChatCondominioCard(),
            const SizedBox(height: 4),

            // Chat con Conserjería
            _buildChatConserjeriaCard(),
            const SizedBox(height: 4),

            // Historial de Chats
            _buildHistorialChats(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalBuscarUsuarios(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildChatCondominioCard() {
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
          onTap: () => _abrirChatCondominio(),
        ),
      ),
    );
  }

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
          onTap: () => _abrirChatConserjeria(),
        ),
      ),
    );
  }

  void _abrirChatCondominio() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'administrador',
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

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'administrador',
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

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'administrador',
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

  void _abrirChatTrabajador(String trabajadorId, String nombreTrabajador) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: trabajadorId,
        tipo: 'admin-trabajador',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'administrador',
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
              nombreChat: nombreTrabajador,
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

  void _abrirChatComite(String comiteId, String nombreComite) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: comiteId,
        tipo: 'admin-comite',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'administrador',
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
              nombreChat: nombreComite,
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

  void _mostrarModalBuscarUsuarios() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalBuscarUsuarios(
        currentUser: widget.currentUser,
        onTrabajadorSeleccionado: (trabajador) {
          Navigator.pop(context);
          _abrirChatTrabajador(trabajador.uid, trabajador.nombre);
        },
        onResidenteSeleccionado: (residente) {
          Navigator.pop(context);
          _abrirChatPrivado(residente.uid, residente.nombre);
        },
        onComiteSeleccionado: (comite) {
          Navigator.pop(context);
          _abrirChatComite(comite.uid, comite.nombre);
        },
      ),
    );
  }

  Widget _buildHistorialChats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Historial de Chats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        StreamBuilder<List<MensajeModel>>(
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
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final chats = snapshot.data ?? [];
            
            // Filtrar chats para ocultar grupal (está anclado)
            final filteredChats = chats.where((chat) => 
              chat.tipo != 'grupal'
            ).toList();
            
            if (filteredChats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay chats disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return _buildChatHistoryCard(chat);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatHistoryCard(MensajeModel chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: chat.id,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          title: _buildChatTitle(chat),
          subtitle: Text(_getChatSubtitle(chat)),
          leading: _getChatIcon(chat),
          onTap: () => _abrirChatConTitulo(chat),
        ),
      ),
    );
  }

  Widget _buildChatTitle(MensajeModel chat) {
    switch (chat.tipo) {
      case 'grupal':
        return const Text('Chat del Condominio');
      case 'conserjeria':
      case 'admin-conserjeria':
        return const Text('Conserjería');
      case 'privado':
      case 'trabajador-residente':
      case 'admin-trabajador':
      case 'residente-trabajador':
      case 'trabajador-admin':
      case 'admin-residente':
      case 'residente-admin':
        // Obtener el nombre del otro participante
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        return FutureBuilder<String>(
          future: _obtenerNombreUsuario(otherUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            }
            if (snapshot.hasError) {
              return Text('Chat con $otherUserId');
            }
            return Text(snapshot.data ?? 'Usuario desconocido');
          },
        );
      default:
        // Para tipos desconocidos, tratarlos como chats privados
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        return FutureBuilder<String>(
          future: _obtenerNombreUsuario(otherUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            }
            if (snapshot.hasError) {
              return Text('Chat con $otherUserId');
            }
            return Text(snapshot.data ?? 'Usuario desconocido');
          },
        );
    }
  }

  // Método para obtener información del usuario
  Future<String> _obtenerNombreUsuario(String usuarioId) async {
    try {
      final condominioId = widget.currentUser.condominioId.toString();
      
      // Verificar si es el administrador
      final adminDoc = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('administrador')
          .get();

      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>;
        if (adminData['uid'] == usuarioId) {
          return adminData['nombre'] ?? 'Administrador';
        }
      }

      // Verificar si es un trabajador
      final trabajadoresSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .where('uid', isEqualTo: usuarioId)
          .get();

      if (trabajadoresSnapshot.docs.isNotEmpty) {
        final trabajadorData = trabajadoresSnapshot.docs.first.data();
        return trabajadorData['nombre'] ?? 'Trabajador';
      }

      // Verificar si es un miembro del comité
      final comiteSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('comite')
          .where('uid', isEqualTo: usuarioId)
          .get();

      if (comiteSnapshot.docs.isNotEmpty) {
        final comiteData = comiteSnapshot.docs.first.data();
        return comiteData['nombre'] ?? 'Comité';
      }

      // Verificar si es un residente
      final residentesSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .where('uid', isEqualTo: usuarioId)
          .get();

      if (residentesSnapshot.docs.isNotEmpty) {
        final residenteData = residentesSnapshot.docs.first.data();
        return residenteData['nombre'] ?? 'Residente';
      }

      return 'Usuario desconocido';
    } catch (e) {
      return 'Error al cargar';
    }
  }

  String _getChatTitle(MensajeModel chat) {
    switch (chat.tipo) {
      case 'grupal':
        return 'Chat del Condominio';
      case 'conserjeria':
        return 'Conserjería';
      case 'privado':
        // Obtener el nombre del otro participante
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        return 'Chat con $otherUserId';
      default:
        return 'Chat';
    }
  }

  String _getChatSubtitle(MensajeModel chat) {
    final fecha = DateTime.parse(chat.fechaRegistro);
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Hace un momento';
    }
  }

  Widget _getChatIcon(MensajeModel chat) {
    switch (chat.tipo) {
      case 'grupal':
        return CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.group, color: Colors.blue.shade600),
        );
      case 'conserjeria':
        return CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.security, color: Colors.green.shade600),
        );
      case 'privado':
        return CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.person, color: Colors.orange.shade600),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: Icon(Icons.chat, color: Colors.grey.shade600),
        );
    }
  }

  void _abrirChat(String chatId, String tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          currentUser: widget.currentUser,
          nombreChat: _getChatTitle(MensajeModel(
            id: chatId,
            fechaRegistro: DateTime.now().toIso8601String(),
            participantes: [],
            contenido: [],
            tipo: tipo,
          )),
          esGrupal: tipo == 'grupal',
        ),
      ),
    );
  }

  Future<void> _abrirChatConTitulo(MensajeModel chat) async {
    String nombreChat;
    bool esGrupal = false;
    
    switch (chat.tipo) {
      case 'grupal':
        nombreChat = 'Chat del Condominio';
        esGrupal = true;
        break;
      case 'conserjeria':
      case 'admin-conserjeria':
        nombreChat = 'Conserjería';
        break;
      case 'privado':
      case 'trabajador-residente':
      case 'admin-trabajador':
      case 'residente-trabajador':
      case 'trabajador-admin':
      case 'admin-residente':
      case 'residente-admin':
        // Obtener el nombre del otro participante
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        // Obtener el nombre real del usuario
        nombreChat = await _obtenerNombreUsuario(otherUserId);
        break;
      default:
        // Para tipos desconocidos, tratarlos como chats privados
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        nombreChat = await _obtenerNombreUsuario(otherUserId);
        break;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUser,
          chatId: chat.id,
          nombreChat: nombreChat,
          esGrupal: esGrupal,
        ),
      ),
    );
  }
}

class _ModalBuscarUsuarios extends StatefulWidget {
  final UserModel currentUser;
  final Function(TrabajadorModel) onTrabajadorSeleccionado;
  final Function(ResidenteModel) onResidenteSeleccionado;
  final Function(ComiteModel) onComiteSeleccionado;

  const _ModalBuscarUsuarios({
    required this.currentUser,
    required this.onTrabajadorSeleccionado,
    required this.onResidenteSeleccionado,
    required this.onComiteSeleccionado,
  });

  @override
  _ModalBuscarUsuariosState createState() => _ModalBuscarUsuariosState();
}

class _ModalBuscarUsuariosState extends State<_ModalBuscarUsuarios> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TrabajadorModel> _trabajadores = [];
  List<ResidenteModel> _residentes = [];
  List<ComiteModel> _comite = [];
  
  List<TrabajadorModel> _trabajadoresFiltrados = [];
  List<ResidenteModel> _residentesFiltrados = [];
  List<ComiteModel> _comiteFiltrado = [];
  
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Trabajadores, 1: Residentes, 2: Comité

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrarDatos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final condominioId = widget.currentUser.condominioId.toString();
      
      final futures = await Future.wait([
        _firestoreService.obtenerTrabajadoresCondominio(condominioId),
        _firestoreService.obtenerResidentesCondominio(condominioId),
        _firestoreService.obtenerMiembrosComite(condominioId),
      ]);

      if (mounted) {
        setState(() {
          _trabajadores = futures[0] as List<TrabajadorModel>;
          _residentes = futures[1] as List<ResidenteModel>;
          _comite = futures[2] as List<ComiteModel>;
          
          _trabajadoresFiltrados = _trabajadores;
          _residentesFiltrados = _residentes;
          _comiteFiltrado = _comite;
          
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

  void _filtrarDatos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _trabajadoresFiltrados = _trabajadores.where((trabajador) {
        final nombre = trabajador.nombre.toLowerCase();
        final tipoTrabajador = trabajador.tipoTrabajador.toLowerCase();
        return nombre.contains(query) || tipoTrabajador.contains(query);
      }).toList();

      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.viviendaSeleccionada.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();

      _comiteFiltrado = _comite.where((comite) {
        final nombre = comite.nombre.toLowerCase();
        final email = comite.email.toLowerCase();
        return nombre.contains(query) || email.contains(query);
      }).toList();
    });
  }

  String _getTipoTrabajadorDisplay(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return 'Conserje';
      case 'seguridad':
        return 'Seguridad';
      case 'limpieza':
        return 'Limpieza';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'jardineria':
        return 'Jardinería';
      case 'administracion':
        return 'Administración';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> items = [];
    
    switch (_selectedTab) {
      case 0: // Trabajadores
        if (_trabajadoresFiltrados.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron trabajadores',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        items = _trabajadoresFiltrados.map((trabajador) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade600,
              child: Text(
                trabajador.nombre.isNotEmpty
                    ? trabajador.nombre[0].toUpperCase()
                    : 'T',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              trabajador.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _getTipoTrabajadorDisplay(trabajador.tipoTrabajador),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chat),
            onTap: () => widget.onTrabajadorSeleccionado(trabajador),
          ),
        )).toList();
        break;
        
      case 1: // Residentes
        if (_residentesFiltrados.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron residentes',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        items = _residentesFiltrados.map((residente) => Card(
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
            onTap: () => widget.onResidenteSeleccionado(residente),
          ),
        )).toList();
        break;
        
      case 2: // Comité
        if (_comiteFiltrado.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron miembros del comité',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        items = _comiteFiltrado.map((comite) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade600,
              child: Text(
                comite.nombre.isNotEmpty
                    ? comite.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              comite.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              comite.email,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chat),
            onTap: () => widget.onComiteSeleccionado(comite),
          ),
        )).toList();
        break;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: items,
    );
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
              'Buscar Usuarios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton('Trabajadores', 0, Icons.work),
                _buildTabButton('Residentes', 1, Icons.home),
                _buildTabButton('Comité', 2, Icons.group),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _selectedTab == 0 
                    ? 'Buscar por nombre o tipo de trabajo...'
                    : _selectedTab == 1
                        ? 'Buscar por nombre o vivienda...'
                        : 'Buscar por nombre o email...',
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

          // Lista de usuarios
          Expanded(
            child: _buildListContent(),
          ),
        ],
      ),
    );
  }
}
