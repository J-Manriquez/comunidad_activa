import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/mensaje_model.dart';
import '../../models/residente_model.dart';
import '../../models/trabajador_model.dart';
import '../../models/comite_model.dart';
import '../../services/firestore_service.dart';
import '../../services/mensaje_service.dart';
import '../../services/unread_messages_service.dart';
import '../../services/notification_service.dart';
import '../chat_screen.dart';
import '../../widgets/unread_messages_badge.dart';

class MensajesTrabajadorScreen extends StatefulWidget {
  final UserModel currentUser;

  const MensajesTrabajadorScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MensajesTrabajadorScreen> createState() => _MensajesTrabajadorScreenState();
}

class _MensajesTrabajadorScreenState extends State<MensajesTrabajadorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MensajeService _mensajeService = MensajeService();
  final UnreadMessagesService _unreadService = UnreadMessagesService();
  final NotificationService _notificationService = NotificationService();

  String? _chatGrupalId;
  String? _chatConserjeriaId;
  String? _chatAdministradorId;

  @override
  void initState() {
    super.initState();
    _cargarChatsIds();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarChatsIds() async {
    try {
      // Cargar chat grupal
      final chatGrupalId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Cargar chat conserjería
      final chatConserjeriaId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: 'conserjeria',
        tipo: 'trabajador-conserjeria',
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
          tipo: 'admin-trabajador',
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

            // Chat con Administrador
            _buildChatAdministradorCard(),
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
    if (_chatGrupalId == null || _chatGrupalId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 6,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade200, width: 2),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: _chatGrupalId!,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          leading: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.home,
              color: Colors.white,
              size: 32,
            ),
          ),
          title: const Text(
            'Chat del Condominio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Conversación general del condominio',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.all(20),
          onTap: _abrirChatCondominio,
        ),
      ),
    );
  }

  Widget _buildChatConserjeriaCard() {
    if (_chatConserjeriaId == null || _chatConserjeriaId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200, width: 1),
        ),
        child: UnreadMessagesListTile(
          condominioId: widget.currentUser.condominioId.toString(),
          chatId: _chatConserjeriaId!,
          usuarioId: widget.currentUser.uid,
          unreadService: _unreadService,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 28,
            ),
          ),
          title: const Text(
            'Conserjería',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Chat con el servicio de conserjería',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.all(16),
          onTap: _abrirChatConserjeria,
        ),
      ),
    );
  }

  Widget _buildChatAdministradorCard() {
    if (_chatAdministradorId == null || _chatAdministradorId!.isEmpty) {
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
        tipoUsuario: 'trabajador',
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
        tipo: 'trabajador-conserjeria',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  void _abrirChatAdministrador() async {
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
        tipo: 'admin-trabajador',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  // Método para abrir chat con trabajador
  Future<void> _abrirChatTrabajador(TrabajadorModel trabajador) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: trabajador.uid,
        tipo: 'trabajador-trabajador',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  // Método para abrir chat con comité
  Future<void> _abrirChatComite(ComiteModel comite) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: comite.uid,
        tipo: 'trabajador-comite',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  // Método para abrir chat privado con residente
  Future<void> _abrirChatPrivadoConResidente(ResidenteModel residente) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residente.uid,
        tipo: 'trabajador-residente',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  void _abrirChatPrivado(String residenteId, String nombreResidente) async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residenteId,
        tipo: 'trabajador-residente',
      );

      // Marcar mensajes como leídos
      await _unreadService.markMessagesAsRead(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: chatId,
        usuarioId: widget.currentUser.uid,
        nombreUsuario: widget.currentUser.nombre,
        tipoUsuario: 'trabajador',
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

  // Método para mostrar modal unificado de búsqueda
  Future<void> _mostrarModalBuscarUsuarios() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalBuscarUsuarios(
        currentUser: widget.currentUser,
        onTrabajadorSeleccionado: (trabajador) {
          Navigator.pop(context);
          _abrirChatTrabajador(trabajador);
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
            
            // Filtrar chats para ocultar grupal y administrador (están anclados)
            final filteredChats = chats.where((chat) => 
              chat.tipo != 'grupal' && 
              chat.tipo != 'administrador' &&
              chat.tipo != 'admin-trabajador' &&
              chat.tipo != 'trabajador-admin' &&
              chat.tipo != 'admin-conserjeria'
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
        // Usar FutureBuilder para obtener el nombre del usuario
        return otherUserId; // Temporalmente devolver el ID, luego lo cambiaremos
      default:
        return 'Chat';
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
    print('🔍 [DEBUG] _abrirChatConTitulo - Iniciando');
    print('🔍 [DEBUG] chat.id: ${chat.id}');
    print('🔍 [DEBUG] chat.tipo: ${chat.tipo}');
    print('🔍 [DEBUG] chat.participantes: ${chat.participantes}');
    
    String nombreChat;
    bool esGrupal = false;
    
    switch (chat.tipo) {
      case 'grupal':
        print('🔍 [DEBUG] ✅ Chat grupal detectado');
        nombreChat = 'Chat del Condominio';
        esGrupal = true;
        break;
      case 'conserjeria':
      case 'admin-conserjeria':
        print('🔍 [DEBUG] ✅ Chat conserjería detectado');
        nombreChat = 'Conserjería';
        break;
      case 'privado':
      case 'trabajador-residente':
      case 'admin-trabajador':
      case 'residente-trabajador':
      case 'trabajador-admin':
        print('🔍 [DEBUG] ✅ Chat privado detectado');
        // Obtener el nombre del otro participante
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        print('🔍 [DEBUG] otherUserId encontrado: $otherUserId');
        print('🔍 [DEBUG] Llamando a _obtenerNombreUsuario...');
        
        nombreChat = await _obtenerNombreUsuario(otherUserId);
        print('🔍 [DEBUG] Nombre obtenido: $nombreChat');
        break;
      default:
        print('🔍 [DEBUG] ⚠️ Tipo de chat desconocido: ${chat.tipo}');
        // Para tipos desconocidos, tratarlos como chats privados
        final otherUserId = chat.participantes.firstWhere(
          (id) => id != widget.currentUser.uid,
          orElse: () => 'Usuario desconocido',
        );
        
        print('🔍 [DEBUG] Tratando tipo desconocido como privado - otherUserId: $otherUserId');
        nombreChat = await _obtenerNombreUsuario(otherUserId);
        print('🔍 [DEBUG] Nombre obtenido para tipo desconocido: $nombreChat');
        break;
    }
    
    print('🔍 [DEBUG] Navegando a ChatScreen con nombre: $nombreChat');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
          currentUser: widget.currentUser,
          nombreChat: nombreChat,
          esGrupal: esGrupal,
        ),
      ),
    );
  }
}

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
    _searchController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = Future.wait([
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

      final results = await futures;

      if (mounted) {
        setState(() {
          _trabajadores = results[0] as List<TrabajadorModel>;
          _trabajadoresFiltrados = _trabajadores;
          _residentes = results[1] as List<ResidenteModel>;
          _residentesFiltrados = _residentes;
          _comite = results[2] as List<ComiteModel>;
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

  void _filtrarUsuarios() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _trabajadoresFiltrados = _trabajadores.where((trabajador) {
        final nombre = trabajador.nombre.toLowerCase();
        final tipo = trabajador.tipoTrabajador.toLowerCase();
        return nombre.contains(query) || tipo.contains(query);
      }).toList();

      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.viviendaSeleccionada.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();

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
              backgroundColor: Colors.blue.shade600,
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
              backgroundColor: Colors.blue.shade600,
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
              'Buscar Usuario',
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

          // Tabs
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

          // Contenido de las tabs
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