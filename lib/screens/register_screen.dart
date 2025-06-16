import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _condominioNombreController = TextEditingController();
  final _condominioDireccionController = TextEditingController();
  final _cargoEspecificoController = TextEditingController();
  
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  UserType _tipoUsuario = UserType.residente;
  String _tipoTrabajador = 'conserje';
  bool _isLoading = false;
  String? _errorMessage;
  bool _mostrarCampoCargoEspecifico = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _codigoController.dispose();
    _condominioNombreController.dispose();
    _condominioDireccionController.dispose();
    _cargoEspecificoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Registrar usuario en Firebase Auth
        UserCredential userCredential = await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Guardar información adicional según el tipo de usuario
        if (userCredential.user != null) {
          String uid = userCredential.user!.uid;
          String email = _emailController.text.trim();
          String nombre = _nombreController.text.trim();
          
          // Crear modelo de usuario general
          UserModel user = UserModel(
            uid: uid,
            email: email,
            nombre: nombre,
            tipoUsuario: _tipoUsuario,
          );
          
          // Guardar datos según el tipo de usuario
          switch (_tipoUsuario) {
            case UserType.administrador:
              // Crear condominio y guardar datos del administrador
              String condominioId = await _firestoreService.createCondominio(
                nombre: _condominioNombreController.text.trim(),
                direccion: _condominioDireccionController.text.trim(),
                adminNombre: nombre,
                adminEmail: email,
              );
              
              // Actualizar el modelo de usuario con el ID del condominio
              user = UserModel(
                uid: uid,
                email: email,
                nombre: nombre,
                tipoUsuario: _tipoUsuario,
                condominioId: condominioId,
              );
              break;
              
            case UserType.residente:
              // Registrar residente
              await _firestoreService.registerResidente(
                nombre: nombre,
                email: email,
                codigo: _codigoController.text.trim(),
                esComite: false, // Por ahora, todos son residentes normales
              );
              
              // Actualizar el modelo de usuario con el ID del condominio
              user = UserModel(
                uid: uid,
                email: email,
                nombre: nombre,
                tipoUsuario: _tipoUsuario,
                condominioId: _codigoController.text.trim(),
              );
              break;
              
            case UserType.trabajador:
              // Registrar trabajador
              await _firestoreService.registerTrabajador(
                nombre: nombre,
                email: email,
                codigo: _codigoController.text.trim(),
                tipoTrabajador: _tipoTrabajador,
                cargoEspecifico: _tipoTrabajador == 'otro' ? _cargoEspecificoController.text.trim() : null,
              );
              
              // Actualizar el modelo de usuario con el ID del condominio
              user = UserModel(
                uid: uid,
                email: email,
                nombre: nombre,
                tipoUsuario: _tipoUsuario,
                condominioId: _codigoController.text.trim(),
              );
              break;
          }
          
          // Navegar a la pantalla principal después de registrarse
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campos comunes para todos los usuarios
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su correo electrónico';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                
                // Selector de tipo de usuario
                DropdownButtonFormField<UserType>(
                  value: _tipoUsuario,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de usuario',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserType.administrador,
                      child: Text('Administrador'),
                    ),
                    DropdownMenuItem(
                      value: UserType.residente,
                      child: Text('Residente'),
                    ),
                    DropdownMenuItem(
                      value: UserType.trabajador,
                      child: Text('Trabajador'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoUsuario = value!;
                      // Resetear el campo de cargo específico
                      _mostrarCampoCargoEspecifico = false;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                
                // Campos específicos según el tipo de usuario
                if (_tipoUsuario == UserType.residente) ...[  
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código de condominio',
                      border: OutlineInputBorder(),
                      helperText: 'Solicite este código a su administrador o al comité del condominio',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el código de condominio';
                      }
                      return null;
                    },
                  ),
                ] else if (_tipoUsuario == UserType.administrador) ...[  
                  TextFormField(
                    controller: _condominioNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del condominio',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del condominio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _condominioDireccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del condominio',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la dirección del condominio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'La prueba de uso se activa automáticamente y permite dos semanas de uso y pruebas para sus trabajadores y residentes. Para contratar el servicio, debe solicitarlo desde la pantalla de configuraciones.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ] else if (_tipoUsuario == UserType.trabajador) ...[  
                  DropdownButtonFormField<String>(
                    value: _tipoTrabajador,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de trabajador',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'conserje',
                        child: Text('Conserje'),
                      ),
                      DropdownMenuItem(
                        value: 'guardia',
                        child: Text('Guardia'),
                      ),
                      DropdownMenuItem(
                        value: 'personalAseo',
                        child: Text('Personal de aseo'),
                      ),
                      DropdownMenuItem(
                        value: 'otro',
                        child: Text('Otro'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoTrabajador = value!;
                        _mostrarCampoCargoEspecifico = value == 'otro';
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (_mostrarCampoCargoEspecifico) ...[  
                    TextFormField(
                      controller: _cargoEspecificoController,
                      decoration: const InputDecoration(
                        labelText: 'Cargo específico',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_mostrarCampoCargoEspecifico && (value == null || value.isEmpty)) {
                          return 'Por favor ingrese su cargo específico';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código proporcionado por el administrador',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el código proporcionado';
                      }
                      return null;
                    },
                  ),
                ],
                
                if (_errorMessage != null) ...[  
                  const SizedBox(height: 16.0),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Crear Usuario', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}