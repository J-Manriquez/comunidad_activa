import 'dart:convert';
import 'package:comunidad_activa/models/residente_model.dart';
import 'package:comunidad_activa/models/user_model.dart';
import 'package:comunidad_activa/screens/chat_screen.dart';
import 'package:comunidad_activa/screens/residente/comunicaciones/r_multas_screen.dart';
import 'package:comunidad_activa/screens/residente/comunicaciones/r_reclamos_screen.dart';
import 'package:comunidad_activa/screens/residente/r_seleccion_vivienda_screen.dart';
import 'package:comunidad_activa/services/mensaje_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';

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
  final TextEditingController _respuestaNotificacionController = TextEditingController();
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

  void _handleNotificationTap(
  NotificationModel notification,
  String userId,
) async {
  // Marcar como leída si no lo está
  final residente = await _firestoreService.getResidenteData(userId);
  if (notification.isRead == null) {
    if (residente != null) {
      await _notificationService.markNotificationAsRead(
        condominioId: widget.condominioId,
        notificationId: notification.id,
        userId: residente.uid,
        userType: 'residentes',
        targetUserId: userId,
        targetUserType: 'residentes',
      );
    }
  }

  if (!mounted) return;

  // Manejar según el tipo de notificación
  if (notification.notificationType == 'multa') {
    // Navegar a la pantalla de multas con el ID de la multa
    final multaId = notification.additionalData?['multaId'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultasResidenteScreen(
          currentUser: UserModel(
            uid: userId,
            condominioId: widget.condominioId,
            email: residente!.email,
            nombre:residente.nombre,
            tipoUsuario: UserType.residente,
          ),
          multaIdToOpen: multaId,
        ),
      ),
    );
  } else if (notification.notificationType == 'reclamo_resuelto') {
    // Navegar a la pantalla de reclamos y mostrar el detalle del reclamo resuelto
    final reclamoId = notification.additionalData?['reclamoId'];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReclamosResidenteScreen(
          currentUser: UserModel(
            uid: userId,
            condominioId: widget.condominioId,
            email: residente!.email,
            nombre: residente.nombre,
            tipoUsuario: UserType.residente,
          ),
          reclamoIdToOpen: reclamoId, // Pasar el ID del reclamo a abrir
        ),
      ),
    );
  } else if (notification.notificationType == 'nuevo_mensaje') {
      // NUEVO: Navegar al chat correspondiente
      final chatId = notification.additionalData?['chatId'];
      final tipoChat = notification.additionalData?['tipoChat'];
      final remitenteNombre = notification.additionalData?['remitenteId'];
      
      // ✅ CORREGIDO: Eliminar notificaciones específicas del chat
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

        // ✅ NUEVO: Eliminar notificaciones específicas del chat
        final notificationService = NotificationService();
        await notificationService.deleteMessageNotifications(
          condominioId: widget.condominioId,
          chatId: chatId,
          userId: userId,
          userType: 'residentes',
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: UserModel(
                uid: userId,
                condominioId: widget.condominioId,
                email: residente!.email,
                nombre: residente.nombre,
                tipoUsuario: UserType.residente,
              ),
              chatId: chatId,
              nombreChat: nombreChat,
              esGrupal: esGrupal,
            ),
          ),
        );
      }
    }else {
    // Para otros tipos de notificaciones, mostrar el diálogo normal
    _showNotificationDetails(notification, userId);
  }
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
      case 'multa': // Agregar este caso
        typeColor = Colors.redAccent;
        typeIcon = Icons.gavel;
        typeText = 'Nueva Multa';
        break;
      case 'nuevo_mensaje': // NUEVO CASO
        typeColor = Colors.blue;
        typeIcon = Icons.message;
        typeText = 'Nuevo Mensaje';
        break;
      case 'reclamo_resuelto':
        typeColor = Colors.green;
        typeIcon = Icons.check_circle;
        typeText = 'Reclamo Resuelto';
        break;
      case 'confirmacion_entrega':
        typeColor = Colors.orange;
        typeIcon = Icons.local_shipping;
        typeText = 'Confirmación de Entrega';
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
        onTap: () => _handleNotificationTap(notification, userId),
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

  // Diálogo para notificaciones de vivienda
void _showViviendaNotificationDialog(NotificationModel notification) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              notification.notificationType == 'vivienda_rechazada'
                  ? Icons.home_outlined
                  : Icons.home,
              color: notification.notificationType == 'vivienda_rechazada'
                  ? Colors.red.shade600
                  : Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Notificación de Vivienda'),
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

// Diálogo para notificaciones de multas
void _showMultaNotificationDialog(NotificationModel notification) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              notification.notificationType == 'multa_aplicada'
                  ? Icons.warning
                  : Icons.check_circle,
              color: notification.notificationType == 'multa_aplicada'
                  ? Colors.red.shade600
                  : Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Notificación de Multa'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Fecha',
                '${notification.date} - ${notification.time}',
              ),
              _buildDetailRow(
                'Tipo',
                _getNotificationTypeText(notification.notificationType),
              ),
              if (notification.additionalData?['monto'] != null)
                _buildDetailRow(
                  'Monto',
                  'S/ ${notification.additionalData!['monto']}',
                ),
              if (notification.additionalData?['motivo'] != null)
                _buildDetailRow(
                  'Motivo',
                  notification.additionalData!['motivo'],
                ),
              const SizedBox(height: 16),
              Text(
                notification.content,
                style: const TextStyle(fontSize: 14),
              ),
              if (notification.notificationType == 'multa_aplicada') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Puede revisar y pagar sus multas en la sección "Mis Multas".',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
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

// Diálogo para notificaciones de reclamos
void _showReclamoNotificationDialog(NotificationModel notification) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.assignment_turned_in,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Reclamo Resuelto'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Fecha',
                '${notification.date} - ${notification.time}',
              ),
              if (notification.additionalData?['tipoReclamo'] != null)
                _buildDetailRow(
                  'Tipo de Reclamo',
                  notification.additionalData!['tipoReclamo'],
                ),
              const SizedBox(height: 16),
              Text(
                notification.content,
                style: const TextStyle(fontSize: 14),
              ),
              // Mostrar respuesta del administrador
              if (notification.additionalData?['respuestaAdmin'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Respuesta del Administrador:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.additionalData!['respuestaAdmin'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Puede revisar todos sus reclamos en la sección "Mis Reclamos".',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
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

// Diálogo para notificaciones generales
void _showGeneralNotificationDialog(NotificationModel notification) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Notificación General'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

// Actualizar el método _getNotificationTypeText para incluir más tipos
String _getNotificationTypeText(String type) {
  switch (type) {
    case 'vivienda_rechazada':
      return 'Vivienda Rechazada';
    case 'vivienda_aprobada':
      return 'Vivienda Aprobada';
    case 'multa_aplicada':
      return 'Multa Aplicada';
    case 'multa_pagada':
      return 'Multa Pagada';
    case 'reclamo_resuelto':
      return 'Reclamo Resuelto';
    case 'confirmacion_entrega':
      return 'Confirmación de Entrega';
    default:
      return 'Notificación General';
  }
}

// Diálogo para notificaciones de confirmación de entrega
void _showConfirmacionEntregaDialog(NotificationModel notification, String userId) {
  final estado = notification.additionalData?['estado'] ?? 'pendiente';
  final tipoCorrespondencia = notification.additionalData?['tipoCorrespondencia'] ?? 'correspondencia';
  final correspondenciaId = notification.additionalData?['correspondenciaId'];
  
  showDialog(
    context: context,
    barrierDismissible: estado != 'pendiente', // No permitir cerrar si está pendiente
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.local_shipping,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Confirmación de Entrega'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tipo de Correspondencia', tipoCorrespondencia),
              _buildDetailRow('Fecha', '${notification.date} - ${notification.time}'),
              const SizedBox(height: 16),
              Text(
                notification.content,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (estado == 'pendiente') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    '¿Confirma que ha recibido esta correspondencia?',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else if (estado == 'aceptada') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Entrega confirmada',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (estado == 'rechazada') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Entrega rechazada',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (estado == 'pendiente') ...[
            TextButton(
              onPressed: () => _responderConfirmacionEntrega(
                notification.id,
                userId,
                correspondenciaId,
                false,
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              onPressed: () => _responderConfirmacionEntrega(
                notification.id,
                userId,
                correspondenciaId,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
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

// Método para responder a la confirmación de entrega
Future<void> _responderConfirmacionEntrega(
  String notificationId,
  String userId,
  String? correspondenciaId,
  bool aceptada,
) async {
  try {
    // Actualizar el estado en la notificación
    await _notificationService.updateNotificationStatus(
      condominioId: widget.condominioId,
      notificationId: notificationId,
      newStatus: aceptada ? 'aceptada' : 'rechazada',
      userId: userId,
      userType: 'residentes',
    );

    // También actualizar el additionalData para reflejar el nuevo estado
    await FirebaseFirestore.instance
        .collection(widget.condominioId)
        .doc('usuarios')
        .collection('residentes')
        .doc(userId)
        .collection('notificaciones')
        .doc(notificationId)
        .update({
      'additionalData.estado': aceptada ? 'aceptada' : 'rechazada',
      'additionalData.fechaRespuesta': DateTime.now().toIso8601String(),
    });
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceptada 
                ? 'Entrega confirmada exitosamente'
                : 'Entrega rechazada',
          ),
          backgroundColor: aceptada ? Colors.green.shade600 : Colors.red.shade600,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al responder: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
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
          userId: residente.uid,
          userType: 'residentes',
          targetUserId: userId,
          targetUserType: 'residentes',
        );
      }
    }

    if (!mounted) return;


  // Determinar qué tipo de diálogo mostrar
  switch (notification.notificationType) {
    case 'vivienda_aprobada':
    case 'vivienda_rechazada':
      _showViviendaNotificationDialog(notification);
      break;
    case 'multa_aplicada':
    case 'multa_pagada':
      _showMultaNotificationDialog(notification);
      break;
    case 'reclamo_resuelto':
      _showReclamoNotificationDialog(notification);
      break;
    case 'estacionamiento_aprobado':
    case 'estacionamiento_rechazado':
    case 'estacionamiento_visita_aprobado':
    case 'estacionamiento_visita_rechazado':
      _showEstacionamientoNotificationDialog(notification);
      break;
    case 'confirmacion_entrega':
      _showConfirmacionEntregaDialog(notification, userId);
      break;
    case 'correspondencia_recibida':
          _showCorrespondenciaNotificationDialog(notification);
          break;
        case 'mensaje_adicional_correspondencia':
          _showMensajeAdicionalNotificationDialog(notification);
          break;
        default:
          _showGeneralNotificationDialog(notification);
          break;
  }

    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           Icon(
    //             notification.notificationType == 'vivienda_rechazada'
    //                 ? Icons.home_outlined
    //                 : notification.notificationType == 'vivienda_aprobada'
    //                 ? Icons.home
    //                 : Icons.notifications,
    //             color: notification.notificationType == 'vivienda_rechazada'
    //                 ? Colors.red.shade600
    //                 : notification.notificationType == 'vivienda_aprobada'
    //                 ? Colors.green.shade600
    //                 : Colors.blue.shade600,
    //           ),
    //           const SizedBox(width: 8),
    //           const Text('Detalle de Notificación'),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             if (notification.additionalData?['viviendaSolicitada'] != null)
    //               _buildDetailRow(
    //                 'Vivienda',
    //                 notification.additionalData!['viviendaSolicitada'],
    //               ),
    //             _buildDetailRow(
    //               'Fecha',
    //               '${notification.date} - ${notification.time}',
    //             ),
    //             _buildDetailRow(
    //               'Tipo',
    //               _getNotificationTypeText(notification.notificationType),
    //             ),
    //             const SizedBox(height: 16),
    //             Text(
    //               notification.content,
    //               style: const TextStyle(fontSize: 14),
    //             ),
    //             // Mostrar mensaje del administrador si existe
    //             if (notification.notificationType == 'vivienda_rechazada' &&
    //                 notification.additionalData?['mensajeAdmin'] != null) ...[
    //               const SizedBox(height: 16),
    //               Container(
    //                 padding: const EdgeInsets.all(12),
    //                 decoration: BoxDecoration(
    //                   color: Colors.red.shade50,
    //                   borderRadius: BorderRadius.circular(8),
    //                   border: Border.all(color: Colors.red.shade200),
    //                 ),
    //                 child: Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Row(
    //                       children: [
    //                         Icon(
    //                           Icons.message,
    //                           color: Colors.red.shade600,
    //                           size: 16,
    //                         ),
    //                         const SizedBox(width: 8),
    //                         Text(
    //                           'Mensaje del Administrador:',
    //                           style: TextStyle(
    //                             fontWeight: FontWeight.bold,
    //                             color: Colors.red.shade600,
    //                             fontSize: 14,
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                     const SizedBox(height: 8),
    //                     Text(
    //                       notification.additionalData!['mensajeAdmin'],
    //                       style: const TextStyle(fontSize: 14),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             ],
    //             if (notification.notificationType == 'vivienda_rechazada') ...[
    //               const SizedBox(height: 16),
    //               Container(
    //                 padding: const EdgeInsets.all(12),
    //                 decoration: BoxDecoration(
    //                   color: Colors.orange.shade50,
    //                   borderRadius: BorderRadius.circular(8),
    //                   border: Border.all(color: Colors.orange.shade200),
    //                 ),
    //                 child: GestureDetector(
    //                   onTap: () async {
    //                     Navigator.push(
    //                       context,
    //                       MaterialPageRoute(
    //                         builder: (context) =>
    //                             ResidenteSeleccionViviendaScreen(
    //                               condominioId: widget.condominioId,
    //                               onViviendaSeleccionada: () {
    //                                 _loadResidenteData();
    //                               },
    //                             ),
    //                       ),
    //                     );
    //                   },
    //                   child: Row(
    //                     children: [
    //                       Icon(
    //                         Icons.info_outline,
    //                         color: Colors.orange.shade600,
    //                         size: 20,
    //                       ),
    //                       const SizedBox(width: 8),
    //                       const Expanded(
    //                         child: Text(
    //                           'Puede intentar seleccionar otra vivienda disponible dando click aquí.',
    //                           style: TextStyle(fontSize: 14),
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ],
    //         ),
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: const Text('Cerrar'),
    //         ),
    //       ],
    //     );
    //   },
    // );
 
 }

  void _showEstacionamientoNotificationDialog(NotificationModel notification) {
    final bool isApproved = notification.notificationType.contains('aprobado');
    final bool isVisita = notification.notificationType.contains('visita');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.cancel,
                color: isApproved ? Colors.green.shade600 : Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVisita 
                      ? (isApproved ? 'Estacionamiento de Visitas Aprobado' : 'Estacionamiento de Visitas Rechazado')
                      : (isApproved ? 'Estacionamiento Aprobado' : 'Estacionamiento Rechazado'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.additionalData?['numeroEstacionamiento'] != null)
                  _buildDetailRow(
                    'Estacionamiento',
                    'N° ${notification.additionalData!['numeroEstacionamiento']}',
                  ),
                _buildDetailRow(
                  'Fecha',
                  '${notification.date} - ${notification.time}',
                ),
                _buildDetailRow(
                  'Tipo',
                  isVisita ? 'Estacionamiento de Visitas' : 'Estacionamiento Regular',
                ),
                const SizedBox(height: 16),
                Text(
                  notification.content,
                  style: const TextStyle(fontSize: 14),
                ),
                // Mostrar motivo de rechazo si existe
                if (!isApproved && notification.additionalData?['motivoRechazo'] != null) ...[
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
                              'Motivo del Rechazo:',
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
                          notification.additionalData!['motivoRechazo'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
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

  void _showCorrespondenciaNotificationDialog(NotificationModel notification) {
    final additionalData = notification.additionalData ?? {};
    final tipoCorrespondencia = additionalData['tipoCorrespondencia'] ?? 'N/A';
    final fechaRecepcion = additionalData['fechaHoraRecepcion'] ?? '';
    final viviendaRecepcion = additionalData['viviendaRecepcion'] ?? '';
    final datosEntrega = additionalData['datosEntrega'] ?? '';
    final tipoEntrega = additionalData['tipoEntrega'] ?? '';
    final tieneAdjuntos = additionalData['tieneAdjuntos'] ?? false;
    final adjuntos = additionalData['adjuntos'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Correspondencia Recibida',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Tipo', tipoCorrespondencia),
                        _buildDetailRow('Tipo de entrega', tipoEntrega),
                        _buildDetailRow('Datos de entrega', datosEntrega),
                        if (viviendaRecepcion.isNotEmpty)
                          _buildDetailRow('Vivienda de recepción', viviendaRecepcion),
                        _buildDetailRow('Fecha de recepción', _formatearFechaNotificacion(fechaRecepcion)),
                        _buildDetailRow('Fecha', '${notification.date} - ${notification.time}'),
                        
                        const SizedBox(height: 16),
                        Text(
                          notification.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                        
                        // Mostrar imágenes si existen
                        if (tieneAdjuntos && adjuntos.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Imágenes adjuntas:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildImagenesAdjuntas(adjuntos),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagenesAdjuntas(Map<String, dynamic> adjuntos) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: adjuntos.entries.map((entry) {
        return GestureDetector(
          onTap: () => _mostrarImagenCompleta(entry.value),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(entry.value),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.grey.shade600),
                        const SizedBox(height: 4),
                        Text(
                          'Error al cargar imagen',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _mostrarImagenCompleta(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Imagen de correspondencia'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar la imagen',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMensajeAdicionalNotificationDialog(NotificationModel notification) {
    final additionalData = notification.additionalData ?? {};
    final tipoCorrespondencia = additionalData['tipoCorrespondencia'] ?? 'N/A';
    final mensaje = additionalData['mensaje'] ?? '';
    final fechaRecepcion = additionalData['fechaHoraRecepcion'] ?? '';
    final viviendaRecepcion = additionalData['viviendaRecepcion'] ?? '';
    final datosEntrega = additionalData['datosEntrega'] ?? '';
    final tipoEntrega = additionalData['tipoEntrega'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mensaje Adicional',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Tipo de correspondencia', tipoCorrespondencia),
                        _buildDetailRow('Tipo de entrega', tipoEntrega),
                        _buildDetailRow('Datos de entrega', datosEntrega),
                        if (viviendaRecepcion.isNotEmpty)
                          _buildDetailRow('Vivienda de recepción', viviendaRecepcion),
                        _buildDetailRow('Fecha de recepción', _formatearFechaNotificacion(fechaRecepcion)),
                        _buildDetailRow('Fecha de notificación', '${notification.date} - ${notification.time}'),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Nuevo mensaje:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            mensaje,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // Campo de respuesta
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildCampoRespuestaNotificacion(additionalData['correspondenciaId']),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _respuestaNotificacionController.dispose();
    super.dispose();
  }

  Widget _buildCampoRespuestaNotificacion(String? correspondenciaId) {
    if (correspondenciaId == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responder:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _respuestaNotificacionController,
          decoration: const InputDecoration(
            hintText: 'Escribe tu respuesta aquí...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _enviarRespuestaNotificacion(correspondenciaId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _enviarRespuestaNotificacion(String correspondenciaId) async {
    if (_respuestaNotificacionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe una respuesta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final nuevoMensaje = {
        'mensaje': _respuestaNotificacionController.text.trim(),
        'fechaHora': DateTime.now().toIso8601String(),
        'usuarioId': user.uid,
      };

      // Obtener la correspondencia actual
      final correspondenciaDoc = await FirebaseFirestore.instance
          .collection(widget.condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .get();

      if (!correspondenciaDoc.exists) {
        throw Exception('Correspondencia no encontrada');
      }

      final correspondenciaData = correspondenciaDoc.data()!;
      List<dynamic> mensajesExistentes = correspondenciaData['infAdicional'] ?? [];
      mensajesExistentes.add(nuevoMensaje);

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection(widget.condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .update({
        'infAdicional': mensajesExistentes,
      });

      // Limpiar el campo de texto
      _respuestaNotificacionController.clear();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta enviada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Cerrar el modal
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar respuesta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatearFechaNotificacion(String fechaHora) {
    try {
      final fecha = DateTime.parse(fechaHora);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaHora;
    }
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
}
