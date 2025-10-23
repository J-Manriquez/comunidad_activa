import 'package:comunidad_activa/models/administrador_model.dart';
import 'package:comunidad_activa/models/comite_model.dart';
import '../../../models/trabajador_model.dart';
import 'package:comunidad_activa/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/mensaje_model.dart';
import '../../../models/residente_model.dart';
import '../../../services/mensaje_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/unread_messages_service.dart';
import '../../../widgets/unread_messages_badge.dart';
import '../../chat_screen.dart';
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
  NotificationService _notificationService = NotificationService();
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
      final chatConserjeriaId = await _mensajeService
          .crearOObtenerChatConserjeria(
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Chat grupal del condominio
            _buildChatGrupalCard(),
            const SizedBox(height: 4),

            // Chat con conserjería
            _buildChatConserjeriaCard(),
            const SizedBox(height: 4),

            // ✅ NUEVO: Chat con administrador
            _buildChatAdministradorCard(),
            const SizedBox(height: 4),

            // Historial de Chats
            _buildHistorialChats(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarModalBuscarUsuarios,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
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
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
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
            child: Icon(Icons.security, color: Colors.orange[700], size: 28),
          ),
          title: const Text(
            'Conserjería',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
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
            content: Text('Error al abrir chat con conserjería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirChatComite(ComiteModel comite) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: comite.uid,
        tipo: 'residente-comite',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
      );

      // Borrar notificaciones de mensajes del condominio para este chat
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
              nombreChat: comite.nombre,
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con miembro del comité: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirChatPrivadoConResidente(ResidenteModel residente) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residente.uid,
        tipo: 'entreResidentes',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
      );

      // Borrar notificaciones de mensajes del condominio para este chat
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
              nombreChat: residente.nombre,
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con residente: $e'),
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
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
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
  Future<void> _abrirChatPrivado(
    MensajeModel chat,
    String nombreResidente,
  ) async {
    try {
      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chat.id,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
      );

      // ✅ NUEVO: Borrar notificaciones de mensajes del condominio para este chat
      await _notificationService.borrarNotificacionesMensajeCondominio(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chat.id,
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

  void _abrirChat(String chatId, String nombreChat, {String? tipo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUser,
          chatId: chatId,
          nombreChat: nombreChat,
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

  void _mostrarModalBuscarResidentes() {
    _mostrarModalBuscarUsuarios();
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
          _abrirChatPrivadoConTrabajador(trabajador);
        },
        onResidenteSeleccionado: (residente) {
          Navigator.pop(context);
          _abrirChatPrivadoConResidente(residente);
        },
        onComiteSeleccionado: (comite) {
          Navigator.pop(context);
          _abrirChatComite(comite);
        },
      ),
    );
  }

  Future<void> _abrirChatPrivadoConTrabajador(TrabajadorModel trabajador) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: trabajador.uid,
        tipo: 'residente-trabajador',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'residentes',
      );

      // Borrar notificaciones de mensajes del condominio para este chat
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
              nombreChat: trabajador.nombre,
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con trabajador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    print('🔍 [DEBUG] _buildChatTitle - Iniciando');
    print('🔍 [DEBUG] chat.tipo: ${chat.tipo}');
    print('🔍 [DEBUG] chat.participantes: ${chat.participantes}');
    print('🔍 [DEBUG] widget.currentUser.uid: ${widget.currentUser.uid}');
    
    switch (chat.tipo) {
      case 'grupal':
        print('🔍 [DEBUG] ✅ Chat grupal detectado');
        return const Text('Chat del Condominio');
      case 'conserjeria':
      case 'admin-conserjeria':
        print('🔍 [DEBUG] ✅ Chat conserjería detectado');
        return const Text('Conserjería');
      case 'privado':
      case 'trabajador-residente':
      case 'admin-trabajador':
      case 'residente-trabajador':
      case 'trabajador-admin':
      case 'admin-residente':
      case 'residente-admin':
        print('🔍 [DEBUG] ✅ Chat privado detectado');
        // Obtener el nombre del otro participante
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        print('🔍 [DEBUG] otherUserId encontrado: $otherUserId');
        
        return FutureBuilder<String>(
          future: _obtenerNombreUsuario(otherUserId),
          builder: (context, snapshot) {
            print('🔍 [DEBUG] FutureBuilder - connectionState: ${snapshot.connectionState}');
            print('🔍 [DEBUG] FutureBuilder - hasError: ${snapshot.hasError}');
            print('🔍 [DEBUG] FutureBuilder - data: ${snapshot.data}');
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('🔍 [DEBUG] ⏳ Mostrando "Cargando..."');
              return const Text('Cargando...');
            }
            if (snapshot.hasError) {
              print('🔍 [DEBUG] ❌ Error en FutureBuilder: ${snapshot.error}');
              return Text('Chat con $otherUserId');
            }
            final resultado = snapshot.data ?? 'Usuario desconocido';
            print('🔍 [DEBUG] ✅ Resultado final: $resultado');
            return Text(resultado);
          },
        );
      default:
        print('🔍 [DEBUG] ⚠️ Tipo de chat desconocido: ${chat.tipo}');
        // Para tipos desconocidos, tratarlos como chats privados
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        print('🔍 [DEBUG] Tratando tipo desconocido como privado - otherUserId: $otherUserId');
        
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
      
      print('🔍 [DEBUG] _obtenerNombreUsuario - Iniciando búsqueda');
      print('🔍 [DEBUG] usuarioId: $usuarioId');
      print('🔍 [DEBUG] condominioId: $condominioId');
      
      // Verificar si es el administrador
      print('🔍 [DEBUG] Verificando administrador...');
      final adminDoc = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('administrador')
          .get();

      print('🔍 [DEBUG] adminDoc.exists: ${adminDoc.exists}');
      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>;
        print('🔍 [DEBUG] adminData: $adminData');
        print('🔍 [DEBUG] adminData[uid]: ${adminData['uid']}');
        if (adminData['uid'] == usuarioId) {
          final nombre = adminData['nombre'] ?? 'Administrador';
          print('🔍 [DEBUG] ✅ Encontrado como administrador: $nombre');
          return nombre;
        }
      }

      // Verificar si es un trabajador
      print('🔍 [DEBUG] Verificando trabajadores...');
      final trabajadoresSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .where('uid', isEqualTo: usuarioId)
          .get();

      print('🔍 [DEBUG] trabajadoresSnapshot.docs.length: ${trabajadoresSnapshot.docs.length}');
      if (trabajadoresSnapshot.docs.isNotEmpty) {
        final trabajadorData = trabajadoresSnapshot.docs.first.data();
        print('🔍 [DEBUG] trabajadorData: $trabajadorData');
        final nombre = trabajadorData['nombre'] ?? 'Trabajador';
        print('🔍 [DEBUG] ✅ Encontrado como trabajador: $nombre');
        return nombre;
      }

      // Verificar si es un miembro del comité
      print('🔍 [DEBUG] Verificando comité...');
      final comiteSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('comite')
          .where('uid', isEqualTo: usuarioId)
          .get();

      print('🔍 [DEBUG] comiteSnapshot.docs.length: ${comiteSnapshot.docs.length}');
      if (comiteSnapshot.docs.isNotEmpty) {
        final comiteData = comiteSnapshot.docs.first.data();
        print('🔍 [DEBUG] comiteData: $comiteData');
        final nombre = comiteData['nombre'] ?? 'Comité';
        print('🔍 [DEBUG] ✅ Encontrado como comité: $nombre');
        return nombre;
      }

      // Verificar si es un residente
      print('🔍 [DEBUG] Verificando residentes...');
      final residentesSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .where('uid', isEqualTo: usuarioId)
          .get();

      print('🔍 [DEBUG] residentesSnapshot.docs.length: ${residentesSnapshot.docs.length}');
      if (residentesSnapshot.docs.isNotEmpty) {
        final residenteData = residentesSnapshot.docs.first.data();
        print('🔍 [DEBUG] residenteData: $residenteData');
        final nombre = residenteData['nombre'] ?? 'Residente';
        print('🔍 [DEBUG] ✅ Encontrado como residente: $nombre');
        return nombre;
      }

      print('🔍 [DEBUG] ❌ Usuario no encontrado en ninguna colección');
      return 'Usuario desconocido';
    } catch (e) {
      print('🔍 [DEBUG] ❌ Error en _obtenerNombreUsuario: $e');
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
}

// Modal para buscar residentes


class _ModalBuscarUsuarios extends StatefulWidget {
  final UserModel currentUser;
  final Function(TrabajadorModel)? onTrabajadorSeleccionado;
  final Function(ResidenteModel)? onResidenteSeleccionado;
  final Function(ComiteModel)? onComiteSeleccionado;

  const _ModalBuscarUsuarios({
    required this.currentUser,
    this.onTrabajadorSeleccionado,
    this.onResidenteSeleccionado,
    this.onComiteSeleccionado,
  });

  @override
  _ModalBuscarUsuariosState createState() => _ModalBuscarUsuariosState();
}

class _ModalBuscarUsuariosState extends State<_ModalBuscarUsuarios>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TrabajadorModel> _trabajadores = [];
  List<TrabajadorModel> _trabajadoresFiltrados = [];
  List<ResidenteModel> _residentes = [];
  List<ResidenteModel> _residentesFiltrados = [];
  List<ComiteModel> _comite = [];
  List<ComiteModel> _comiteFiltrado = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
    _searchController.addListener(_filtrarDatos);
    _tabController.addListener(_filtrarDatos);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = await Future.wait([
        _firestoreService.obtenerTrabajadoresCondominio(
          widget.currentUser.condominioId.toString(),
        ),
        _firestoreService.obtenerResidentesCondominio(
          widget.currentUser.condominioId.toString(),
        ),
        _firestoreService.obtenerMiembrosComite(
          widget.currentUser.condominioId.toString(),
        ),
      ]);

      if (mounted) {
        setState(() {
          _trabajadores = futures[0] as List<TrabajadorModel>;
          _trabajadoresFiltrados = _trabajadores;
          _residentes = futures[1] as List<ResidenteModel>;
          _residentesFiltrados = _residentes;
          _comite = futures[2] as List<ComiteModel>;
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
      // Filtrar trabajadores
      _trabajadoresFiltrados = _trabajadores.where((trabajador) {
        final nombre = trabajador.nombre.toLowerCase();
        final tipoTrabajador = trabajador.tipoTrabajador.toLowerCase();
        return nombre.contains(query) || tipoTrabajador.contains(query);
      }).toList();

      // Filtrar residentes
      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.descripcionVivienda.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();

      // Filtrar comité
      _comiteFiltrado = _comite.where((miembro) {
        final nombre = miembro.nombre.toLowerCase();
        return nombre.contains(query);
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

  Widget _buildTrabajadoresList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trabajadoresFiltrados.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron trabajadores',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _trabajadoresFiltrados.length,
      itemBuilder: (context, index) {
        final trabajador = _trabajadoresFiltrados[index];
        return Card(
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
            onTap: () => widget.onTrabajadorSeleccionado?.call(trabajador),
          ),
        );
      },
    );
  }

  Widget _buildResidentesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_residentesFiltrados.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron residentes',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _residentesFiltrados.length,
      itemBuilder: (context, index) {
        final residente = _residentesFiltrados[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade600,
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
              'Vivienda: ${residente.descripcionVivienda}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chat),
            onTap: () => widget.onResidenteSeleccionado?.call(residente),
          ),
        );
      },
    );
  }

  Widget _buildComiteList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_comiteFiltrado.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron miembros del comité',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _comiteFiltrado.length,
      itemBuilder: (context, index) {
        final miembro = _comiteFiltrado[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade600,
              child: Text(
                miembro.nombre.isNotEmpty
                    ? miembro.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              miembro.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Miembro del Comité',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.chat),
            onTap: () => widget.onComiteSeleccionado?.call(miembro),
          ),
        );
      },
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

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
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

          // Pestañas
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade600,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade600,
            tabs: const [
              Tab(text: 'Trabajadores'),
              Tab(text: 'Residentes'),
              Tab(text: 'Comité'),
            ],
          ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrabajadoresList(),
                _buildResidentesList(),
                _buildComiteList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
