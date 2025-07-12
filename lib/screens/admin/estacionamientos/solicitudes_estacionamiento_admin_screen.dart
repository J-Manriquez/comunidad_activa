import 'package:flutter/material.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/estacionamiento_model.dart';

class SolicitudesEstacionamientoAdminScreen extends StatefulWidget {
  final String condominioId;

  const SolicitudesEstacionamientoAdminScreen({
    Key? key,
    required this.condominioId,
  }) : super(key: key);

  @override
  State<SolicitudesEstacionamientoAdminScreen> createState() => _SolicitudesEstacionamientoAdminScreenState();
}

class _SolicitudesEstacionamientoAdminScreenState extends State<SolicitudesEstacionamientoAdminScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final NotificationService _notificationService = NotificationService();
  
  List<EstacionamientoModel> _solicitudesPendientes = [];
  bool _isLoading = true;
  String? _error;
  Set<String> _processingSolicitudes = {};

  @override
  void initState() {
    super.initState();
    print('🟡 [SOLICITUDES_ADMIN] Iniciando pantalla de solicitudes de estacionamiento');
    _cargarSolicitudesPendientes();
  }

  Future<void> _cargarSolicitudesPendientes() async {
    try {
      print('🟡 [SOLICITUDES_ADMIN] Iniciando carga de solicitudes');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🟡 [SOLICITUDES_ADMIN] Obteniendo lista de estacionamientos del condominio: ${widget.condominioId}');
      
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(widget.condominioId);
      
      print('🟡 [SOLICITUDES_ADMIN] Total estacionamientos encontrados: ${estacionamientos.length}');
      
      // Filtrar solo los que tienen solicitudes pendientes y NO son estacionamientos de visitas
      final solicitudesPendientes = estacionamientos
          .where((est) => est.estadoSolicitud == 'pendiente' && est.estVisita == false)
          .toList();
      
      print('🟢 [SOLICITUDES_ADMIN] Solicitudes pendientes encontradas: ${solicitudesPendientes.length}');
      for (final solicitud in solicitudesPendientes) {
        print('   - N°${solicitud.nroEstacionamiento}: ${solicitud.nombreSolicitante} (${solicitud.viviendaSolicitante})');
      }
      
      if (mounted) {
        setState(() {
          _solicitudesPendientes = solicitudesPendientes;
          _isLoading = false;
        });
        print('🟢 [SOLICITUDES_ADMIN] Solicitudes cargadas exitosamente');
      }
    } catch (e) {
      print('🔴 [SOLICITUDES_ADMIN] Error al cargar solicitudes: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _aprobarSolicitud(EstacionamientoModel estacionamiento) async {
    try {
      print('🟡 [SOLICITUDES_ADMIN] Iniciando aprobación de solicitud');
      print('🟡 [SOLICITUDES_ADMIN] Datos de aprobación:');
      print('   - Estacionamiento ID: ${estacionamiento.id}');
      print('   - Número estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('   - Solicitante: ${estacionamiento.nombreSolicitante}');
      print('   - Vivienda: ${estacionamiento.viviendaSolicitante}');
      print('   - Solicitante ID: ${estacionamiento.idSolicitante?.first}');
      
      setState(() {
        _processingSolicitudes.add(estacionamiento.id);
      });

      // Actualizar el estacionamiento asignándolo al residente
      print('🟡 [SOLICITUDES_ADMIN] Actualizando estacionamiento con datos del residente');
      await _estacionamientoService.actualizarEstacionamiento(
        widget.condominioId,
        estacionamiento.id,
        {
          'viviendaAsignada': estacionamiento.viviendaSolicitante,
          'residenteAsignado': estacionamiento.nombreSolicitante,
          'residenteId': estacionamiento.idSolicitante?.first,
          'fechaAsignacion': DateTime.now(),
          'estadoSolicitud': 'aprobada',
          'idSolicitante': null,
          'nombreSolicitante': null,
          'viviendaSolicitante': null,
          'fechaSolicitud': null,
        },
      );
      print('🟢 [SOLICITUDES_ADMIN] Estacionamiento actualizado exitosamente');

      // Enviar notificación al residente
      print('🟡 [SOLICITUDES_ADMIN] Enviando notificación de aprobación al residente');
      await _notificationService.createUserNotification(
        condominioId: widget.condominioId,
        userId: estacionamiento.idSolicitante!.first,
        userType: 'residentes',
        tipoNotificacion: 'estacionamiento_aprobado',
        contenido: 'Su solicitud del estacionamiento N° ${estacionamiento.nroEstacionamiento} ha sido aprobada.',
        additionalData: {
          'estacionamientoId': estacionamiento.id,
          'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
          'fechaAprobacion': DateTime.now().toIso8601String(),
        },
      );
      print('🟢 [SOLICITUDES_ADMIN] Notificación de aprobación enviada');

      print('🟢 [SOLICITUDES_ADMIN] Solicitud aprobada exitosamente');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud aprobada para ${estacionamiento.nombreSolicitante!.first}'),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar las solicitudes
      print('🟡 [SOLICITUDES_ADMIN] Recargando lista de solicitudes');
      await _cargarSolicitudesPendientes();
    } catch (e) {
      print('🔴 [SOLICITUDES_ADMIN] Error al aprobar solicitud: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingSolicitudes.remove(estacionamiento.id);
        });
      }
    }
  }

  void _mostrarModalRechazo(EstacionamientoModel estacionamiento) {
    final TextEditingController mensajeController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rechazar Solicitud'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estacionamiento N° ${estacionamiento.nroEstacionamiento}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Solicitante: ${estacionamiento.nombreSolicitante!.first}'),
                  Text('Vivienda: ${estacionamiento.viviendaSolicitante!.first}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: mensajeController,
                    enabled: !isProcessing,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del rechazo (opcional)',
                      hintText: 'Ingrese el motivo del rechazo...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Procesando rechazo...'),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() {
                            isProcessing = true;
                          });
                          
                          try {
                            await _rechazarSolicitud(
                              estacionamiento,
                              mensajeController.text.trim(),
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al rechazar solicitud: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Rechazar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rechazarSolicitud(EstacionamientoModel estacionamiento, String motivo) async {
    try {
      print('🟡 [SOLICITUDES_ADMIN] Iniciando rechazo de solicitud');
      print('🟡 [SOLICITUDES_ADMIN] Datos de rechazo:');
      print('   - Estacionamiento ID: ${estacionamiento.id}');
      print('   - Número estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('   - Solicitante: ${estacionamiento.nombreSolicitante}');
      print('   - Vivienda: ${estacionamiento.viviendaSolicitante}');
      print('   - Solicitante ID: ${estacionamiento.idSolicitante?.first}');
      print('   - Motivo rechazo: ${motivo.isNotEmpty ? motivo : "Sin motivo especificado"}');
      
      setState(() {
        _processingSolicitudes.add(estacionamiento.id);
      });

      // Actualizar el estacionamiento rechazando la solicitud
      print('🟡 [SOLICITUDES_ADMIN] Actualizando estado del estacionamiento a "rechazada"');
      await _estacionamientoService.actualizarEstacionamiento(
        widget.condominioId,
        estacionamiento.id,
        {
          'estadoSolicitud': 'rechazada',
          'respuestaSolicitud': motivo.isNotEmpty ? motivo : 'Solicitud rechazada por el administrador',
          'fechaRechazo': DateTime.now().toIso8601String(),
          // Limpiar datos de solicitud y vivienda asignada
          'viviendaAsignada': null,
          'idSolicitante': null,
          'nombreSolicitante': null,
          'viviendaSolicitante': null,
          'fechaHoraSolicitud': null,
        },
      );
      print('🟢 [SOLICITUDES_ADMIN] Estado del estacionamiento actualizado');

      // Enviar notificación al residente
      print('🟡 [SOLICITUDES_ADMIN] Preparando datos de notificación');
      final Map<String, dynamic> notificationData = {
        'estacionamientoId': estacionamiento.id,
        'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
        'fechaRechazo': DateTime.now().toIso8601String(),
      };

      if (motivo.isNotEmpty) {
        notificationData['motivoRechazo'] = motivo;
      }

      print('🟡 [SOLICITUDES_ADMIN] Enviando notificación de rechazo al residente');
      await _notificationService.createUserNotification(
        condominioId: widget.condominioId,
        userId: estacionamiento.idSolicitante!.first,
        userType: 'residentes',
        tipoNotificacion: 'estacionamiento_rechazado',
        contenido: motivo.isNotEmpty
            ? 'Su solicitud del estacionamiento N° ${estacionamiento.nroEstacionamiento} ha sido rechazada. Motivo: $motivo'
            : 'Su solicitud del estacionamiento N° ${estacionamiento.nroEstacionamiento} ha sido rechazada.',
        additionalData: notificationData,
      );
      print('🟢 [SOLICITUDES_ADMIN] Notificación de rechazo enviada');

      print('🟢 [SOLICITUDES_ADMIN] Solicitud rechazada exitosamente');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud rechazada para ${estacionamiento.nombreSolicitante!.first}'),
          backgroundColor: Colors.orange,
        ),
      );

      // Recargar solicitudes
      print('🟡 [SOLICITUDES_ADMIN] Recargando lista de solicitudes');
      await _cargarSolicitudesPendientes();
    } catch (e) {
      print('🔴 [SOLICITUDES_ADMIN] Error al rechazar solicitud: $e');
      throw e;
    } finally {
      if (mounted) {
        setState(() {
          _processingSolicitudes.remove(estacionamiento.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Estacionamiento'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudesPendientes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando solicitudes pendientes...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar solicitudes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarSolicitudesPendientes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_solicitudesPendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay solicitudes pendientes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Todas las solicitudes han sido procesadas.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudesPendientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _solicitudesPendientes.length,
        itemBuilder: (context, index) {
          final solicitud = _solicitudesPendientes[index];
          return _buildSolicitudCard(solicitud);
        },
      ),
    );
  }

  Widget _buildSolicitudCard(EstacionamientoModel solicitud) {
    final isProcessing = _processingSolicitudes.contains(solicitud.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Estacionamiento N° ${solicitud.nroEstacionamiento}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Solicitante: ${solicitud.nombreSolicitante!.first}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.home, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Vivienda: ${solicitud.viviendaSolicitante!.first}'),
              ],
            ),
            if (solicitud.fechaHoraSolicitud != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Solicitado: ${_formatearFecha(solicitud.fechaHoraSolicitud!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (isProcessing)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Procesando...'),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprobarSolicitud(solicitud),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarModalRechazo(solicitud),
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

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaIso;
    }
  }
}