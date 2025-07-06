import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _quickLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comunidad Activa',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),
              const Text(
                'Bienvenido a la aplicación para la gestión de tu condominio',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16.0),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Registrarse', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 32.0),
              
              // Sección de acceso rápido
              const Divider(),
              const SizedBox(height: 16.0),
              const Text(
                'Acceso Rápido de Prueba',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              
              // Botón para administrador
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _quickLogin('a@a.cl', '000000'),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Administrador (a@a.cl)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              const SizedBox(height: 12.0),
              
              // Botón para residente
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _quickLogin('c@c.cl', '000000'),
                icon: const Icon(Icons.home),
                label: const Text('Residente (c@c.cl)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              
              if (_isLoading) ...[
                const SizedBox(height: 16.0),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}