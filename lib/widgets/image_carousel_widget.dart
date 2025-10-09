import 'package:flutter/material.dart';
import '../utils/image_display_widget.dart';

class ImageCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Function(Map<String, dynamic>)? onImageTap;

  const ImageCarouselWidget({
    Key? key,
    required this.images,
    this.width = double.infinity,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onImageTap,
  }) : super(key: key);

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Map<String, dynamic> _validateImageData(Map<String, dynamic> imageData) {
    // Validar y corregir la estructura de imageData si es necesario
    if (imageData['type'] == null) {
      // Intentar inferir el tipo basado en la estructura
      if (imageData['data'] != null && imageData['data'] is String) {
        imageData['type'] = 'normal';
      } else if (imageData['fragments'] != null && imageData['fragments'] is List) {
        final fragments = imageData['fragments'] as List;
        imageData['type'] = fragments.length <= 10 ? 'internal_fragmented' : 'external_fragmented';
      } else {
        // Tipo desconocido, usar placeholder
        return {
          'type': 'placeholder',
          'data': null,
        };
      }
    }
    return imageData;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.business,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    // Validar todas las imágenes
    final validImages = widget.images.map((image) => _validateImageData(image)).toList();

    if (validImages.length == 1) {
      // Si solo hay una imagen, mostrarla sin carrusel
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: _buildImageWithErrorHandling(validImages.first),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Carrusel de imágenes
          ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: validImages.length,
              itemBuilder: (context, index) {
                return _buildImageWithErrorHandling(validImages[index]);
              },
            ),
          ),
          
          // Indicadores de página (dots)
          if (validImages.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  validImages.length,
                  (index) => GestureDetector(
                    onTap: () => _goToPage(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Botones de navegación (solo si hay más de una imagen)
          if (validImages.length > 1) ...[
            // Botón anterior
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex > 0) {
                      _goToPage(_currentIndex - 1);
                    } else {
                      _goToPage(validImages.length - 1);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            
            // Botón siguiente
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex < validImages.length - 1) {
                      _goToPage(_currentIndex + 1);
                    } else {
                      _goToPage(0);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Contador de imágenes
          if (validImages.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${validImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWithErrorHandling(Map<String, dynamic> imageData) {
    // Si es un placeholder o datos inválidos, mostrar icono por defecto
    if (imageData['type'] == 'placeholder' || imageData['data'] == null) {
      return GestureDetector(
        onTap: widget.onImageTap != null ? () => widget.onImageTap!(imageData) : null,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.business,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onImageTap != null ? () => widget.onImageTap!(imageData) : null,
      child: ImageDisplayWidget(
        imageData: imageData,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorWidget: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Error al cargar imagen',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}