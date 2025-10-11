import 'package:flutter/material.dart';
import 'package:comunidad_activa/utils/image_display_widget.dart';

/// Helper class para mostrar imágenes en pantalla completa
class ImageFullscreenHelper {
  /// Muestra una imagen en pantalla completa usando un Dialog
  static void showFullscreenImage(
    BuildContext context,
    Map<String, dynamic> imageData, {
    bool dismissible = true,
    Color backgroundColor = Colors.black,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: backgroundColor.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Fondo para detectar taps y cerrar
              GestureDetector(
                onTap: dismissible ? () => Navigator.of(context).pop() : null,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              // Imagen en pantalla completa con zoom
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ImageDisplayWidget(
                    imageData: imageData,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Botón de cerrar
              if (dismissible)
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Crea un callback onTap que muestra la imagen en pantalla completa
  static VoidCallback createFullscreenCallback(
    BuildContext context,
    Map<String, dynamic> imageData, {
    bool dismissible = true,
    Color backgroundColor = Colors.black,
  }) {
    return () => showFullscreenImage(
          context,
          imageData,
          dismissible: dismissible,
          backgroundColor: backgroundColor,
        );
  }
}