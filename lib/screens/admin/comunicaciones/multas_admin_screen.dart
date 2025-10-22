import 'package:comunidad_activa/screens/admin/comunicaciones/gestion_multas_screen.dart';
import 'package:comunidad_activa/screens/admin/comunicaciones/historial_multas_screen.dart';
import 'package:comunidad_activa/screens/admin/comunidad_screen.dart';
import 'package:flutter/material.dart';
import '../../../services/multa_service.dart';
import '../../../models/user_model.dart';
import '../../../models/comite_model.dart';
import '../../../models/trabajador_model.dart';
import '../../../services/firestore_service.dart';


class MultasAdminScreen extends StatefulWidget {
  final UserModel currentUser;

  const MultasAdminScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<MultasAdminScreen> createState() => _MultasAdminScreenState();
}

class _MultasAdminScreenState extends State<MultasAdminScreen> {
  final MultaService _multaService = MultaService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _tienePermisoCrearMulta = false;
  bool _tienePermisoGestionadorMultas = false;
  bool _tienePermisoHistorialMultas = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    try {
      if (widget.currentUser.tipoUsuario == UserType.administrador) {
        // Los administradores tienen todos los permisos
        setState(() {
          _tienePermisoCrearMulta = true;
          _tienePermisoGestionadorMultas = true;
          _tienePermisoHistorialMultas = true;
          _isLoading = false;
        });
      } else if (widget.currentUser.tipoUsuario == UserType.trabajador) {
        final trabajador = await _firestoreService.getTrabajadorData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid
        );
        
        if (trabajador != null) {
          setState(() {
            _tienePermisoCrearMulta = trabajador.funcionesDisponibles['crearMulta'] == true;
            _tienePermisoGestionadorMultas = trabajador.funcionesDisponibles['gestionadorMultas'] == true;
            _tienePermisoHistorialMultas = trabajador.funcionesDisponibles['historialMultas'] == true;
            _isLoading = false;
          });
        }
      } else if (widget.currentUser.tipoUsuario == UserType.comite || 
                 (widget.currentUser.tipoUsuario == UserType.residente && widget.currentUser.esComite == true)) {
        final comite = await _firestoreService.getComiteData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid
        );
        
        if (comite != null) {
          setState(() {
            _tienePermisoCrearMulta = comite.funcionesDisponibles['crearMulta'] == true;
            _tienePermisoGestionadorMultas = comite.funcionesDisponibles['gestionadorMultas'] == true;
            _tienePermisoHistorialMultas = comite.funcionesDisponibles['historialMultas'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al verificar permisos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Multas'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_tienePermisoCrearMulta)
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.add_circle, color: Colors.green[700]),
                        title: const Text('Crear Multa a Residente'),
                        subtitle: const Text('Aplicar multa a un residente específico'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComunidadScreen(
                                condominioId: widget.currentUser.condominioId!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_tienePermisoCrearMulta) const SizedBox(height: 16),
                  if (_tienePermisoGestionadorMultas)
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.settings, color: Colors.blue[700]),
                        title: const Text('Gestionador de Multas'),
                        subtitle: const Text('Configurar tipos y valores de multas'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GestionMultasScreen(
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_tienePermisoGestionadorMultas) const SizedBox(height: 16),
                  if (_tienePermisoHistorialMultas)
                    Card(
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.history, color: Colors.orange[700]),
                        title: const Text('Historial de Multas'),
                        subtitle: const Text('Ver todas las multas creadas'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistorialMultasScreen(
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Mostrar mensaje si no tiene permisos
                  if (!_tienePermisoCrearMulta && !_tienePermisoGestionadorMultas && !_tienePermisoHistorialMultas)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tienes permisos para acceder a las funciones de gestión de multas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
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