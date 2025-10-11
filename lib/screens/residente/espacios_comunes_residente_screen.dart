import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/reserva_model.dart';
import '../../services/espacios_comunes_service.dart';
import '../../widgets/image_carousel_widget.dart';
import '../../utils/image_fullscreen_helper.dart';
import 'solicitar_espacio_screen.dart';
import 'revisiones_espacios_residente_screen.dart';

class EspaciosComunesResidenteScreen extends StatefulWidget {
  final UserModel currentUser;

  const EspaciosComunesResidenteScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<EspaciosComunesResidenteScreen> createState() =>
      _EspaciosComunesResidenteScreenState();
}

class _EspaciosComunesResidenteScreenState
    extends State<EspaciosComunesResidenteScreen> {
  final EspaciosComunesService _espaciosComunesService =
      EspaciosComunesService();
  List<ReservaModel> _misSolicitudes = [];
  bool _isLoading = true;
  int _costoTotalEspacios = 0;

  @override
  void initState() {
    super.initState();
    _cargarMisSolicitudes();
  }

  Future<void> _calcularCostoTotal() async {
    try {
      int costoTotal = 0;
      
      // Obtener todas las reservas aprobadas del usuario
      final reservasAprobadas = _misSolicitudes.where((reserva) => 
        reserva.estado == 'aprobada'
      ).toList();
      
      for (final reserva in reservasAprobadas) {
        // Obtener datos del espacio común para verificar si tiene precio
        final espacioComun = await _espaciosComunesService.obtenerEspacioComunPorId(
          widget.currentUser.condominioId!,
          reserva.espacioId ?? '',
        );
        
        if (espacioComun != null && espacioComun.precio != null) {
          costoTotal += espacioComun.precio!;
        }
        
        // Sumar costos de revisiones si existen
        if (reserva.revisionesUso != null) {
          for (final revision in reserva.revisionesUso!) {
            costoTotal += revision.costo ?? 0;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _costoTotalEspacios = costoTotal;
        });
      }
    } catch (e) {
       print('Error al calcular costo total: $e');
     }
   }

   void _mostrarDetallesCostos() {
     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Text('Detalle de Costos'),
           content: SizedBox(
             width: double.maxFinite,
             child: FutureBuilder<List<Map<String, dynamic>>>(
               future: _obtenerDetallesCostos(),
               builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Text('No hay costos registrados');
                 }
                 
                 final detalles = snapshot.data!;
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Flexible(
                       child: ListView.builder(
                         shrinkWrap: true,
                         itemCount: detalles.length,
                         itemBuilder: (context, index) {
                           final detalle = detalles[index];
                           return Card(
                             child: Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     detalle['nombreEspacio'],
                                     style: const TextStyle(
                                       fontWeight: FontWeight.bold,
                                       fontSize: 16,
                                     ),
                                   ),
                                   const SizedBox(height: 4),
                                   Text('Fecha: ${detalle['fecha']}'),
                                   if (detalle['costoEspacio'] > 0) ...[
                                     Text('Costo del espacio: \$${detalle['costoEspacio'].toString().replaceAllMapped(
                                       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                       (Match m) => '${m[1]}.',
                                     )}'),
                                   ],
                                   if (detalle['revisiones'].isNotEmpty) ...[
                                     const SizedBox(height: 8),
                                     const Text(
                                       'Revisiones:',
                                       style: TextStyle(fontWeight: FontWeight.w600),
                                     ),
                                     ...detalle['revisiones'].map<Widget>((revision) => 
                                       Padding(
                                         padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                                         child: Text(
                                           '• ${revision['tipo']}: \$${revision['costo'].toString().replaceAllMapped(
                                             RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                             (Match m) => '${m[1]}.',
                                           )}',
                                         ),
                                       ),
                                     ).toList(),
                                   ],
                                   const SizedBox(height: 8),
                                   Text(
                                     'Total: \$${detalle['total'].toString().replaceAllMapped(
                                       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                       (Match m) => '${m[1]}.',
                                     )}',
                                     style: const TextStyle(
                                       fontWeight: FontWeight.bold,
                                       color: Colors.green,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                     const SizedBox(height: 16),
                     Text(
                       'Total General: \$${_costoTotalEspacios.toString().replaceAllMapped(
                         RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                         (Match m) => '${m[1]}.',
                       )}',
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Colors.green,
                       ),
                     ),
                   ],
                 );
               },
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

  Future<List<Map<String, dynamic>>> _obtenerDetallesCostos() async {
    List<Map<String, dynamic>> detalles = [];
    
    try {
      // Obtener todas las reservas aprobadas del usuario
      final reservasAprobadas = _misSolicitudes.where((reserva) => 
        reserva.estado == 'aprobada'
      ).toList();
      
      for (final reserva in reservasAprobadas) {
        int costoEspacio = 0;
        String nombreEspacio = 'Espacio desconocido';
        
        // Obtener datos del espacio común
        final espacioComun = await _espaciosComunesService.obtenerEspacioComunPorId(
          widget.currentUser.condominioId!,
          reserva.espacioId ?? '',
        );
        
        if (espacioComun != null) {
          nombreEspacio = espacioComun.nombre;
          costoEspacio = espacioComun.precio ?? 0;
        }
        
        // Obtener costos de revisiones
        List<Map<String, dynamic>> revisiones = [];
        int costoRevisiones = 0;
        
        if (reserva.revisionesUso != null) {
          for (final revision in reserva.revisionesUso!) {
            if (revision.costo != null && revision.costo! > 0) {
              revisiones.add({
                'tipo': revision.tipoRevision == 'pre' ? 'Pre-uso' : 'Post-uso',
                'costo': revision.costo!,
              });
              costoRevisiones += revision.costo!;
            }
          }
        }
        
        // Solo agregar si hay algún costo
        if (costoEspacio > 0 || costoRevisiones > 0) {
          detalles.add({
            'nombreEspacio': nombreEspacio,
            'fecha': reserva.fechaUso?.toString().split(' ')[0] ?? 'Sin fecha',
            'costoEspacio': costoEspacio,
            'revisiones': revisiones,
            'total': costoEspacio + costoRevisiones,
          });
        }
      }
    } catch (e) {
      print('Error al obtener detalles de costos: $e');
    }
    
    return detalles;
  }

  Future<void> _cargarMisSolicitudes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final solicitudes = await _espaciosComunesService
          .obtenerReservasPorResidente(
              widget.currentUser.condominioId!, widget.currentUser.uid!);

      setState(() {
        _misSolicitudes = solicitudes;
        _isLoading = false;
      });
      // Calcular costo total después de cargar las solicitudes
      await _calcularCostoTotal();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar solicitudes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios Comunes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarMisSolicitudes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenedor de costo total
              Card(
                elevation: 4,
                color: Colors.green[50],
                child: InkWell(
                  onTap: () {
                    _mostrarDetallesCostos();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 40,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Espacios Comunes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_costoTotalEspacios.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]}.',
                                )}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card para solicitar espacio
              Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolicitarEspacioScreen(
                          currentUser: widget.currentUser,
                        ),
                      ),
                    ).then((_) => _cargarMisSolicitudes());
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_business,
                          size: 40,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solicitar Espacio Común',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Reserva un espacio común para tu uso',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card para revisiones
              Card(
                elevation: 4,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RevisionesEspaciosResidenteScreen(
                          currentUser: widget.currentUser,
                        ),
                      ),
                    );
                    // Actualizar la lista cuando regrese
                    _cargarMisSolicitudes();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rate_review,
                          size: 40,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revisiones de Espacios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ver revisiones de espacios utilizados',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lista de solicitudes
              const Text(
                'Mis Solicitudes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_misSolicitudes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No tienes solicitudes de espacios comunes',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _misSolicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = _misSolicitudes[index];
                    return _buildSolicitudCard(solicitud);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(ReservaModel solicitud) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (solicitud.estado.toLowerCase()) {
      case 'aprobada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprobada';
        break;
      case 'rechazado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazada';
        break;
      case 'pendiente':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendiente';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagen del espacio - Lado izquierdo
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _obtenerImagenesEspacioComun(solicitud.espacioId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ImageCarouselWidget(
                      images: snapshot.data!,
                      onImageTap: (imageData) {
                        ImageFullscreenHelper.showFullscreenImage(
                          context,
                          imageData,
                        );
                      },
                    );
                  }
                  
                  // Si no hay imágenes, mostrar placeholder
                  return const Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.grey,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Información del espacio - Lado derecho
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          solicitud.nombreEspacio!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fecha: ${solicitud.fechaUso!.day}/${solicitud.fechaUso!.month}/${solicitud.fechaUso!.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hora: ${solicitud.horaInicio} - ${solicitud.horaFin}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Solicitado: ${solicitud.fechaSolicitud!.day}/${solicitud.fechaSolicitud!.month}/${solicitud.fechaSolicitud!.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener las imágenes del espacio común
  Future<List<Map<String, dynamic>>> _obtenerImagenesEspacioComun(String espacioId) async {
    try {
      final espacioComun = await EspaciosComunesService().obtenerEspacioComunPorId(
        widget.currentUser.condominioId!,
        espacioId,
      );
      
      // Recopilar todas las imágenes disponibles
      List<Map<String, dynamic>> images = [];
      
      if (espacioComun?.additionalData != null) {
        // Buscar imagen1Data, imagen2Data y imagen3Data
        for (int i = 1; i <= 3; i++) {
          final imageKey = 'imagen${i}Data';
          if (espacioComun!.additionalData![imageKey] != null) {
            Map<String, dynamic> imageData = espacioComun.additionalData![imageKey];
            
            // Debug: Imprimir la estructura de imageData
            print('DEBUG - $imageKey structure: $imageData');
            print('DEBUG - $imageKey type: ${imageData['type']}');
            print('DEBUG - $imageKey keys: ${imageData.keys.toList()}');
            
            // Validar y corregir la estructura de imageData si es necesario
            Map<String, dynamic> validImageData = _validateImageData(imageData);
            images.add(validImageData);
          }
        }
      }
      
      return images;
    } catch (e) {
      print('Error al obtener imágenes del espacio común: $e');
      return [];
    }
  }

  /// Valida y corrige la estructura de imageData si es necesario
  Map<String, dynamic> _validateImageData(Map<String, dynamic> imageData) {
    // Debug: Imprimir información detallada
    print('DEBUG - Validating imageData: $imageData');
    
    // Verificar si tiene el campo 'type'
    if (!imageData.containsKey('type')) {
      print('DEBUG - Missing type field, attempting to infer...');
      
      // Intentar inferir el tipo basado en la estructura
      if (imageData.containsKey('data') && imageData['data'] is String) {
        print('DEBUG - Found data field with String, assuming normal type');
        return {
          'type': 'normal',
          'data': imageData['data'],
        };
      } else if (imageData.containsKey('fragments') && imageData['fragments'] is List) {
        print('DEBUG - Found fragments field, assuming internal_fragmented type');
        return {
          'type': 'internal_fragmented',
          'fragments': imageData['fragments'],
          'total_fragments': imageData['total_fragments'] ?? (imageData['fragments'] as List).length,
          'original_type': imageData['original_type'] ?? 'jpeg',
        };
      } else if (imageData.containsKey('fragment_id')) {
        print('DEBUG - Found fragment_id field, assuming external_fragmented type');
        return {
          'type': 'external_fragmented',
          'fragment_id': imageData['fragment_id'],
          'total_fragments': imageData['total_fragments'] ?? 1,
          'original_type': imageData['original_type'] ?? 'jpeg',
        };
      } else {
        print('DEBUG - Cannot infer type, defaulting to normal with error handling');
        return {
          'type': 'normal',
          'data': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=', // Imagen placeholder muy pequeña
        };
      }
    }
    
    // Si ya tiene type, verificar que sea válido
    final type = imageData['type'] as String?;
    if (type == null || !['normal', 'internal_fragmented', 'external_fragmented'].contains(type)) {
      print('DEBUG - Invalid type: $type, defaulting to normal');
      return {
        'type': 'normal',
        'data': imageData['data'] ?? 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=',
      };
    }
    
    print('DEBUG - imageData is valid with type: $type');
    return imageData;
  }
}