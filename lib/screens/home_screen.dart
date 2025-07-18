import 'package:comunidad_activa/screens/admin/comunicaciones/admin_reclamos_screen.dart';
import 'package:comunidad_activa/screens/admin/correspondencia/correspondencias_screen.dart';
import 'package:comunidad_activa/screens/admin/settings_screen.dart';
import 'package:comunidad_activa/screens/residente/comunicaciones/r_reclamos_screen.dart';
import 'package:comunidad_activa/screens/residente/gastos_comunes_residente_screen.dart';
import 'package:comunidad_activa/screens/residente/residente_screen.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/residente_bloqueado_model.dart';
import '../services/auth_service.dart';
import '../services/bloqueo_service.dart';
import '../services/estacionamiento_service.dart';
import 'cuenta/welcome_screen.dart';
import '../models/user_model.dart';
import 'package:comunidad_activa/screens/admin/admin_screen.dart';
import 'package:comunidad_activa/screens/user_screens/comite_screen.dart';

import 'user_screens/trabajador_screen.dart';
import 'admin/vivienda/config_viviendas_screen.dart';
import 'admin/comunidad_screen.dart';
import 'admin/comunicaciones/multas_admin_screen.dart'; // Nueva importación
import 'admin/gastosComunes/gastos_comunes_screen.dart';
import 'admin/estacionamientos/estacionamientos_admin_screen.dart';
import 'residente/comunicaciones/r_multas_screen.dart';
import 'residente/r_config_screen.dart'; // Nueva importación
import 'residente/comunicaciones/mensajes_residente_screen.dart';
import 'residente/comunicaciones/publicaciones_residente_screen.dart';
import 'admin/comunicaciones/mensajes_admin_screen.dart';
import 'admin/comunicaciones/crear_publicacion_screen.dart';
import 'admin/comunicaciones/gestion_publicaciones_screen.dart';
import 'admin/espaciosComunes/espacios_comunes_screen.dart';
import 'residente/espacios_comunes_residente_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  bool _estacionamientosActivos = false;

  @override
  void initState() {
    super.initState();
    _verificarEstacionamientos();
  }

  Future<void> _verificarEstacionamientos() async {
    final authService = AuthService();
    final user = await authService.getCurrentUserData();
    if (user != null && user.condominioId != null) {
      final activos = await _estacionamientoService.verificarEstacionamientosActivos(user.condominioId!);
      if (mounted) {
        setState(() {
          _estacionamientosActivos = activos;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final bloqueoService = BloqueoService();

    return FutureBuilder(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Verificar si el usuario residente está bloqueado
          if (user.tipoUsuario == UserType.residente) {
            return FutureBuilder(
              future: bloqueoService.verificarCorreoBloqueado(user.condominioId.toString(), user.email),
              builder: (context, blockSnapshot) {
                if (blockSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                // Si el usuario está bloqueado, mostrar pantalla de bloqueo
                if (blockSnapshot.hasData && blockSnapshot.data != null) {
                  final usuarioBloqueado = blockSnapshot.data!;
                  return _buildBlockedUserScreen(context, usuarioBloqueado, authService);
                }
                
                // Si no está bloqueado, continuar normalmente
                return _buildNormalScreen(context, user, authService);
              },
            );
          }
          
          // Para administradores y otros tipos de usuario, continuar normalmente
          return _buildNormalScreen(context, user, authService);
        }

        // Si no hay datos de usuario, mostrar pantalla de error mejorada
        return _buildNoUserDataScreen(context, authService);
      },
    );
  }
  
  Widget _buildBlockedUserScreen(BuildContext context, dynamic usuarioBloqueado, AuthService authService) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                color: Colors.red,
                size: 80.0,
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Cuenta Bloqueada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                'Su cuenta ha sido bloqueada por el administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Motivo del bloqueo:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      usuarioBloqueado.motivo ?? 'No se especificó un motivo',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0),
              ElevatedButton.icon(
                onPressed: () {
                  authService.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: 18.0),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Para más información, contacte al administrador del condominio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNormalScreen(BuildContext context, UserModel user, AuthService authService) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad Activa'),
        backgroundColor: user.tipoUsuario == UserType.administrador
            ? Colors.blue.shade600
            : Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context, user, authService),
      body: _buildBody(context, user),
    );
  }
  
  Widget _buildNoUserDataScreen(BuildContext context, AuthService authService) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 80.0,
              ),
              const SizedBox(height: 20.0),
              const Text(
                '¡Ups! No se encontraron datos de usuario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Parece que tu sesión ha expirado o hubo un problema. Por favor, inicia sesión nuevamente para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30.0),
              ElevatedButton.icon(
                onPressed: () {
                  authService.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Volver a iniciar sesión',
                  style: TextStyle(fontSize: 18.0),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Si el problema persiste, no dudes en contactar al administrador del sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    UserModel user,
    AuthService authService,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: user.tipoUsuario == UserType.administrador
                  ? Colors.blue.shade600
                  : Colors.green.shade600,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    user.tipoUsuario == UserType.administrador
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    size: 40,
                    color: user.tipoUsuario == UserType.administrador
                        ? Colors.blue.shade600
                        : Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.nombre,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Opción de inicio para todos los usuarios
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context); // Cerrar el drawer
            },
          ),

          // Opciones específicas para administradores
          if (user.tipoUsuario == UserType.administrador) ...[            
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Comunidad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ComunidadScreen(condominioId: user.condominioId!),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Mensajes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MensajesAdminScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Gestión de Multas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MultasAdminScreen(currentUser: user,),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Gestión de Publicaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GestionPublicacionesScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Gastos Comunes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GastosComunesScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para administradores - Gestión de Reclamos
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Gestión de Reclamos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminReclamosScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para administradores - Espacios Comunes
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Espacios Comunes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EspaciosComunesScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para administradores - Correspondencias
            ListTile(
              leading: const Icon(Icons.mail),
              title: const Text('Correspondencias'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CorrespondenciasScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para administradores - Estacionamientos (solo si están activos)
             if (_estacionamientosActivos)
               ListTile(
                 leading: const Icon(Icons.local_parking),
                 title: const Text('Estacionamientos'),
                 onTap: () {
                   Navigator.pop(context);
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) =>
                           EstacionamientosAdminScreen(condominioId: user.condominioId!),
                     ),
                   );
                 },
               ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuraciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(condominioId: user.condominioId!),
                  ),
                );
              },
            ),
          ],

          // Opciones específicas para residentes
          if (user.tipoUsuario == UserType.residente) ...[            
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Mensajes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MensajesResidenteScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Mis Gastos Comunes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GastosComunesResidenteScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Mis Multas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultasResidenteScreen(currentUser: user,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Publicaciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicacionesResidenteScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para residentes - Mis Reclamos
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Mis Reclamos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReclamosResidenteScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para residentes - Espacios Comunes
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Espacios Comunes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EspaciosComunesResidenteScreen(currentUser: user),
                  ),
                );
              },
            ),
            // Nueva opción para residentes - Estacionamientos (solo si están activos)
              if (_estacionamientosActivos)
                ListTile(
                  leading: const Icon(Icons.local_parking),
                  title: const Text('Estacionamientos'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar EstacionamientosResidenteScreen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo'),
                      ),
                    );
                  },
                ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ResidenteConfigScreen(condominioId: user.condominioId!),
                  ),
                );
              },
            ),
          ],

          const Divider(),
          // Opción de cerrar sesión para todos los usuarios
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    // Verificar si el usuario tiene un condominio asignado
    if (user.condominioId == null) {
      return const Center(
        child: Text(
          'No tienes un condominio asignado. Contacta al administrador.',
        ),
      );
    }

    // Mostrar contenido según el tipo de usuario (sin AppBar ni Drawer adicionales)
    switch (user.tipoUsuario) {
      case UserType.administrador:
        return _buildAdminContent(user.condominioId!);
      case UserType.residente:
        // Verificar si es miembro del comité
        if (user.esComite == true) {
          return _buildComiteContent(user.condominioId!);
        }
        return _buildResidenteContent(user.condominioId!);
      case UserType.trabajador:
        return _buildTrabajadorContent(user.condominioId!);
      default:
        return const Center(child: Text('Tipo de usuario no reconocido'));
    }
  }

  Widget _buildAdminContent(String condominioId) {
    // Contenido del AdminScreen sin AppBar ni Drawer
    return AdminScreen(condominioId: condominioId);
  }

  Widget _buildComiteContent(String condominioId) {
    // Contenido del ComiteScreen sin AppBar ni Drawer
    return ComiteScreen(condominioId: condominioId);
  }

  Widget _buildResidenteContent(String condominioId) {
    // Contenido del ResidenteScreen sin AppBar ni Drawer
    return ResidenteScreen(condominioId: condominioId);
  }

  Widget _buildTrabajadorContent(String condominioId) {
    // Contenido del TrabajadorScreen sin AppBar ni Drawer
    return TrabajadorScreen(condominioId: condominioId);
  }
}
