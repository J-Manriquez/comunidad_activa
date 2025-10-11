import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../models/publicacion_model.dart';
import '../../services/publicacion_service.dart';
import '../../utils/profile_image.dart';
import '../../utils/image_display_widget.dart';
import '../../utils/image_fullscreen_helper.dart';

class VerPublicacionScreen extends StatefulWidget {
  final PublicacionModel publicacion;
  final UserModel currentUser;
  final bool esAdministrador;

  const VerPublicacionScreen({
    Key? key,
    required this.publicacion,
    required this.currentUser,
    this.esAdministrador = false,
  }) : super(key: key);

  @override
  State<VerPublicacionScreen> createState() => _VerPublicacionScreenState();
}

class _VerPublicacionScreenState extends State<VerPublicacionScreen> {
  final PublicacionService _publicacionService = PublicacionService();
  late PublicacionModel _publicacion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _publicacion = widget.publicacion;
    _marcarComoLeida();
  }

  Future<void> _marcarComoLeida() async {
    if (!widget.esAdministrador && !_esPublicacionLeida()) {
      try {
        await _publicacionService.marcarComoLeida(
          widget.currentUser.condominioId!,
          _publicacion.id,
          widget.currentUser.uid,
        );
      } catch (e) {
        print('Error al marcar como leída: $e');
      }
    }
  }

  bool _esPublicacionLeida() {
    return _publicacion.isRead?[widget.currentUser.uid] == true;
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return DateFormat('dd/MM/yyyy HH:mm', 'es').format(fecha);
    } catch (e) {
      return fechaIso;
    }
  }

  List<Map<String, dynamic>> _obtenerImagenes() {
    final imagenes = <Map<String, dynamic>>[];
    final additionalData = _publicacion.additionalData;
    
    if (additionalData != null) {
      // Buscar imágenes en additionalData (soporte para ambos formatos)
      for (int i = 1; i <= 3; i++) {
        // Nuevo formato fragmentado
        final imagenData = additionalData['imagen${i}Data'];
        if (imagenData != null && imagenData is Map<String, dynamic>) {
          imagenes.add(imagenData);
        }
        // Formato anterior Base64
        else {
          final imagenBase64 = additionalData['imagen$i'] ?? additionalData['imagen${i}Base64'];
          if (imagenBase64 != null && imagenBase64.toString().isNotEmpty) {
            imagenes.add({'type': 'base64', 'data': imagenBase64.toString()});
          }
        }
      }
    }
    
    return imagenes;
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = _obtenerImagenes();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.article,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _publicacion.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Información de la publicación
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Publicado el ${_formatearFecha(_publicacion.fechaPublicacion)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (_publicacion.additionalData?['nombreCreador'] != null) ...[
                          Icon(
                            Icons.person,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _publicacion.additionalData!['nombreCreador'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de publicación
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Para ${_publicacion.tipoPublicacion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Contenido de la publicación
                  const Text(
                    'Contenido:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _publicacion.contenido,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  // Imágenes si existen
                  if (imagenes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Imágenes:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagenesGrid(imagenes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesGrid(List<Map<String, dynamic>> imagenes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: imagenes.length,
      itemBuilder: (context, index) {
        final imagenData = imagenes[index];
        return GestureDetector(
          onTap: () => ImageFullscreenHelper.showFullscreenImage(context, imagenData),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageDisplayWidget(
                    imageData: imagenData,
                    fit: BoxFit.cover,
                  ),
                  // Overlay para indicar que se puede tocar
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
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