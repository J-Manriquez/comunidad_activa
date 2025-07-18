import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificacionConfirmacionEntrega extends StatefulWidget {
  final String condominioId;
  final String residenteId;
  final NotificationModel notificacion;
  final VoidCallback? onRespuesta;

  const NotificacionConfirmacionEntrega({
    super.key,
    required this.condominioId,
    required this.residenteId,
    required this.notificacion,
    this.onRespuesta,
  });

  @override
  State<NotificacionConfirmacionEntrega> createState() => _NotificacionConfirmacionEntregaState();
}

class _NotificacionConfirmacionEntregaState extends State<NotificacionConfirmacionEntrega> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final estado = widget.notificacion.additionalData?['estado'] ?? 'pendiente';
    final tipoCorrespondencia =
        widget.notificacion.additionalData?['tipoCorrespondencia'] ??
            'correspondencia';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(estado),
                    color: _getStatusColor(estado),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmación de Entrega',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        tipoCorrespondencia,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(estado),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenido
            Text(
              widget.notificacion.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.notificacion.date} - ${widget.notificacion.time}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mensaje de estado o botones de acción
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
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _responderConfirmacion(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade600),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _responderConfirmacion(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: estado == 'aceptada'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: estado == 'aceptada'
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      estado == 'aceptada' ? Icons.check_circle : Icons.cancel,
                      color: estado == 'aceptada'
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estado == 'aceptada'
                          ? 'Entrega confirmada'
                          : 'Entrega rechazada',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: estado == 'aceptada'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _responderConfirmacion(bool aceptada) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Actualizar el estado en la notificación usando la estructura estándar
      await _notificationService.updateNotificationStatus(
        condominioId: widget.condominioId,
        notificationId: widget.notificacion.id,
        newStatus: aceptada ? 'aceptada' : 'rechazada',
        userId: widget.residenteId,
        userType: 'residentes',
      );
      
      // También actualizar el additionalData para reflejar el nuevo estado
      await _firestore
          .collection(widget.condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(widget.residenteId)
          .collection('notificaciones')
          .doc(widget.notificacion.id)
          .update({
        'additionalData.estado': aceptada ? 'aceptada' : 'rechazada',
        'additionalData.fechaRespuesta': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aceptada
                  ? 'Entrega confirmada exitosamente'
                  : 'Entrega rechazada',
            ),
            backgroundColor:
                aceptada ? Colors.green.shade600 : Colors.red.shade600,
          ),
        );

        // Llamar callback si existe
        widget.onRespuesta?.call();
      }
    } catch (e) {
      setState(() {
        _error = 'Error al procesar respuesta: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'aceptada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'pendiente':
      default:
        return Icons.local_shipping;
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.green.shade600;
      case 'rechazada':
        return Colors.red.shade600;
      case 'pendiente':
      default:
        return Colors.orange.shade600;
    }
  }

  String _getStatusText(String estado) {
    switch (estado) {
      case 'aceptada':
        return 'Confirmada';
      case 'rechazada':
        return 'Rechazada';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }
}