import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/trabajador_model.dart';
import '../../../models/comite_model.dart';
import '../../../services/firestore_service.dart';
import 'ingresar_correspondencia_screen.dart';
import 'configuracion_correspondencia_screen.dart';
import 'correspondencias_activas_screen.dart';
import 'historial_correspondencias_screen.dart';

class CorrespondenciasScreen extends StatefulWidget {
  final UserModel currentUser;

  const CorrespondenciasScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorrespondenciasScreen> createState() => _CorrespondenciasScreenState();
}

class _CorrespondenciasScreenState extends State<CorrespondenciasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, bool> _permisos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (widget.currentUser.tipoUsuario == UserType.administrador) {
        // El administrador tiene todos los permisos
        _permisos = {
          'configuracionCorrespondencias': true,
          'ingresarCorrespondencia': true,
          'correspondenciasActivas': true,
          'historialCorrespondencias': true,
        };
      } else if (widget.currentUser.tipoUsuario == UserType.trabajador) {
        // Cargar permisos del trabajador
        final trabajador = await _firestoreService.getTrabajadorData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        );
        if (trabajador != null) {
          _permisos = {
            'configuracionCorrespondencias': trabajador.funcionesDisponibles['configuracionCorrespondencias'] ?? false,
            'ingresarCorrespondencia': trabajador.funcionesDisponibles['ingresarCorrespondencia'] ?? false,
            'correspondenciasActivas': trabajador.funcionesDisponibles['correspondenciasActivas'] ?? false,
            'historialCorrespondencias': trabajador.funcionesDisponibles['historialCorrespondencias'] ?? false,
          };
        }
      } else if (widget.currentUser.tipoUsuario == UserType.residente && widget.currentUser.esComite == true) {
        // Cargar permisos del comité
        final comite = await _firestoreService.getComiteData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        );
        if (comite != null) {
          _permisos = {
            'configuracionCorrespondencias': comite.funcionesDisponibles['configuracionCorrespondencias'] ?? false,
            'ingresarCorrespondencia': comite.funcionesDisponibles['ingresarCorrespondencia'] ?? false,
            'correspondenciasActivas': comite.funcionesDisponibles['correspondenciasActivas'] ?? false,
            'historialCorrespondencias': comite.funcionesDisponibles['historialCorrespondencias'] ?? false,
          };
        }
      }
    } catch (e) {
      print('Error al cargar permisos: $e');
      // En caso de error, no mostrar ningún permiso
      _permisos = {
        'configuracionCorrespondencias': false,
        'ingresarCorrespondencia': false,
        'correspondenciasActivas': false,
        'historialCorrespondencias': false,
      };
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar StreamBuilder para actualizaciones en tiempo real de permisos
    if (widget.currentUser.tipoUsuario == UserType.trabajador) {
      return StreamBuilder<TrabajadorModel?>(
        stream: _firestoreService.getTrabajadorStream(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          Map<String, bool> permisos = {};
          if (snapshot.hasData && snapshot.data != null) {
            final trabajador = snapshot.data!;
            permisos = {
              'configuracionCorrespondencias': trabajador.funcionesDisponibles['configuracionCorrespondencias'] ?? false,
              'ingresarCorrespondencia': trabajador.funcionesDisponibles['ingresarCorrespondencia'] ?? false,
              'correspondenciasActivas': trabajador.funcionesDisponibles['correspondenciasActivas'] ?? false,
              'historialCorrespondencias': trabajador.funcionesDisponibles['historialCorrespondencias'] ?? false,
            };
          }

          return _buildCorrespondenciasScreen(permisos);
        },
      );
    } else if (widget.currentUser.tipoUsuario == UserType.residente && widget.currentUser.esComite == true) {
      return StreamBuilder<ComiteModel?>(
        stream: _firestoreService.getComiteStream(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          Map<String, bool> permisos = {};
          if (snapshot.hasData && snapshot.data != null) {
            final comite = snapshot.data!;
            permisos = {
              'configuracionCorrespondencias': comite.funcionesDisponibles['configuracionCorrespondencias'] ?? false,
              'ingresarCorrespondencia': comite.funcionesDisponibles['ingresarCorrespondencia'] ?? false,
              'correspondenciasActivas': comite.funcionesDisponibles['correspondenciasActivas'] ?? false,
              'historialCorrespondencias': comite.funcionesDisponibles['historialCorrespondencias'] ?? false,
            };
          }

          return _buildCorrespondenciasScreen(permisos);
        },
      );
    } else {
      // Para administradores, usar permisos completos
      final permisos = {
        'configuracionCorrespondencias': true,
        'ingresarCorrespondencia': true,
        'correspondenciasActivas': true,
        'historialCorrespondencias': true,
      };
      return _buildCorrespondenciasScreen(permisos);
    }
  }

  Widget _buildCorrespondenciasScreen(Map<String, bool> permisos) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondencias'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Solo mostrar el botón de agregar si tiene permiso para ingresar correspondencia
          if (permisos['ingresarCorrespondencia'] == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IngresarCorrespondenciaScreen(
                      condominioId: widget.currentUser.condominioId!,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card de configuración (solo visible si tiene permiso)
            if (permisos['configuracionCorrespondencias'] == true) ...[
              Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Colors.blue.shade600,
                    size: 32,
                  ),
                  title: const Text(
                    'Configuración de Correspondencias',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Gestionar configuraciones del sistema de correspondencias',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfiguracionCorrespondenciaScreen(
                          condominioId: widget.currentUser.condominioId!,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Cards para correspondencias activas e historial
            Expanded(
              child: _buildCorrespondenciasCards(permisos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrespondenciasCards(Map<String, bool> permisos) {
    List<Widget> cards = [];
    
    // Card de correspondencias activas (solo si tiene permiso)
    if (permisos['correspondenciasActivas'] == true) {
      cards.add(
        Expanded(
          child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CorrespondenciasActivasScreen(
                      condominioId: widget.currentUser.condominioId!,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail,
                      size: 64,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Correspondencias Activas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ver correspondencias pendientes de entrega',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Agregar separador si hay más de una card
    if (cards.isNotEmpty && permisos['historialCorrespondencias'] == true) {
      cards.add(const SizedBox(height: 16));
    }
    
    // Card de historial de correspondencias (solo si tiene permiso)
    if (permisos['historialCorrespondencias'] == true) {
      cards.add(
        Expanded(
          child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialCorrespondenciasScreen(
                      condominioId: widget.currentUser.condominioId!,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Historial de Correspondencias',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ver correspondencias ya entregadas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Si no hay cards disponibles, mostrar mensaje
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin permisos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes permisos para acceder a las funciones de correspondencia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(children: cards);
  }
}