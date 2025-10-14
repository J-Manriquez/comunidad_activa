import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/visita_bloqueada_model.dart';
import '../../services/bloqueo_visitas_service.dart';
import '../../widgets/image_carousel_widget.dart';
import '../../utils/image_fullscreen_helper.dart';
import '../../utils/image_display_widget.dart';
import 'visitasBloqueadas/crear_bloqueo_visita_screen.dart';

class BloqueoVisitasScreen extends StatefulWidget {
  final UserModel currentUser;

  const BloqueoVisitasScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<BloqueoVisitasScreen> createState() => _BloqueoVisitasScreenState();
}

class _BloqueoVisitasScreenState extends State<BloqueoVisitasScreen> {
  final BloqueoVisitasService _bloqueoVisitasService = BloqueoVisitasService();
  String _filtroEstado = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloqueo de Visitas'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _filtroEstado = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'activo',
                child: Text('Activos'),
              ),
              const PopupMenuItem(
                value: 'expirado',
                child: Text('Expirados'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Botón para crear nuevo bloqueo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrearBloqueoVisitaScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
                
                // Si se creó exitosamente un bloqueo, actualizar la pantalla
                if (result == true) {
                  setState(() {
                    // Esto forzará la reconstrucción del FutureBuilder
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Bloqueo de Visita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          
          // Lista de visitas bloqueadas
          Expanded(
            child: FutureBuilder<List<VisitaBloqueadaModel>>(
              future: _bloqueoVisitasService.obtenerVisitasBloqueadas(
                widget.currentUser.condominioId ?? '',
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
                    child: Text('No hay visitas bloqueadas'),
                  );
                }

                List<VisitaBloqueadaModel> visitasFiltradas = snapshot.data!;
                
                if (_filtroEstado != 'todos') {
                  visitasFiltradas = visitasFiltradas
                      .where((visita) => visita.estado == _filtroEstado)
                      .toList();
                }

                if (visitasFiltradas.isEmpty) {
                  return Center(
                    child: Text('No hay visitas con estado: $_filtroEstado'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: visitasFiltradas.length,
                  itemBuilder: (context, index) {
                    return _buildVisitaCard(visitasFiltradas[index]);
                  },
                );
              },
            ),
          ),
        ],
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
                        const Icon(Icons.home, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Vivienda: ${visita.viviendaBloqueo}',
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
                  ],
                ),
              ),
            ],
          ),
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

  Map<String, dynamic> _validateImageData(dynamic imageData) {
    if (imageData is Map<String, dynamic>) {
      // Si ya tiene la estructura correcta, verificar que tenga 'type' y 'data'
      if (imageData.containsKey('type') && imageData.containsKey('data')) {
        return imageData;
      }
      
      // Si no tiene 'type', inferirlo basado en la estructura
      if (imageData.containsKey('data')) {
        String type = 'normal';
        if (imageData.containsKey('fragments')) {
          type = imageData.containsKey('isInternal') && imageData['isInternal'] == true
              ? 'internal_fragmented'
              : 'external_fragmented';
        }
        return {
          'type': type,
          'data': imageData['data'],
          if (imageData.containsKey('fragments')) 'fragments': imageData['fragments'],
          if (imageData.containsKey('isInternal')) 'isInternal': imageData['isInternal'],
        };
      }
    }
    
    // Si es un string (base64 directo), crear la estructura
    if (imageData is String) {
      return {
        'type': 'normal',
        'data': imageData,
      };
    }
    
    // Fallback: imagen placeholder
    return {
      'type': 'placeholder',
      'data': 'placeholder_image',
    };
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

  Widget _buildEstadoChip(String estado) {
    Color color;
    String texto;
    
    switch (estado.toLowerCase()) {
      case 'activo':
        color = Colors.red;
        texto = 'Activo';
        break;
      case 'expirado':
        color = Colors.grey;
        texto = 'Expirado';
        break;
      default:
        color = Colors.blue;
        texto = estado;
    }

    return Chip(
      label: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }

  void _mostrarDetallesModal(VisitaBloqueadaModel visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DetalleBloqueoVisitaModal(
          visita: visita,
          onExpirar: () => _cambiarEstado(visita),
          condominioId: widget.currentUser.condominioId ?? '',
        );
      },
    );
  }

  void _cambiarEstado(VisitaBloqueadaModel visita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar Estado'),
          content: Text(
            '¿Está seguro que desea marcar como expirado el bloqueo de ${visita.nombreVisitante}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _bloqueoVisitasService.cambiarEstadoVisita(
                    condominioId: widget.currentUser.condominioId ?? '',
                    visitaId: visita.id,
                    nuevoEstado: 'expirado',
                  );
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Cerrar el modal de detalles también
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Estado actualizado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {}); // Refrescar la lista
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar estado: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Expirar'),
            ),
          ],
        );
      },
    );
  }
}

class _DetalleBloqueoVisitaModal extends StatefulWidget {
  final VisitaBloqueadaModel visita;
  final VoidCallback onExpirar;
  final String condominioId;

  const _DetalleBloqueoVisitaModal({
    Key? key,
    required this.visita,
    required this.onExpirar,
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
    try {
      final info = await _bloqueoVisitasService.obtenerInfoUsuarioBloqueo(
        condominioId: widget.condominioId,
        usuarioId: widget.visita.bloqueadoPor,
      );
      if (mounted) {
        setState(() {
          _infoUsuario = info;
        });
      }
    } catch (e) {
      print('Error al cargar información del usuario: $e');
      if (mounted) {
        setState(() {
          _infoUsuario = {
            'nombre': 'Error al cargar',
            'cargo': 'Desconocido',
          };
        });
      }
    }
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

  Map<String, dynamic> _validateImageData(dynamic imageData) {
    if (imageData is Map<String, dynamic>) {
      // Si ya tiene la estructura correcta, verificar que tenga 'type' y 'data'
      if (imageData.containsKey('type') && imageData.containsKey('data')) {
        return imageData;
      }
      
      // Si no tiene 'type', inferirlo basado en la estructura
      if (imageData.containsKey('data')) {
        String type = 'normal';
        if (imageData.containsKey('fragments')) {
          type = imageData.containsKey('isInternal') && imageData['isInternal'] == true
              ? 'internal_fragmented'
              : 'external_fragmented';
        }
        return {
          'type': type,
          'data': imageData['data'],
          if (imageData.containsKey('fragments')) 'fragments': imageData['fragments'],
          if (imageData.containsKey('isInternal')) 'isInternal': imageData['isInternal'],
        };
      }
    }
    
    // Si es un string (base64 directo), crear la estructura
    if (imageData is String) {
      return {
        'type': 'normal',
        'data': imageData,
      };
    }
    
    // Fallback: imagen placeholder
    return {
      'type': 'placeholder',
      'data': 'placeholder_image',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalles del Bloqueo',
                      style: const TextStyle(
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
                    // Nombre del visitante
                    Text(
                      widget.visita.nombreVisitante,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información básica
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'RUT',
                      value: widget.visita.rutVisitante,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.home,
                      label: 'Vivienda',
                      value: widget.visita.viviendaBloqueo,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.info,
                      label: 'Estado',
                      value: widget.visita.estado,
                      valueColor: widget.visita.estado == 'activo' ? Colors.red : Colors.grey,
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
            
            // Botón de acción
            if (widget.visita.estado == 'activo')
              Container(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onExpirar,
                    icon: const Icon(Icons.block),
                    label: const Text('Expirar Bloqueo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
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
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'No hay imágenes disponibles',
              style: TextStyle(color: Colors.grey),
            ),
          ],
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
        final imagenData = imagenes[index];
        return GestureDetector(
          onTap: () => ImageFullscreenHelper.showFullscreenImage(context, imagenData),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageDisplayWidget(
                    imageData: imagenData,
                    fit: BoxFit.cover,
                  ),
                  // Overlay para indicar que se puede tocar
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}