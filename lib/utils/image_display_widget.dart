import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/utils/storage_service.dart';
import 'package:comunidad_activa/utils/profile_image.dart';

/// Widget para mostrar imágenes que pueden estar fragmentadas externamente
class ImageDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> imageData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const ImageDisplayWidget({
    Key? key,
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ImageDisplayWidget> createState() => _ImageDisplayWidgetState();
}

class _ImageDisplayWidgetState extends State<ImageDisplayWidget> {
  // Cache para imágenes reconstruidas
  static final Map<String, String> _imageCache = {};
  static final Map<String, Future<String>> _futureCache = {};
  
  @override
  Widget build(BuildContext context) {
    final type = widget.imageData['type'] as String;
    
    switch (type) {
      case 'normal':
      case 'internal_fragmented':
        // Usar ProfileImage para imágenes normales y fragmentadas internamente
        return ProfileImage(
          imageData: widget.imageData,
          width: widget.width ?? 100,
          height: widget.height ?? 100,
          fit: widget.fit,
        );
      
      case 'external_fragmented':
        return _buildExternalFragmentedImage();
      
      default:
        return _buildErrorWidget('Tipo de imagen no reconocido: $type');
    }
  }
  
  Widget _buildExternalFragmentedImage() {
    final fragmentId = widget.imageData['fragment_id'] as String;
    final totalFragments = widget.imageData['total_fragments'] as int;
    final originalType = widget.imageData['original_type'] as String;
    
    // Verificar cache
    if (_imageCache.containsKey(fragmentId)) {
      return _buildImageFromBase64(_imageCache[fragmentId]!);
    }
    
    // Verificar cache de futures
    if (_futureCache.containsKey(fragmentId)) {
      return FutureBuilder<String>(
        future: _futureCache[fragmentId]!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }
          
          if (snapshot.hasError) {
            return _buildErrorWidget('Error: ${snapshot.error}');
          }
          
          if (snapshot.hasData) {
            return _buildImageFromBase64(snapshot.data!);
          }
          
          return _buildErrorWidget('No se pudo cargar la imagen');
        },
      );
    }
    
    // Crear nuevo future y agregarlo al cache
    final future = _loadExternalFragments(fragmentId, totalFragments, originalType);
    _futureCache[fragmentId] = future;
    
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget('Error: ${snapshot.error}');
        }
        
        if (snapshot.hasData) {
          return _buildImageFromBase64(snapshot.data!);
        }
        
        return _buildErrorWidget('No se pudo cargar la imagen');
      },
    );
  }
  
  Future<String> _loadExternalFragments(String fragmentId, int totalFragments, String originalType) async {
    try {
      final fragments = <String>[];
      
      // Cargar todos los fragmentos desde Firestore
      for (int i = 0; i < totalFragments; i++) {
        final doc = await FirebaseFirestore.instance
            .collection('image_fragments')
            .doc('${fragmentId}_$i')
            .get();
        
        if (!doc.exists) {
          throw Exception('Fragmento $i no encontrado');
        }
        
        final data = doc.data()!;
        fragments.add(data['fragment'] as String);
      }
      
      // Reconstruir la imagen
      final completeImage = StorageService.reconstruirImagenBase64(fragments, originalType);
      
      // Guardar en cache
      _imageCache[fragmentId] = completeImage;
      
      // Limpiar el future cache
      _futureCache.remove(fragmentId);
      
      return completeImage;
    } catch (e) {
      // Limpiar el future cache en caso de error
      _futureCache.remove(fragmentId);
      throw e;
    }
  }
  
  Widget _buildImageFromBase64(String base64Image) {
    try {
      final cleanBase64 = base64Image.split(',').last;
      final bytes = base64Decode(cleanBase64);
      
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget('Error al mostrar imagen');
          },
        ),
      );
    } catch (e) {
      return _buildErrorWidget('Error al decodificar imagen: $e');
    }
  }
  
  Widget _buildLoadingWidget() {
    return widget.placeholder ?? Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildErrorWidget(String message) {
    return widget.errorWidget ?? Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Icon(
              Icons.error,
              color: Colors.red,
              size: (widget.height != null && widget.height! < 60) ? 16 : 32,
            ),
          ),
          if (widget.height == null || widget.height! > 40) ...[
            const SizedBox(height: 2),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: (widget.height != null && widget.height! < 60) ? 8 : 10, 
                    color: Colors.red
                  ),
                  textAlign: TextAlign.center,
                  maxLines: (widget.height != null && widget.height! < 60) ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Limpia el cache de imágenes (útil para liberar memoria)
  static void clearCache() {
    _imageCache.clear();
    _futureCache.clear();
  }
  
  /// Limpia una imagen específica del cache
  static void clearImageFromCache(String fragmentId) {
    _imageCache.remove(fragmentId);
    _futureCache.remove(fragmentId);
  }
}

/// Widget para subir imágenes con progreso y fragmentación automática
class ImageUploadWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onImageSelected;
  final String? initialImage;
  final double? width;
  final double? height;
  final String buttonText;
  final IconData buttonIcon;

  const ImageUploadWidget({
    Key? key,
    required this.onImageSelected,
    this.initialImage,
    this.width = 200,
    this.height = 200,
    this.buttonText = 'Seleccionar Imagen',
    this.buttonIcon = Icons.add_photo_alternate,
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _currentImageData;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _currentImageData = {
        'type': 'normal',
        'data': widget.initialImage!,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _selectImage,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildContent(),
          ),
        ),
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text('${(_uploadProgress * 100).toInt()}%'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isUploading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentImageData != null) {
      return ImageDisplayWidget(
        imageData: _currentImageData!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.buttonIcon,
          size: 48,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          widget.buttonText,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      // Aquí deberías implementar la selección de imagen usando image_picker
      // Por ahora, esto es un placeholder
      
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Simular selección de imagen y procesamiento
      // En una implementación real, usarías ImagePicker aquí
      
      // final picker = ImagePicker();
      // final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      // 
      // if (pickedFile != null) {
      //   final imageData = await _storageService.procesarImagenFragmentada(
      //     xFile: pickedFile,
      //     onProgress: (progress) {
      //       setState(() {
      //         _uploadProgress = progress;
      //       });
      //     },
      //   );
      //   
      //   setState(() {
      //     _currentImageData = imageData;
      //     _isUploading = false;
      //   });
      //   
      //   widget.onImageSelected(imageData);
      // }
      
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}