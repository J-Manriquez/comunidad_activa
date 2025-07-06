import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/mensaje_model.dart';
import '../services/mensaje_service.dart';
import '../services/firestore_service.dart';
import '../services/unread_messages_service.dart';
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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MensajeService _mensajeService = MensajeService();
  final FirestoreService _firestoreService = FirestoreService();
  late final UnreadMessagesService _unreadService;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, String> _nombresUsuarios = {};
  bool _isLoading = false;
  bool _isLoadingMoreMessages = false;
  bool _isUploadingImage = false;
  List<ContenidoMensajeModel> _mensajes = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMessages = true;
  bool _isInitialLoad = true;
  StreamSubscription<QuerySnapshot>? _mensajesSubscription;
  Timer? _marcadoAutomaticoTimer;
  String? _imagenSeleccionadaBase64;
  FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _unreadService = UnreadMessagesService();
    WidgetsBinding.instance.addObserver(this);
    _cargarNombresUsuarios();
    _cargarMensajesIniciales();
    _scrollController.addListener(_onScroll);
    _iniciarListenerMensajes();
    _iniciarMarcadoAutomaticoLeidos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    _unreadService.dispose();
    _mensajesSubscription?.cancel();
    _marcadoAutomaticoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print('📱 App volvió al primer plano - marcando mensajes como leídos');
      _marcarMensajesComoLeidosConUnreadService();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMoreMessages &&
        _hasMoreMessages) {
      _cargarMasMensajes();
    }
  }

  Future<void> _cargarMensajesIniciales() async {
    try {
      final query = FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId.toString())
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(widget.chatId)
          .collection('contenido')
          .orderBy('fechaHoraCreacion', descending: true)
          .limit(20);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final mensajes = snapshot.docs
            .map(
              (doc) => ContenidoMensajeModel.fromFirestore(doc.data(), doc.id),
            )
            .toList();

        setState(() {
          _mensajes = mensajes.reversed.toList();
          _hasMoreMessages = snapshot.docs.length == 20;
          _isInitialLoad = false;
        });

        // Marcar mensajes como leídos
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _marcarMensajesComoLeidos(_mensajes);
          _marcarMensajesComoLeidosConUnreadService();
          _scrollToBottom();
        });
      } else {
        setState(() {
          _isInitialLoad = false;
          _hasMoreMessages = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar mensajes iniciales: $e');
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _cargarMasMensajes() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages || _lastDocument == null)
      return;

    setState(() {
      _isLoadingMoreMessages = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId.toString())
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(widget.chatId)
          .collection('contenido')
          .orderBy('fechaHoraCreacion', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(20);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final nuevosMensajes = snapshot.docs
            .map(
              (doc) => ContenidoMensajeModel.fromFirestore(doc.data(), doc.id),
            )
            .toList()
            .reversed
            .toList();

        setState(() {
          _mensajes.insertAll(0, nuevosMensajes);
          _hasMoreMessages = snapshot.docs.length == 20;
        });

        setState(() {
          // Marcar mensajes como leídos
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _marcarMensajesComoLeidos(nuevosMensajes);
            _marcarMensajesComoLeidosConUnreadService();
            _scrollToBottom();
          });
        });

        // Marcar mensajes como leídos
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _marcarMensajesComoLeidos(nuevosMensajes);
          _marcarMensajesComoLeidosConUnreadService();
          _scrollToBottom();
        });
      } else {
        setState(() {
          _hasMoreMessages = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar más mensajes: $e');
    } finally {
      setState(() {
        _isLoadingMoreMessages = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _iniciarListenerMensajes() {
    // Esperar a que se carguen los mensajes iniciales antes de iniciar el listener
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Escuchar TODOS los mensajes del chat para detectar cambios en tiempo real
      Query query = FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId.toString())
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(widget.chatId)
          .collection('contenido')
          .orderBy('fechaHoraCreacion', descending: false);

      _mensajesSubscription = query.snapshots().listen((snapshot) {
        print('🔄 Listener de mensajes activado - ${snapshot.docs.length} mensajes');
        
        if (snapshot.docs.isNotEmpty) {
          final mensajesActualizados = <ContenidoMensajeModel>[];
          
          for (final doc in snapshot.docs) {
            final mensajeActualizado = ContenidoMensajeModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            mensajesActualizados.add(mensajeActualizado);
          }

          // Verificar si hay mensajes nuevos o actualizaciones
          final mensajesNuevos = <ContenidoMensajeModel>[];
          bool hayActualizaciones = false;
          
          for (final mensajeActualizado in mensajesActualizados) {
            final indiceExistente = _mensajes.indexWhere((m) => m.id == mensajeActualizado.id);
            
            if (indiceExistente == -1) {
              // Mensaje nuevo
              mensajesNuevos.add(mensajeActualizado);
            } else {
              // Verificar si el campo isRead cambió
              final mensajeExistente = _mensajes[indiceExistente];
              if (mensajeExistente.isRead.toString() != mensajeActualizado.isRead.toString()) {
                print('📝 Actualizando estado de lectura para mensaje ${mensajeActualizado.id}');
                _mensajes[indiceExistente] = mensajeActualizado;
                hayActualizaciones = true;
              }
            }
          }

          // Actualizar UI si hay cambios
          if (mensajesNuevos.isNotEmpty || hayActualizaciones) {
            setState(() {
              // Agregar mensajes nuevos
              _mensajes.addAll(mensajesNuevos);
            });

            // Hacer scroll solo para mensajes nuevos
            if (mensajesNuevos.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _marcarMensajesComoLeidos(mensajesNuevos);
                _marcarMensajesComoLeidosConUnreadService();
                _scrollToBottom();
              });
            }
          }
        }
        
        // Marcar todos los mensajes no leídos como leídos cuando el usuario está en el chat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _marcarMensajesComoLeidosConUnreadService();
        });
      });
    });
  }

  void _iniciarMarcadoAutomaticoLeidos() {
    // Marcar mensajes inmediatamente al entrar al chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 Marcado inicial al entrar al chat');
      _marcarMensajesComoLeidosConUnreadService();
    });
    
    // Marcar mensajes como leídos cada 3 segundos mientras el usuario esté en el chat
    _marcadoAutomaticoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        print('🔄 Ejecutando marcado automático de mensajes...');
        _marcarMensajesComoLeidosConUnreadService();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _cargarNombresUsuarios() async {
    try {
      if (widget.esGrupal) {
        // Cargar nombres de todos los residentes y administrador
        final residentes = await _firestoreService.obtenerResidentesCondominio(
          widget.currentUser.condominioId.toString(),
        );
        final admin = await _firestoreService.getAdministradorData(
          widget.currentUser.condominioId.toString(),
        );

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
    // Marcar mensajes como leídos automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcarMensajesComoLeidos(_mensajes);
      _marcarMensajesComoLeidosConUnreadService();
    });
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
            child: _isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay mensajes aún.\n¡Envía el primer mensaje!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      // Indicador de carga para mensajes anteriores
                      if (_isLoadingMoreMessages)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[700]!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Cargando mensajes anteriores...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Lista de mensajes
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) {
                            final mensaje = _mensajes[index];
                            return _buildMensajeCard(mensaje);
                          },
                        ),
                      ),
                    ],
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
                if (mensaje.texto != null && mensaje.texto!.isNotEmpty)
                  Text(mensaje.texto!, style: const TextStyle(fontSize: 16)),
                // Mostrar imagen si existe
                if (mensaje.additionalData != null && mensaje.additionalData!['imagenBase64'] != null)
                  _buildImagenMensaje(mensaje.additionalData!['imagenBase64']),
                const SizedBox(height: 8),
                // Información del mensaje
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat(
                        'HH:mm',
                      ).format(DateTime.parse(mensaje.fechaHoraCreacion)),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      child: Column(
        children: [
          // Vista previa de imagen seleccionada
          if (_imagenSeleccionadaBase64 != null)
            _buildVistaPrevia(),
          Row(
            children: [
              // Botón de imagen
              IconButton(
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : Icon(
                        Icons.image,
                        color: Colors.blue[700],
                      ),
                onPressed: _isUploadingImage ? null : _seleccionarImagen,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _textFieldFocusNode,
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
                  onSubmitted: (_) => _enviarMensaje(),
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
        ],
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty && _imagenSeleccionadaBase64 == null) return;

    setState(() => _isLoading = true);

    try {
      // Preparar additionalData si hay imagen
      Map<String, dynamic>? additionalData;
      if (_imagenSeleccionadaBase64 != null) {
        additionalData = {
          'imagenBase64': _imagenSeleccionadaBase64,
        };
      }

      // Enviar mensaje a Firestore
      await _mensajeService.enviarMensaje(
        condominioId: widget.currentUser.condominioId.toString(),
        chatId: widget.chatId,
        autorUid: widget.currentUser.uid,
        texto: texto.isNotEmpty ? texto : null,
        additionalData: additionalData,
      );

      _messageController.clear();
      setState(() {
        _imagenSeleccionadaBase64 = null;
      });

      // El listener en tiempo real se encargará de agregar el mensaje
      // Solo hacemos scroll al final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
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

  Future<void> _marcarMensajesComoLeidos(
    List<ContenidoMensajeModel> mensajes,
  ) async {
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

  /// Marca los mensajes como leídos usando el UnreadMessagesService
  /// para actualizar los contadores en tiempo real
  Future<void> _marcarMensajesComoLeidosConUnreadService() async {
    try {
      print('📱 Iniciando marcado de mensajes como leídos...');
      
      // Obtener mensajes no leídos del usuario actual
      final snapshot = await FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId.toString())
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(widget.chatId)
          .collection('contenido')
          .where('autorUid', isNotEqualTo: widget.currentUser.uid)
          .get();

      print('📊 Total de mensajes encontrados: ${snapshot.docs.length}');
      
      int mensajesMarcados = 0;
      
      // Marcar cada mensaje usando el formato correcto del MensajeService
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isRead = data['isRead'] as Map<String, dynamic>? ?? {};

        // Solo marcar si no está ya leído por este usuario
        if (!isRead.containsKey(widget.currentUser.uid)) {
          print('✅ Marcando mensaje ${doc.id} como leído');
          await _mensajeService.marcarMensajeComoLeido(
            condominioId: widget.currentUser.condominioId.toString(),
            chatId: widget.chatId,
            contenidoId: doc.id,
            usuarioId: widget.currentUser.uid,
            nombreUsuario: widget.currentUser.nombre,
          );
          mensajesMarcados++;
        }
      }
      
      print('🎯 Mensajes marcados como leídos: $mensajesMarcados');
    } catch (e) {
      print('❌ Error al marcar mensajes como leídos con UnreadService: $e');
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

            // Manejar tanto el formato bool como el formato Map
            String nombre = 'Usuario';
            String fechaHora = '';

            if (entry.value is Map<String, dynamic>) {
              final readInfo = entry.value as Map<String, dynamic>;
              nombre = readInfo['nombre'] ?? 'Usuario';
              fechaHora = readInfo['fechaHora'] ?? '';
            } else if (entry.value is bool && entry.value == true) {
              // Formato simplificado (solo bool)
              nombre = 'Usuario';
              fechaHora = 'Leído';
            } else {
              return const SizedBox.shrink(); // No mostrar si no está leído
            }

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
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(DateTime.parse(fechaHora)),
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

  // Método para seleccionar imagen
  Future<void> _seleccionarImagen() async {
    try {
      setState(() => _isUploadingImage = true);

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imagenSeleccionadaBase64 = base64String;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // Widget para vista previa de imagen seleccionada
  Widget _buildVistaPrevia() {
    if (_imagenSeleccionadaBase64 == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(_imagenSeleccionadaBase64!),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Imagen seleccionada',
              style: TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _imagenSeleccionadaBase64 = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // Widget para mostrar imagen en mensaje
  Widget _buildImagenMensaje(String imagenBase64) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => _mostrarImagenCompleta(imagenBase64),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(imagenBase64),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Mostrar imagen en pantalla completa
  void _mostrarImagenCompleta(String imagenBase64) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(imagenBase64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
