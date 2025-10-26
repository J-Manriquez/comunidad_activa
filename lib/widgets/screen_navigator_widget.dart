import 'package:flutter/material.dart';
import 'screen_blocker_widget.dart';
import '../services/permission_service.dart';

/// Widget que maneja la navegación y verificación de permisos de pantallas
class ScreenNavigatorWidget extends StatelessWidget {
  final Widget child;
  final String primaryPermission;
  final List<String>? specificPermissions;
  final String? customBlockMessage;
  final IconData? blockIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const ScreenNavigatorWidget({
    super.key,
    required this.child,
    required this.primaryPermission,
    this.specificPermissions,
    this.customBlockMessage,
    this.blockIcon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionResult>(
      future: PermissionService.checkScreenPermissions(
        primaryPermission: primaryPermission,
        specificPermissions: specificPermissions,
        customBlockMessage: customBlockMessage,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return ScreenBlockerWidget(
            customMessage: 'Error al verificar permisos: ${snapshot.error}',
            customIcon: Icons.error,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
          );
        }

        final result = snapshot.data!;

        if (!result.hasAccess) {
          return ScreenBlockerWidget(
            customMessage: result.blockMessage ?? result.error ?? 'Acceso denegado',
            customIcon: blockIcon,
            backgroundColor: backgroundColor,
            textColor: textColor,
            iconColor: iconColor,
          );
        }

        return child;
      },
    );
  }
}

/// Widget simplificado para verificación básica de permisos
class SimpleScreenNavigator extends StatelessWidget {
  final Widget child;
  final String primaryPermission;
  final List<String>? specificPermissions;
  final String? customBlockMessage;

  const SimpleScreenNavigator({
    Key? key,
    required this.child,
    required this.primaryPermission,
    this.specificPermissions,
    this.customBlockMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      child: child,
      primaryPermission: primaryPermission,
      specificPermissions: specificPermissions ?? [],
      customBlockMessage: customBlockMessage,
    );
  }
}