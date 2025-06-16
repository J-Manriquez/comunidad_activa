import 'package:comunidad_activa/screens/admin/settings_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import '../models/user_model.dart';
import 'admin/admin_screen.dart';
import 'user_screens/comite_screen.dart';
import 'user_screens/residente_screen.dart';
import 'user_screens/trabajador_screen.dart';
import 'admin/viviendas_screen.dart'; // Importar la nueva pantalla de configuración

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
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
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('Comunidad Activa'),
            ),
            drawer: _buildDrawer(context, user, authService),
            body: _buildBody(context, user),
          );
        }
        
        return const Scaffold(
          body: Center(child: Text('No se encontraron datos del usuario')),
        );
      },
    );
  }
  
  Widget _buildDrawer(BuildContext context, UserModel user, AuthService authService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
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
          // Opción de configuración solo para administradores
          if (user.tipoUsuario == UserType.administrador)
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context); // Cerrar el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(condominioId: user.condominioId!),
                  ),
                );
              },
            ),
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
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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
        child: Text('No tienes un condominio asignado. Contacta al administrador.'),
      );
    }
    
    // Mostrar pantalla según el tipo de usuario
    switch (user.tipoUsuario) {
      case UserType.administrador:
        return AdminScreen(condominioId: user.condominioId!);
      case UserType.residente:
        // Verificar si es miembro del comité
        if (user.esComite == true) {
          return ComiteScreen(condominioId: user.condominioId!);
        }
        return ResidenteScreen(condominioId: user.condominioId!);
      case UserType.trabajador:
        return TrabajadorScreen(condominioId: user.condominioId!);
      default:
        return const Center(
          child: Text('Tipo de usuario no reconocido'),
        );
    }
  }
}