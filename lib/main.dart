import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; // Agregar esta línea
import 'firebase_options.dart';
import 'screens/cuenta/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cuenta/login_screen.dart';
import 'screens/cuenta/register_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/residente/residente_screen.dart';
import 'screens/residente/r_seleccion_vivienda_screen.dart';
import 'screens/admin/comunicaciones/admin_notifications_screen.dart';
import 'screens/residente/comunicaciones/r_notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Agregar esta línea para inicializar datos de localización en español
  await initializeDateFormatting('es', null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comunidad Activa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Definir rutas nombradas
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  User? user = snapshot.data;
                  if (user == null) {
                    return const WelcomeScreen();
                  }
                  return const HomeScreen();
                }
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      // Manejar rutas con parámetros
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/admin':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AdminScreen(
                condominioId: args?['condominioId'] ?? '',
              ),
            );
          case '/residente':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ResidenteScreen(
                condominioId: args?['condominioId'] ?? '',
              ),
            );
          case '/residente/seleccion-vivienda':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ResidenteSeleccionViviendaScreen(
                condominioId: args?['condominioId'] ?? '',
                onViviendaSeleccionada: args?['onViviendaSeleccionada'],
              ),
            );
          case '/admin/notifications':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AdminNotificationsScreen(
                condominioId: args?['condominioId'] ?? '',
              ),
            );
          case '/residente/notifications':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ResidenteNotificationsScreen(
                condominioId: args?['condominioId'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text('Página no encontrada'),
                ),
              ),
            );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
