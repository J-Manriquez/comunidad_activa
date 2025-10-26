import 'package:comunidad_activa/models/user_model.dart';
import 'package:flutter/material.dart';
import 'screen_navigator_widget.dart';
import '../services/permission_service.dart';

/// EJEMPLOS DE USO DEL SISTEMA DE PERMISOS
/// 
/// Este archivo contiene ejemplos de cómo implementar el sistema de permisos
/// tanto usando los widgets como usando directamente el PermissionService

// ============================================================================
// MÉTODO 1: USANDO WIDGETS (ScreenNavigatorWidget y SimpleScreenNavigator)
// ============================================================================

/// Ejemplo 1: Pantalla de Correspondencia usando SimpleScreenNavigator
class CorrespondenciaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleScreenNavigator(
      primaryPermission: 'correspondencia',
      specificPermissions: ['correspondencia'],
      customBlockMessage: 'No tienes permisos para gestionar la correspondencia',
      child: Scaffold(
        appBar: AppBar(title: Text('Correspondencia')),
        body: Center(
          child: Text('Contenido de la pantalla de correspondencia'),
        ),
      ),
    );
  }
}

/// Ejemplo 2: Pantalla de Control de Acceso usando ScreenNavigatorWidget con personalización
class ControlAccesoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'controlAcceso',
      specificPermissions: ['controlAcceso'],
      customBlockMessage: 'Esta función está restringida para tu tipo de usuario',
      blockIcon: Icons.security,
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red.shade800,
      iconColor: Colors.red.shade600,
      child: Scaffold(
        appBar: AppBar(title: Text('Control de Acceso')),
        body: Center(
          child: Text('Contenido del control de acceso'),
        ),
      ),
    );
  }
}

// ============================================================================
// MÉTODO 2: USANDO DIRECTAMENTE EL PERMISSIONSERVICE
// ============================================================================

/// Ejemplo 3: Pantalla que verifica permisos manualmente
class GestionEstacionamientosScreen extends StatefulWidget {
  @override
  _GestionEstacionamientosScreenState createState() => _GestionEstacionamientosScreenState();
}

class _GestionEstacionamientosScreenState extends State<GestionEstacionamientosScreen> {
  bool _hasAccess = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final hasAccess = await PermissionService.hasPermission(
        primaryPermission: 'gestionEstacionamientos',
        specificPermissions: ['gestionEstacionamientos'],
      );
      
      setState(() {
        _hasAccess = hasAccess;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al verificar permisos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestión de Estacionamientos')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestión de Estacionamientos')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: Text('Gestión de Estacionamientos')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'No tienes permisos para gestionar estacionamientos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Gestión de Estacionamientos')),
      body: Center(
        child: Text('Contenido de gestión de estacionamientos'),
      ),
    );
  }
}

/// Ejemplo 4: Pantalla con verificaciones condicionales de UI
class EspaciosComunesScreen extends StatefulWidget {
  @override
  _EspaciosComunesScreenState createState() => _EspaciosComunesScreenState();
}

class _EspaciosComunesScreenState extends State<EspaciosComunesScreen> {
  bool _canManageSpaces = false;
  bool _canViewReservations = false;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Verificar múltiples permisos de una vez
      final permissions = await PermissionService.checkMultiplePermissions([
        'espaciosComunes',
        'reservasEspacios',
      ]);

      final isAdmin = await PermissionService.isAdmin();

      setState(() {
        _canManageSpaces = permissions['espaciosComunes'] ?? false;
        _canViewReservations = permissions['reservasEspacios'] ?? false;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Espacios Comunes')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Espacios Comunes')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opciones disponibles:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            
            // Botón condicional para gestionar espacios
            if (_canManageSpaces)
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar a gestión de espacios
                },
                icon: Icon(Icons.settings),
                label: Text('Gestionar Espacios'),
              ),
            
            SizedBox(height: 8),
            
            // Botón condicional para ver reservas
            if (_canViewReservations)
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar a reservas
                },
                icon: Icon(Icons.calendar_today),
                label: Text('Ver Reservas'),
              ),
            
            SizedBox(height: 8),
            
            // Botón solo para administradores
            if (_isAdmin)
              ElevatedButton.icon(
                onPressed: () {
                  // Funcionalidad de admin
                },
                icon: Icon(Icons.admin_panel_settings),
                label: Text('Panel de Administración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            
            SizedBox(height: 16),
            
            // Mostrar mensaje si no tiene permisos
            if (!_canManageSpaces && !_canViewReservations)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No tienes permisos para gestionar espacios comunes',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ejemplo 5: Widget personalizado que usa PermissionService
class PermissionAwareButton extends StatefulWidget {
  final String requiredPermission;
  final List<String>? specificPermissions;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PermissionAwareButton({
    Key? key,
    required this.requiredPermission,
    required this.label,
    required this.onPressed,
    this.specificPermissions,
    this.icon,
  }) : super(key: key);

  @override
  _PermissionAwareButtonState createState() => _PermissionAwareButtonState();
}

class _PermissionAwareButtonState extends State<PermissionAwareButton> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await PermissionService.hasPermission(
      primaryPermission: widget.requiredPermission,
      specificPermissions: widget.specificPermissions,
    );
    
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (!_hasPermission) {
      return SizedBox.shrink(); // No mostrar el botón si no tiene permisos
    }

    return ElevatedButton.icon(
      onPressed: widget.onPressed,
      icon: Icon(widget.icon ?? Icons.check),
      label: Text(widget.label),
    );
  }
}

// ============================================================================
// EJEMPLOS DE USO DE MÉTODOS ESPECÍFICOS DEL PERMISSIONSERVICE
// ============================================================================

/// Ejemplo 6: Pantalla que demuestra el uso de métodos específicos
class PermissionDemoScreen extends StatefulWidget {
  @override
  _PermissionDemoScreenState createState() => _PermissionDemoScreenState();
}

class _PermissionDemoScreenState extends State<PermissionDemoScreen> {
  Map<String, dynamic>? _userInfo;
  Map<String, bool>? _primaryPermissions;
  Map<String, bool>? _specificPermissions;
  UserType? _userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionInfo();
  }

  Future<void> _loadPermissionInfo() async {
    try {
      final userInfo = await PermissionService.getUserPermissionsInfo();
      final primaryPermissions = await PermissionService.getPrimaryPermissions();
      final specificPermissions = await PermissionService.getSpecificPermissions();
      final userType = await PermissionService.getCurrentUserType();

      setState(() {
        _userInfo = userInfo;
        _primaryPermissions = primaryPermissions;
        _specificPermissions = specificPermissions;
        _userType = userType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Demo de Permisos')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Demo de Permisos')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Usuario',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text('Tipo: ${_userType?.toString() ?? 'Desconocido'}'),
                    if (_userInfo != null) ...[
                      Text('Email: ${_userInfo!['user']['email'] ?? 'N/A'}'),
                      Text('Nombre: ${_userInfo!['user']['nombre'] ?? 'N/A'}'),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Permisos primarios
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permisos Primarios del Condominio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    if (_primaryPermissions != null)
                      ...(_primaryPermissions!.entries.map((entry) => 
                        Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.cancel,
                              color: entry.value ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('${entry.key}: ${entry.value ? 'Habilitado' : 'Deshabilitado'}'),
                          ],
                        ),
                      ).toList())
                    else
                      Text('No se pudieron cargar los permisos primarios'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Permisos específicos
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permisos Específicos del Usuario',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    if (_specificPermissions != null && _specificPermissions!.isNotEmpty)
                      ...(_specificPermissions!.entries.map((entry) => 
                        Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.cancel,
                              color: entry.value ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('${entry.key}: ${entry.value ? 'Permitido' : 'Denegado'}'),
                          ],
                        ),
                      ).toList())
                    else
                      Text('Este tipo de usuario no tiene permisos específicos'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Botones de ejemplo usando PermissionAwareButton
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Botones Condicionales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PermissionAwareButton(
                          requiredPermission: 'correspondencia',
                          specificPermissions: ['correspondencia'],
                          label: 'Correspondencia',
                          icon: Icons.mail,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Accediendo a correspondencia')),
                            );
                          },
                        ),
                        PermissionAwareButton(
                          requiredPermission: 'controlAcceso',
                          specificPermissions: ['controlAcceso'],
                          label: 'Control Acceso',
                          icon: Icons.security,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Accediendo a control de acceso')),
                            );
                          },
                        ),
                        PermissionAwareButton(
                          requiredPermission: 'gastoComun',
                          specificPermissions: ['gastoComun'],
                          label: 'Gastos Comunes',
                          icon: Icons.attach_money,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Accediendo a gastos comunes')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GUÍA DE PERMISOS DISPONIBLES
// ============================================================================

/// PERMISOS DE PRIMER GRADO (en CondominioModel.gestionFunciones):
/// - 'correspondencia': Gestión de correspondencia
/// - 'controlAcceso': Control de acceso de visitantes
/// - 'gestionEstacionamientos': Gestión de estacionamientos
/// - 'espaciosComunes': Gestión de espacios comunes
/// - 'multas': Gestión de multas
/// - 'gastoComun': Gestión de gastos comunes
/// - 'chat': Sistema de chat
/// - 'reservasEspacios': Reservas de espacios comunes
/// - 'gestionTurnos': Gestión de turnos de trabajo

/// PERMISOS ESPECÍFICOS (en TrabajadorModel.funcionesDisponibles y ComiteModel.funcionesDisponibles):
/// Los mismos nombres que los permisos de primer grado, pero aplicados individualmente
/// a cada trabajador o miembro del comité.

/// REGLAS DE ACCESO:
/// 1. Si el permiso de primer grado está en false -> BLOQUEADO para todos
/// 2. Si el permiso de primer grado está en true:
///    - Administradores y Residentes: ACCESO COMPLETO
///    - Trabajadores y Comité: Solo si tienen el permiso específico en true

/// EJEMPLOS DE USO:
/// 
/// // Método 1: Widget completo
/// SimpleScreenNavigator(
///   primaryPermission: 'correspondencia',
///   specificPermissions: ['correspondencia'],
///   child: MyScreen(),
/// )
/// 
/// // Método 2: Verificación manual
/// final hasAccess = await PermissionService.hasPermission(
///   primaryPermission: 'correspondencia',
///   specificPermissions: ['correspondencia'],
/// );
/// 
/// // Método 3: Verificaciones específicas
/// final isAdmin = await PermissionService.isAdmin();
/// final canAccessFunction = await PermissionService.canAccessFunction('correspondencia');
/// final isEnabled = await PermissionService.isFunctionEnabled('correspondencia');