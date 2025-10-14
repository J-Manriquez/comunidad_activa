import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/visita_bloqueada_model.dart';
import '../../services/bloqueo_visitas_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/image_carousel_widget.dart';
import '../../utils/image_fullscreen_helper.dart';

class VisitasBloqueadasResidenteScreen extends StatefulWidget {
  final UserModel currentUser;
  final String? visitaIdToOpen;

  const VisitasBloqueadasResidenteScreen({
    Key? key,
    required this.currentUser,
    this.visitaIdToOpen,
  }) : super(key: key);

  @override
  State<VisitasBloqueadasResidenteScreen> createState() => _VisitasBloqueadasResidenteScreenState();
}

class _VisitasBloqueadasResidenteScreenState extends State<VisitasBloqueadasResidenteScreen> {
  final BloqueoVisitasService _bloqueoVisitasService = BloqueoVisitasService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _descripcionVivienda;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _obtenerDescripcionVivienda();
  }

  Future<void> _obtenerDescripcionVivienda() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Buscar el residente actual por UID
      final residenteActual = await _firestoreService.getResidenteData(widget.currentUser.uid);

      if (residenteActual != null) {
        // Construir la descripción de la vivienda
        String descripcion = '';
        
        if (residenteActual.descripcionVivienda != null && 
            residenteActual.descripcionVivienda!.isNotEmpty) {
          descripcion = residenteActual.descripcionVivienda!;
        } else {
          // Construir desde los campos individuales
          final tipoVivienda = residenteActual.tipoVivienda ?? '';
          final numeroVivienda = residenteActual.numeroVivienda ?? '';
          final etiquetaEdificio = residenteActual.etiquetaEdificio ?? '';
          final numeroDepartamento = residenteActual.numeroDepartamento ?? '';

          if (tipoVivienda.toLowerCase() == 'casa') {
            descripcion = 'Casa $numeroVivienda';
          } else if (tipoVivienda.toLowerCase() == 'departamento') {
            if (etiquetaEdificio.isNotEmpty && numeroDepartamento.isNotEmpty) {
              descripcion = 'Departamento $etiquetaEdificio-$numeroDepartamento';
            } else if (numeroVivienda.isNotEmpty) {
              descripcion = 'Departamento $numeroVivienda';
            }
          }
        }

        setState(() {
          _descripcionVivienda = descripcion;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al obtener descripción de vivienda: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas Bloqueadas'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _descripcionVivienda == null || _descripcionVivienda!.isEmpty
              ? const Center(
                  child: Text(
                    'No se pudo obtener la información de la vivienda',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : FutureBuilder<List<VisitaBloqueadaModel>>(
                  future: _bloqueoVisitasService.obtenerVisitasBloqueadasPorVivienda(
                    condominioId: widget.currentUser.condominioId!,
                    descripcionVivienda: _descripcionVivienda!,
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

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay visitas bloqueadas para tu vivienda',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final visitasBloqueadas = snapshot.data!;

                    // Auto-abrir modal si se especifica visitaIdToOpen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.visitaIdToOpen != null) {
                        final visitaToOpen = visitasBloqueadas.firstWhere(
                          (visita) => visita.id == widget.visitaIdToOpen,
                          orElse: () => visitasBloqueadas.first,
                        );
                        _mostrarDetallesModal(visitaToOpen);
                      }
                    });

                    return Column(
                      children: [
                        // Header con información de la vivienda
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.red.shade50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vivienda: $_descripcionVivienda',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${visitasBloqueadas.length} visita(s) bloqueada(s)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista de visitas bloqueadas
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: visitasBloqueadas.length,
                            itemBuilder: (context, index) {
                              return _buildVisitaCard(visitasBloqueadas[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildVisitaCard(VisitaBloqueadaModel visita) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesModal(visita),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen del visitante - Lado izquierdo
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: _buildImageCarousel(visita),
              ),
              const SizedBox(width: 12),
              // Información del visitante - Lado derecho
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con nombre y estado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visita.nombreVisitante,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildEstadoChip(visita.estado),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Información básica
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'RUT: ${visita.rutVisitante}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Fecha: ${visita.fechaBloqueoFormateada}',
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
                        const Icon(Icons.description, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Motivo: ${visita.motivoBloqueo}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
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
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color backgroundColor;
    Color textColor;
    String texto;

    switch (estado.toLowerCase()) {
      case 'activo':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        texto = 'Activo';
        break;
      case 'expirado':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        texto = 'Expirado';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        texto = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageCarousel(VisitaBloqueadaModel visita) {
    final imagenes = _obtenerImagenesVisitaBloqueada(visita);
    
    if (imagenes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Sin imágenes', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: ImageCarouselWidget(
          images: imagenes,
          height: 150,
          borderRadius: BorderRadius.circular(8.0),
          onImageTap: (imageData) {
            ImageFullscreenHelper.showFullscreenImage(context, imageData);
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _obtenerImagenesVisitaBloqueada(VisitaBloqueadaModel visita) {
    List<Map<String, dynamic>> imagenes = [];
    
    if (visita.additionalData != null) {
      // Buscar imágenes en additionalData con las claves imagen1, imagen2, imagen3
      for (int i = 1; i <= 3; i++) {
        final imagenKey = 'imagen$i';
        if (visita.additionalData!.containsKey(imagenKey)) {
          final imagenData = visita.additionalData![imagenKey];
          if (imagenData != null) {
            imagenes.add(_validateImageData(imagenData));
          }
        }
      }
    }
    
    return imagenes;
  }

  Map<String, dynamic> _validateImageData(dynamic imagenData) {
    if (imagenData is Map<String, dynamic>) {
      return imagenData;
    } else if (imagenData is String) {
      return {
        'base64': imagenData,
        'type': 'base64',
      };
    } else {
      return {
        'base64': '',
        'type': 'base64',
      };
    }
  }

  void _mostrarDetallesModal(VisitaBloqueadaModel visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DetalleBloqueoVisitaModal(
          visita: visita,
          condominioId: widget.currentUser.condominioId ?? '',
        );
      },
    );
  }
}

class _DetalleBloqueoVisitaModal extends StatefulWidget {
  final VisitaBloqueadaModel visita;
  final String condominioId;

  const _DetalleBloqueoVisitaModal({
    Key? key,
    required this.visita,
    required this.condominioId,
  }) : super(key: key);

  @override
  State<_DetalleBloqueoVisitaModal> createState() => _DetalleBloqueoVisitaModalState();
}

class _DetalleBloqueoVisitaModalState extends State<_DetalleBloqueoVisitaModal> {
  final BloqueoVisitasService _bloqueoVisitasService = BloqueoVisitasService();
  Map<String, String>? _infoUsuario;

  @override
  void initState() {
    super.initState();
    _cargarInfoUsuario();
  }

  Future<void> _cargarInfoUsuario() async {
    final info = await _bloqueoVisitasService.obtenerInfoUsuarioBloqueo(
      condominioId: widget.condominioId,
      usuarioId: widget.visita.bloqueadoPor,
    );
    
    if (mounted) {
      setState(() {
        _infoUsuario = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del Bloqueo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del visitante
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'Nombre del Visitante',
                      value: widget.visita.nombreVisitante,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.badge,
                      label: 'RUT',
                      value: widget.visita.rutVisitante,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.home,
                      label: 'Vivienda',
                      value: widget.visita.viviendaBloqueo,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.info_outline,
                      label: 'Estado',
                      value: widget.visita.estado,
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.visita.estado == 'activo' 
                              ? Colors.red.shade100 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.visita.estado.toUpperCase(),
                          style: TextStyle(
                            color: widget.visita.estado == 'activo' 
                                ? Colors.red.shade700 
                                : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Fecha de Bloqueo',
                      value: widget.visita.fechaBloqueoFormateada,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'Bloqueado por',
                      value: _infoUsuario != null 
                          ? '${_infoUsuario!['nombre']} (${_infoUsuario!['cargo']})'
                          : 'Cargando...',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Motivo del bloqueo
                    const Text(
                      'Motivo del Bloqueo:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        widget.visita.motivoBloqueo,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Imágenes en formato grid
                    const Text(
                      'Imágenes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagenesGrid(widget.visita),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ?? Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenesGrid(VisitaBloqueadaModel visita) {
    final imagenes = _obtenerImagenesVisitaBloqueada(visita);
    
    if (imagenes.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('No hay imágenes disponibles', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imagenes.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ImageFullscreenHelper.showFullscreenImage(context, imagenes[index]);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageCarouselWidget(
                images: [imagenes[index]],
                height: 100,
                borderRadius: BorderRadius.circular(8.0),
                onImageTap: (imageData) {
                  ImageFullscreenHelper.showFullscreenImage(context, imageData);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _obtenerImagenesVisitaBloqueada(VisitaBloqueadaModel visita) {
    List<Map<String, dynamic>> imagenes = [];
    
    if (visita.additionalData != null) {
      // Buscar imágenes en additionalData con las claves imagen1, imagen2, imagen3
      for (int i = 1; i <= 3; i++) {
        final imagenKey = 'imagen$i';
        if (visita.additionalData!.containsKey(imagenKey)) {
          final imagenData = visita.additionalData![imagenKey];
          if (imagenData != null) {
            imagenes.add(_validateImageData(imagenData));
          }
        }
      }
    }
    
    return imagenes;
  }

  Map<String, dynamic> _validateImageData(dynamic imagenData) {
    if (imagenData is Map<String, dynamic>) {
      return imagenData;
    } else if (imagenData is String) {
      return {
        'base64': imagenData,
        'type': 'base64',
      };
    } else {
      return {
        'base64': '',
        'type': 'base64',
      };
    }
  }
}