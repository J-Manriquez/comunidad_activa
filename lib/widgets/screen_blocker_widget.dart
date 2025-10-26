import 'package:flutter/material.dart';

class ScreenBlockerWidget extends StatelessWidget {
  final String? customMessage;
  final IconData? customIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const ScreenBlockerWidget({
    super.key,
    this.customMessage,
    this.customIcon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultMessage = customMessage ?? 'No tienes permisos para usar esta pantalla';
    final defaultIcon = customIcon ?? Icons.lock_outline;
    final bgColor = backgroundColor ?? Colors.grey.shade100;
    final txtColor = textColor ?? Colors.grey.shade700;
    final icnColor = iconColor ?? Colors.grey.shade600;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: icnColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  defaultIcon,
                  size: 64,
                  color: icnColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Mensaje principal
              Text(
                defaultMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                ) ?? TextStyle(
                  fontSize: 24,
                  color: txtColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mensaje secundario
              Text(
                'Contacta al administrador si crees que esto es un error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: txtColor.withOpacity(0.7),
                ) ?? TextStyle(
                  fontSize: 16,
                  color: txtColor.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Decoración adicional
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: icnColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget wrapper que puede bloquear o mostrar contenido basado en una condición
class ConditionalScreenBlocker extends StatelessWidget {
  final bool shouldBlock;
  final Widget child;
  final String? blockMessage;
  final IconData? blockIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const ConditionalScreenBlocker({
    super.key,
    required this.shouldBlock,
    required this.child,
    this.blockMessage,
    this.blockIcon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldBlock) {
      return ScreenBlockerWidget(
        customMessage: blockMessage,
        customIcon: blockIcon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        iconColor: iconColor,
      );
    }
    
    return child;
  }
}