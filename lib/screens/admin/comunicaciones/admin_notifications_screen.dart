import 'package:comunidad_activa/models/user_model.dart';
import 'package:comunidad_activa/screens/admin/comunicaciones/admin_reclamos_screen.dart';
import 'package:comunidad_activa/screens/admin/comunicaciones/mensajes_admin_screen.dart';
import 'package:comunidad_activa/screens/admin/estacionamientos/solicitudes_estacionamiento_admin_screen.dart';
import 'package:comunidad_activa/screens/admin/estacionamientos/estacionamientos_visitas_screen.dart';
import 'package:comunidad_activa/screens/chat_screen.dart';
import 'package:comunidad_activa/services/auth_service.dart';
import 'package:comunidad_activa/services/firestore_service.dart';
import 'package:comunidad_activa/services/mensaje_service.dart';
import 'package:comunidad_activa/services/notification_service.dart';
import 'package:comunidad_activa/models/notification_model.dart';
import 'package:comunidad_activa/services/bloqueo_service.dart';
import 'package:comunidad_activa/services/estacionamiento_service.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatefulWidget {
  final String condominioId;

  const AdminNotificationsScreen({super.key, required this.condominioId});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final BloqueoService _bloqueoService = BloqueoService();

  UserModel? user;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await _authService.getCurrentUserData();
      if (mounted) {
        setState(() {
          user = currentUser;
        });
      }
    } catch (e) {
      print('❌ Error al cargar usuario actual: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notificaciones del Condominio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getCondominioNotifications(
          widget.condominioId,
        ),
        builder: (context, snapshot) {
          print('Estado de conexión: ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error en StreamBuilder: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar notificaciones: ${snapshot.error}',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          print('Notificaciones recibidas: ${notifications.length}');

          // Filtrar notificaciones relevantes para administradores
          final relevantNotifications = notifications
              .where(
                (n) =>
                    n.notificationType == 'solicitud_vivienda' ||
                    n.notificationType == 'nuevo_reclamo' ||
                    n.notificationType == 'mensaje' ||
                    n.notificationType == 'solicitud_estacionamiento' ||
                    n.notificationType == 'solicitud_estacionamiento_visita',
              )
              .toList();

          print('Notificaciones relevantes: ${relevantNotifications.length}');
          for (var notif in relevantNotifications) {
            print(
              '- Tipo: ${notif.notificationType}, Contenido: ${notif.content}',
            );
          }

          if (relevantNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notificaciones pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: relevantNotifications.length,
            itemBuilder: (context, index) {
              final notification = relevantNotifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  // Función principal de manejo de notificaciones
  void _handleNotificationTap(NotificationModel notification) async {
    // Marcar notificación como leída
    await _markNotificationAsRead(notification);

    // Manejar según el tipo de notificación
    switch (notification.notificationType) {
      case 'mensaje':
        _handleMessageNotification(notification);
        break;
      case 'nuevo_reclamo':
        _handleReclamoNotification(notification);
        break;
      case 'solicitud_vivienda':
        _handleHousingRequestNotification(notification);
        break;
      case 'solicitud_estacionamiento':
        // Navegar a la pantalla dedicada de solicitudes de estacionamiento
        _handleParkingRequestNotification(notification);
        break;
      case 'solicitud_estacionamiento_visita':
        // Navegar a la pantalla de estacionamientos de visitas
        _handleParkingVisitRequestNotification(notification);
        break;
      default:
        _showGenericNotificationDetails(notification);
    }
  }

  // Función para manejar notificaciones de mensajes
  void _handleMessageNotification(NotificationModel notification) async {
    try {
      final chatId = notification.additionalData?['chatId'];
      final tipoChat = notification.additionalData?['tipoChat'];
      final remitenteNombre = notification.additionalData?['remitenteId'];

      if (chatId != null) {
        String nombreChat;
        bool esGrupal = false;

        if (tipoChat == 'grupal') {
          nombreChat = 'Chat General del Condominio';
          esGrupal = true;
        } else if (tipoChat == 'conserjeria') {
          nombreChat = 'Conserjería';
        } else {
          nombreChat = remitenteNombre ?? 'Chat';
        }

        // Marcar todos los mensajes del chat como leídos y eliminar notificaciones
        final mensajeService = MensajeService();
        final admin = await _firestoreService.getAdministradorData(
          widget.condominioId,
        );

        if (admin != null) {
          await mensajeService.marcarTodosMensajesComoLeidos(
            condominioId: widget.condominioId,
            chatId: chatId,
            usuarioId: admin.uid,
            nombreUsuario: admin.nombre,
            tipoUsuario: 'administrador',
          );
        }

        // Eliminar notificaciones
        // ✅ NUEVO: Borrar notificaciones de mensajes del condominio para este chat
        await _notificationService.borrarNotificacionesMensajeCondominio(
          condominioId: widget.condominioId,
          chatId: chatId,
        );

        if (chatId != null) {
          // Navegar al chat específico
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                currentUser: user!,
                nombreChat: nombreChat,
                esGrupal: esGrupal,
              ),
            ),
          );
        } else {
          // Si no hay chatId, ir a la pantalla de mensajes general
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MensajesAdminScreen(currentUser: user!),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al manejar notificación de mensaje: $e');
      _showErrorSnackBar('Error al abrir el chat: $e');
    }
  }

  // Función para manejar notificaciones de reclamos
  void _handleReclamoNotification(NotificationModel notification) async {
    try {
      final reclamoId = notification.additionalData?['reclamoId'];

      if (reclamoId != null) {
        // Navegar directamente al reclamo específico
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminReclamosScreen(
              currentUser: user!,
              reclamoIdToOpen: reclamoId,
            ),
          ),
        );
      } else {
        // Si no hay reclamoId específico, mostrar detalles y luego ir a reclamos
        _showReclamoDetails(notification);
      }
    } catch (e) {
      print('❌ Error al manejar notificación de reclamo: $e');
      _showErrorSnackBar('Error al abrir el reclamo: $e');
    }
  }

  // Función para manejar notificaciones de solicitud de vivienda
  void _handleHousingRequestNotification(NotificationModel notification) {
    _showHousingRequestDetails(notification);
  }

  // Función para manejar notificaciones de solicitud de estacionamiento
  void _handleParkingRequestNotification(NotificationModel notification) async {
    try {
      // Navegar directamente a la pantalla de solicitudes de estacionamiento
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SolicitudesEstacionamientoAdminScreen(
            condominioId: widget.condominioId,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error al navegar a solicitudes de estacionamiento: $e');
      _showErrorSnackBar('Error al abrir solicitudes de estacionamiento: $e');
    }
  }

  // Función para manejar notificaciones de solicitud de estacionamiento de visitas
  void _handleParkingVisitRequestNotification(NotificationModel notification) async {
    try {
      // Navegar directamente a la pantalla de estacionamientos de visitas
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EstacionamientosVisitasScreen(
            condominioId: widget.condominioId,
            modoResidente: false, // Modo administrador
          ),
        ),
      );
    } catch (e) {
      print('❌ Error al navegar a estacionamientos de visitas: $e');
      _showErrorSnackBar('Error al abrir estacionamientos de visitas: $e');
    }
  }



  // Función auxiliar para marcar notificación como leída
  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead == null) {
      final user = _authService.currentUser;
      if (user != null) {
        final admin = await _firestoreService.getAdministradorData(
          widget.condominioId,
        );
        if (admin != null) {
          await _notificationService.markNotificationAsRead(
            condominioId: widget.condominioId,
            notificationId: notification.id,
            userId: admin.uid,
            userType: 'administrador',
            isCondominioNotification: true,
          );
        }
      }
    }
  }

  // Función auxiliar para mostrar errores
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isRead = notification.isRead != null;
    final isPending = notification.status == 'pendiente';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String title;

    // Configurar según el tipo de notificación
    switch (notification.notificationType) {
      case 'mensaje':
        statusColor = Colors.blue;
        statusIcon = Icons.message;
        statusText = 'Nuevo Mensaje';
        title =
            'Mensaje de ${notification.additionalData?['senderName'] ?? 'Usuario'}';
        break;
      case 'nuevo_reclamo':
        statusColor = Colors.orange;
        statusIcon = Icons.report_problem;
        statusText = 'Nuevo Reclamo';
        title =
            'Reclamo: ${notification.additionalData?['tipoReclamo'] ?? 'Sin tipo'}';
        break;
      case 'solicitud_vivienda':
        statusColor = isPending
            ? Colors.orange
            : (notification.status == 'aprobada' ? Colors.green : Colors.red);
        statusIcon = isPending
            ? Icons.pending
            : (notification.status == 'aprobada'
                  ? Icons.check_circle
                  : Icons.cancel);
        statusText = isPending
            ? 'Pendiente'
            : (notification.status == 'aprobada' ? 'Aprobada' : 'Rechazada');
        title = 'Solicitud de Vivienda';
        break;
      case 'solicitud_estacionamiento':
        statusColor = Colors.purple;
        statusIcon = Icons.local_parking;
        statusText = 'Ver en Solicitudes de Estacionamiento';
        title = 'Solicitud de Estacionamiento';
        break;
      case 'solicitud_estacionamiento_visita':
        statusColor = Colors.deepPurple;
        statusIcon = Icons.person_add;
        statusText = 'Ver en Estacionamientos de Visitas';
        title = 'Solicitud de Estacionamiento de Visitas';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.notifications;
        statusText = 'Notificación';
        title = 'Notificación General';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 2 : 4,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isRead
                ? null
                : Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.content,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notification.date} - ${notification.time}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (isPending &&
                      notification.notificationType == 'solicitud_vivienda')
                    Text(
                      'Toca para responder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReclamoDetails(NotificationModel notification) async {
    print('🔍 Mostrando detalles del reclamo: ${notification.additionalData}');

    try {
      if (!mounted) return;

      // Obtener el ID del reclamo desde additionalData
      final reclamoId = notification.additionalData?['reclamoId'];

      if (reclamoId != null) {
        // Navegar directamente a AdminReclamosScreen con el ID del reclamo específico
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminReclamosScreen(
              currentUser: user!,
              reclamoIdToOpen: reclamoId,
            ),
          ),
        );
      } else {
        // Si no hay reclamoId, mostrar el diálogo actual como fallback
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.report_problem, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Detalle del Reclamo'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo: ${notification.additionalData?['tipoReclamo'] ?? 'No especificado'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Residente: ${notification.additionalData?['nombreResidente'] ?? 'Desconocido'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contenido:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(notification.content),
                const SizedBox(height: 16),
                Text(
                  'Fecha ${notification.date} - ${notification.time}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdminReclamosScreen(currentUser: user!),
                    ),
                  );
                },
                child: const Text('Ver Todos los Reclamos'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error al mostrar detalles del reclamo: $e');
      _showErrorSnackBar('Error al cargar detalles: $e');
    }
  }

  void _showHousingRequestDetails(NotificationModel notification) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.home_work, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Solicitud de Vivienda'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Residente',
                  notification.additionalData?['residenteNombre'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Email',
                  notification.additionalData?['residenteEmail'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Vivienda solicitada',
                  notification.additionalData?['descripcionVivienda'] ?? 'N/A',
                ),
                _buildDetailRow(
                  'Fecha',
                  '${notification.date} - ${notification.time}',
                ),
                _buildDetailRow('Estado', notification.status),
                const SizedBox(height: 16),
                Text(
                  notification.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            if (notification.status == 'pendiente') ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRejectOptions(notification);
                },
                child: Text(
                  'Rechazar',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleHousingRequest(notification, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aprobar'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ],
        );
      },
    );
  }



  void _showGenericNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de Notificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo: ${notification.notificationType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(notification.content),
            const SizedBox(height: 16),
            Text(
              'Fecha: ${notification.date} - ${notification.time}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

  void _showRejectOptions(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Opciones de Rechazo'),
          content: const Text(
            'Seleccione una opción para rechazar la solicitud',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMessageDialog(notification);
              },
              child: const Text('Enviar mensaje al residente'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bloquearResidente(notification);
              },
              child: Text(
                'Eliminar y bloquear residente',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageDialog(NotificationModel notification) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mensaje para el residente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escriba un mensaje explicando el motivo del rechazo:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Escriba su mensaje aquí...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleHousingRequest(
                  notification,
                  false,
                  messageController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar con mensaje'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bloquearResidente(NotificationModel notification) async {
    print('🔒 Iniciando proceso de bloqueo de residente');

    final TextEditingController razonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear Residente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese la razón del bloqueo:'),
            const SizedBox(height: 16),
            TextField(
              controller: razonController,
              decoration: const InputDecoration(
                hintText: 'Razón del bloqueo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final razon = razonController.text.trim();
              if (razon.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe ingresar una razón')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                print('🔍 Obteniendo datos del residente desde additionalData');
                final additionalData = notification.additionalData;
                print('📋 AdditionalData: $additionalData');

                if (additionalData == null) {
                  print('❌ Error: additionalData es null');
                  throw Exception(
                    'No se encontraron datos adicionales en la notificación',
                  );
                }

                final residenteId = additionalData['residenteId'] as String?;
                print('👤 ResidenteId obtenido: $residenteId');

                if (residenteId == null || residenteId.isEmpty) {
                  print('❌ Error: residenteId es null o vacío');
                  throw Exception('ID del residente no encontrado');
                }

                print(
                  '🔍 Obteniendo datos completos del residente desde Firestore',
                );
                final residenteData = await _firestoreService.getResidenteData(
                  residenteId,
                );
                print(
                  '📊 Datos del residente obtenidos: ${residenteData?.toMap()}',
                );

                if (residenteData == null) {
                  print(
                    '❌ Error: No se encontraron datos del residente en Firestore',
                  );
                  throw Exception('No se encontraron datos del residente');
                }

                print(
                  '🚫 Bloqueando residente con email: ${residenteData.email}',
                );
                await _bloqueoService.bloquearResidente(
                  condominioId: widget.condominioId,
                  residente: residenteData,
                  motivo: razon,
                );
                print('✅ Residente bloqueado exitosamente');

                print('📝 Actualizando estado de notificación');
                await _notificationService.updateNotificationStatus(
                  condominioId: widget.condominioId,
                  notificationId: notification.id,
                  newStatus: 'residente_bloqueado',
                  isCondominioNotification: true,
                );
                print('✅ Estado de notificación actualizado');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Residente bloqueado exitosamente'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error en el proceso de bloqueo: $e');
                _showErrorSnackBar('Error al bloquear residente: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Bloquear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _handleHousingRequest(
    NotificationModel notification,
    bool approve, [
    String? adminMessage,
  ]) async {
    try {
      final additionalData = notification.additionalData;
      if (additionalData == null) return;

      final residenteId = additionalData['residenteId'] as String;
      final residenteNombre = additionalData['residenteNombre'] as String;
      final vivienda = additionalData['vivienda'] as String;
      final tipo = additionalData['tipo'] as String;
      final etiquetaEdificio = additionalData['etiquetaEdificio'] as String?;
      final descripcionVivienda =
          additionalData['descripcionVivienda'] as String;

      if (approve) {
        // Aprobar: actualizar datos del residente
        final residenteActual = await _firestoreService.getResidenteData(
          residenteId,
        );
        if (residenteActual != null) {
          Map<String, dynamic> updateData;

          if (tipo == 'Casa') {
            updateData = {
              'tipoVivienda': 'casa',
              'numeroVivienda': vivienda,
              'viviendaSeleccionada': 'seleccionada',
            };
          } else {
            updateData = {
              'tipoVivienda': 'departamento',
              'etiquetaEdificio': etiquetaEdificio,
              'numeroDepartamento': vivienda,
              'viviendaSeleccionada': 'seleccionada',
            };
          }

          await _firestoreService.updateResidenteData(residenteId, updateData);

          // Actualizar estado de la notificación
          await _notificationService.updateNotificationStatus(
            condominioId: widget.condominioId,
            notificationId: notification.id,
            newStatus: 'aprobada',
            isCondominioNotification: true,
          );

          // Enviar notificación de aprobación al residente
          await _notificationService.createUserNotification(
            condominioId: widget.condominioId,
            userId: residenteId,
            userType: 'residentes',
            tipoNotificacion: 'vivienda_aprobada',
            contenido:
                'Su solicitud de vivienda ha sido aprobada. Ya puede acceder a todas las funcionalidades del sistema.',
            additionalData: {
              'viviendaSolicitada': descripcionVivienda,
              'fechaAprobacion': DateTime.now().toIso8601String(),
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solicitud aprobada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        print('🚫 Rechazando solicitud de vivienda');

        // Actualizar estado del residente a 'no_seleccionada' para reactivar el modal
        await _firestoreService.actualizarEstadoViviendaResidente(
          widget.condominioId,
          residenteId,
          'no_seleccionada',
        );
        print('✅ Estado de vivienda actualizado a no_seleccionada');

        // Rechazar: actualizar estado y enviar notificación
        await _notificationService.updateNotificationStatus(
          condominioId: widget.condominioId,
          notificationId: notification.id,
          newStatus: 'rechazada',
          isCondominioNotification: true,
        );

        // Crear notificación de rechazo para el residente
        Map<String, dynamic> rejectionData = {
          'viviendaSolicitada': descripcionVivienda,
          'fechaRechazo': DateTime.now().toIso8601String(),
        };

        if (adminMessage != null && adminMessage.isNotEmpty) {
          rejectionData['mensajeAdmin'] = adminMessage;
        }

        await _notificationService.createUserNotification(
          condominioId: widget.condominioId,
          userId: residenteId,
          userType: 'residentes',
          tipoNotificacion: 'vivienda_rechazada',
          contenido:
              'Su solicitud de vivienda ha sido rechazada. Puede intentar seleccionar otra vivienda disponible.',
          additionalData: rejectionData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Solicitud rechazada y residente puede volver a seleccionar vivienda',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }
}
