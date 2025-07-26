import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/residente_model.dart';
import '../../models/correspondencia_config_model.dart';
import '../../services/correspondencia_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/modal_entrega_correspondencia.dart';

class CorrespondenciasResidenteScreen extends StatefulWidget {
  final String condominioId;

  const CorrespondenciasResidenteScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<CorrespondenciasResidenteScreen> createState() => _CorrespondenciasResidenteScreenState();
}

class _CorrespondenciasResidenteScreenState extends State<CorrespondenciasResidenteScreen> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  ResidenteModel? _residente;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadResidenteData();
  }
  
  Future<void> _loadResidenteData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        setState(() {
          _residente = residente;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos del residente: $e';
        _isLoading = false;
      });
    }
  }
  
  String _getViviendaResidente() {
    if (_residente == null) return '';
    
    // Construir la descripción de la vivienda similar a como se hace en el modelo
    String descripcion = '';
    
    if (_residente!.tipoVivienda?.isNotEmpty == true) {
      descripcion += _residente!.tipoVivienda!;
    }
    
    if (_residente!.numeroVivienda?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ' ';
      descripcion += _residente!.numeroVivienda!;
    }
    
    if (_residente!.etiquetaEdificio?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ', ';
      descripcion += _residente!.etiquetaEdificio!;
    }
    
    if (_residente!.numeroDepartamento?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ' ';
      descripcion += _residente!.numeroDepartamento!;
    }
    
    return descripcion;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Correspondencias'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadResidenteData();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _residente == null
                  ? const Center(
                      child: Text('No se encontraron datos del residente'),
                    )
                  : _buildCorrespondenciasList(),
    );
  }
  
  Widget _buildCorrespondenciasList() {
    final viviendaResidente = _getViviendaResidente();
    
    if (viviendaResidente.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se pudo determinar la vivienda del residente',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Sección de notificaciones de entrega pendientes
        _buildNotificacionesEntrega(),
        // Sección de correspondencias
        Expanded(child: _buildCorrespondenciasStream(viviendaResidente)),
      ],
    );
  }
  
  Widget _buildNotificacionesEntrega() {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox.shrink();
    
    return FutureBuilder(
      future: _notificationService.getNotificationsForUser(
        user.uid,
        widget.condominioId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al obtener notificaciones de entrega: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          );
        }
        
        final notifications = snapshot.data ?? [];
        final pendingNotifications = notifications.where(
          (n) => n.isRead == null
        ).toList();
        
        if (pendingNotifications.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmaciones de Entrega Pendientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...pendingNotifications.map((notification) => 
                _buildNotificationCard(notification)
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNotificationCard(dynamic notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarEntrega(notification, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarEntrega(notification, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmarEntrega(dynamic notification, bool aceptada) async {
    try {
      await _notificationService.markNotificationAsRead(
        condominioId: widget.condominioId,
        notificationId: notification.id,
        userId: _residente!.uid,
        userType: 'residentes',
      );
      
      // Actualizar el estado de la notificación
      await _notificationService.updateNotificationStatus(
        condominioId: widget.condominioId,
        notificationId: notification.id,
        newStatus: aceptada ? 'aceptada' : 'rechazada',
        userId: _residente!.uid,
        userType: 'residentes',
      );
      
      // Mostrar mensaje de confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aceptada 
                ? 'Entrega confirmada exitosamente'
                : 'Entrega rechazada',
            ),
            backgroundColor: aceptada ? Colors.green : Colors.orange,
          ),
        );
        
        // Refrescar la pantalla
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la confirmación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildCorrespondenciasStream(String viviendaResidente) {
     return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('condominios')
          .doc(widget.condominioId)
          .collection('correspondencias')
          .where('fechaHoraEntrega', isNull: true) // Solo correspondencias activas
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar correspondencias: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay correspondencias activas',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        // Filtrar correspondencias que pertenecen a la vivienda del residente
        final correspondenciasResidente = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final datosEntrega = data['datosEntrega'] as String? ?? '';
          final viviendaRecepcion = data['viviendaRecepcion'] as String? ?? '';
          
          // Verificar si la correspondencia pertenece a la vivienda del residente
          return datosEntrega.contains(viviendaResidente) || 
                 viviendaRecepcion.contains(viviendaResidente);
        }).toList();
        
        // Ordenar por fecha de recepción (más recientes primero)
        correspondenciasResidente.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final fechaA = dataA['fechaHoraRecepcion'] as Timestamp?;
          final fechaB = dataB['fechaHoraRecepcion'] as Timestamp?;
          
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          
          return fechaB.compareTo(fechaA); // Orden descendente
        });
        
        if (correspondenciasResidente.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay correspondencias para tu vivienda',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: correspondenciasResidente.length,
          itemBuilder: (context, index) {
            final doc = correspondenciasResidente[index];
            final correspondencia = CorrespondenciaModel.fromFirestore(doc);
            
            return _buildCorrespondenciaCard(correspondencia);
          },
        );
      },
    );
  }
  
  Widget _buildCorrespondenciaCard(CorrespondenciaModel correspondencia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCorrespondenciaIcon(correspondencia.tipoCorrespondencia),
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correspondencia.tipoCorrespondencia,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        correspondencia.tipoEntrega,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pendiente',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Destinatario:', correspondencia.datosEntrega),
            if (correspondencia.viviendaRecepcion != null)
              _buildInfoRow('Recepción:', correspondencia.viviendaRecepcion!),
            _buildInfoRow(
              'Fecha de recepción:',
              _formatDateTime(correspondencia.fechaHoraRecepcion),
            ),
            // Observaciones no están disponibles en el modelo actual
            
            // Mostrar mensajes adicionales si existen
            if (correspondencia.infAdicional?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Mensajes adicionales:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...correspondencia.infAdicional!.map((mensaje) {
                final mensajeTexto = mensaje['mensaje'] as String? ?? '';
                final timestamp = mensaje['timestamp'] as Timestamp?;
                final fechaFormateada = timestamp != null 
                    ? _formatDateTime(timestamp)
                    : 'Fecha no disponible';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensajeTexto,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fechaFormateada,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCorrespondenciaIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'carta':
        return Icons.mail;
      case 'paquete':
        return Icons.inventory_2;
      case 'documento':
        return Icons.description;
      case 'sobre':
        return Icons.mail_outline;
      default:
        return Icons.mail;
    }
  }
  
  String _formatDateTime(dynamic dateTime) {
    DateTime parsedDate;
    
    if (dateTime is Timestamp) {
      parsedDate = dateTime.toDate();
    } else if (dateTime is String) {
      try {
        parsedDate = DateTime.parse(dateTime);
      } catch (e) {
        return dateTime; // Return original string if parsing fails
      }
    } else {
      return 'Fecha no disponible';
    }
    
    return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
  }
}