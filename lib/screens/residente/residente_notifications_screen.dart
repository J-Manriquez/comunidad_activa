import 'package:comunidad_activa/models/residente_model.dart';
import 'package:comunidad_activa/screens/residente/r_seleccion_vivienda_screen.dart';
import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ResidenteNotificationsScreen extends StatefulWidget {
  final String condominioId;

  const ResidenteNotificationsScreen({super.key, required this.condominioId});

  @override
  State<ResidenteNotificationsScreen> createState() =>
      _ResidenteNotificationsScreenState();
}

class _ResidenteNotificationsScreenState
    extends State<ResidenteNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  ResidenteModel? _residente;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mis Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(
          condominioId: widget.condominioId,
          userId: user.uid,
          userType: 'residentes',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                    'Error al cargar notificaciones',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
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
                    'No tienes notificaciones',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(
                notification as NotificationModel,
                user.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, String userId) {
    final isRead = notification.isRead != null;

    Color typeColor;
    IconData typeIcon;
    String typeText;

    switch (notification.notificationType) {
      case 'vivienda_rechazada':
        typeColor = Colors.red;
        typeIcon = Icons.home_outlined;
        typeText = 'Vivienda Rechazada';
        break;
      case 'vivienda_aprobada':
        typeColor = Colors.green;
        typeIcon = Icons.home;
        typeText = 'Vivienda Aprobada';
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.notifications;
        typeText = 'Notificación';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 2 : 4,
      child: InkWell(
        onTap: () => _showNotificationDetails(notification, userId),
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
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      typeText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
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
                  if (!isRead)
                    Text(
                      'Toca para leer',
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

  Future<void> _loadResidenteData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        if (mounted) {
          setState(() {
            _residente = residente;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNotificationDetails(
    NotificationModel notification,
    String userId,
  ) async {
    // Marcar como leída si no lo está
    if (notification.isRead == null) {
      final residente = await _firestoreService.getResidenteData(userId);
      if (residente != null) {
        await _notificationService.markNotificationAsRead(
          condominioId: widget.condominioId,
          notificationId: notification.id,
          userName: residente.nombre,
          userId: residente.uid,
          userType: 'residentes',
          targetUserId: userId,
          targetUserType: 'residentes',
        );
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                notification.notificationType == 'vivienda_rechazada'
                    ? Icons.home_outlined
                    : notification.notificationType == 'vivienda_aprobada'
                        ? Icons.home
                        : Icons.notifications,
                color: notification.notificationType == 'vivienda_rechazada'
                    ? Colors.red.shade600
                    : notification.notificationType == 'vivienda_aprobada'
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              const Text('Detalle de Notificación'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.additionalData?['viviendaSolicitada'] != null)
                  _buildDetailRow(
                    'Vivienda',
                    notification.additionalData!['viviendaSolicitada'],
                  ),
                _buildDetailRow(
                  'Fecha',
                  '${notification.date} - ${notification.time}',
                ),
                _buildDetailRow(
                  'Tipo',
                  _getNotificationTypeText(notification.notificationType),
                ),
                const SizedBox(height: 16),
                Text(
                  notification.content,
                  style: const TextStyle(fontSize: 14),
                ),
                // Mostrar mensaje del administrador si existe
                if (notification.notificationType == 'vivienda_rechazada' &&
                    notification.additionalData?['mensajeAdmin'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.message,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mensaje del Administrador:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.additionalData!['mensajeAdmin'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
                if (notification.notificationType == 'vivienda_rechazada') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ResidenteSeleccionViviendaScreen(
                                  condominioId: widget.condominioId,
                                  onViviendaSeleccionada: () {
                                    _loadResidenteData();
                                  },
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Puede intentar seleccionar otra vivienda disponible dando click aquí.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'vivienda_rechazada':
        return 'Vivienda Rechazada';
      case 'vivienda_aprobada':
        return 'Vivienda Aprobada';
      default:
        return 'Notificación General';
    }
  }
}
