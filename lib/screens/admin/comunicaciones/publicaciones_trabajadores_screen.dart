import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/publicacion_service.dart';
import '../../../widgets/image_carousel_widget.dart';
import '../../../utils/image_fullscreen_helper.dart';
import '../../comunicaciones/ver_publicacion_screen.dart';

class PublicacionesTrabajadoresScreen extends StatefulWidget {
  final UserModel currentUser;

  const PublicacionesTrabajadoresScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<PublicacionesTrabajadoresScreen> createState() => _PublicacionesTrabajadoresScreenState();
}

class _PublicacionesTrabajadoresScreenState extends State<PublicacionesTrabajadoresScreen> {
  final PublicacionService _publicacionService = PublicacionService();
  List<PublicacionModel> _publicaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
  }

  Future<void> _cargarPublicaciones() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final publicaciones = await _publicacionService.obtenerPublicacionesPorTipo(
        widget.currentUser.condominioId!,
        'trabajadores',
      );
      
      if (mounted) {
        setState(() {
          _publicaciones = publicaciones;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar publicaciones para trabajadores: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return DateFormat('dd/MM/yyyy HH:mm', 'es').format(fecha);
    } catch (e) {
      return fechaIso;
    }
  }

  void _mostrarDetallePublicacion(PublicacionModel publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerPublicacionScreen(
          publicacion: publicacion,
          currentUser: widget.currentUser,
          esAdministrador: false,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay publicaciones para trabajadores',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las publicaciones dirigidas a trabajadores aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicaciones para Trabajadores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              print('🔧 Botón de corrección presionado');
              await _publicacionService.corregirEstadoPublicaciones(widget.currentUser.condominioId!);
              await _cargarPublicaciones();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Corregir y recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publicaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarPublicaciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _publicaciones.length,
                    itemBuilder: (context, index) {
                      final publicacion = _publicaciones[index];
                      return _buildPublicacionCard(publicacion);
                    },
                  ),
                ),
    );
  }

  Widget _buildPublicacionCard(PublicacionModel publicacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallePublicacion(publicacion),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y fecha
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      publicacion.titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  Text(
                    _formatearFecha(publicacion.fechaPublicacion),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrusel de imágenes si existen
                  if (publicacion.additionalData != null && 
                      (publicacion.additionalData!.containsKey('imagen1Data') ||
                       publicacion.additionalData!.containsKey('imagen2Data') ||
                       publicacion.additionalData!.containsKey('imagen3Data')))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildImagenesPublicacion(publicacion),
                    ),
                  
                  // Contenido de texto
                  Text(
                    publicacion.contenido,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer con estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: publicacion.estado == 'activa' 
                              ? Colors.green[100] 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          publicacion.estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: publicacion.estado == 'activa' 
                                ? Colors.green[700] 
                                : Colors.red[700],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
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

  Widget _buildImagenesPublicacion(PublicacionModel publicacion) {
    List<Map<String, dynamic>> images = [];
    
    if (publicacion.additionalData != null) {
      // Buscar imagen1Data, imagen2Data, imagen3Data
      for (int i = 1; i <= 3; i++) {
        final imageKey = 'imagen${i}Data';
        if (publicacion.additionalData![imageKey] != null) {
          final imageData = publicacion.additionalData![imageKey];
          if (imageData is Map<String, dynamic>) {
            // Imagen fragmentada
            images.add(imageData);
          } else if (imageData is String && imageData.isNotEmpty) {
            // Imagen Base64 (compatibilidad hacia atrás)
            images.add({'type': 'base64', 'data': imageData});
          }
        }
      }
    }
    
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.article,
            color: Colors.grey[400],
            size: 60,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      child: ImageCarouselWidget(
        images: images,
        height: 200,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        onImageTap: (imageData) {
          ImageFullscreenHelper.showFullscreenImage(context, imageData);
        },
      ),
    );
  }
}