import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/trabajador_model.dart';
import '../../models/comite_model.dart';
import '../../services/firestore_service.dart';
import 'registro_diario/crear_registro_screen.dart';
import 'registro_diario/registros_del_dia_screen.dart';
import 'registro_diario/historial_registros_screen.dart';

class RegistroDiarioScreen extends StatefulWidget {
  final String condominioId;
  final UserModel? currentUser;

  const RegistroDiarioScreen({
    super.key,
    required this.condominioId,
    this.currentUser,
  });

  @override
  State<RegistroDiarioScreen> createState() => _RegistroDiarioScreenState();
}

class _RegistroDiarioScreenState extends State<RegistroDiarioScreen> {
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
      // Si no hay usuario actual o es administrador, permitir todo
      if (widget.currentUser == null || widget.currentUser!.tipoUsuario == UserType.administrador) {
        setState(() {
          _permisos = {
            'crearNuevoRegistro': true,
            'registrosDelDia': true,
            'historialRegistros': true,
          };
          _isLoading = false;
        });
        return;
      }

      // Verificar permisos para trabajador
      if (widget.currentUser!.tipoUsuario == UserType.trabajador) {
        final trabajador = await _firestoreService.getTrabajadorData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid,
        );
        if (trabajador != null) {
          setState(() {
            _permisos = {
              'crearNuevoRegistro': trabajador.funcionesDisponibles['crearNuevoRegistro'] ?? false,
              'registrosDelDia': trabajador.funcionesDisponibles['registrosDelDia'] ?? false,
              'historialRegistros': trabajador.funcionesDisponibles['historialRegistros'] ?? false,
            };
            _isLoading = false;
          });
        }
      }
      // Verificar permisos para comité
      else if (widget.currentUser!.tipoUsuario == UserType.comite ||
               (widget.currentUser!.tipoUsuario == UserType.residente && widget.currentUser!.esComite == true)) {
        final comite = await _firestoreService.getComiteData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid,
        );
        if (comite != null) {
          setState(() {
            _permisos = {
              'crearNuevoRegistro': comite.funcionesDisponibles['crearNuevoRegistro'] ?? false,
              'registrosDelDia': comite.funcionesDisponibles['registrosDelDia'] ?? false,
              'historialRegistros': comite.funcionesDisponibles['historialRegistros'] ?? false,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar permisos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Verificar si el usuario tiene al menos un permiso
    bool tieneAlgunPermiso = _permisos.values.any((permiso) => permiso == true);
    
    if (!tieneAlgunPermiso) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registro Diario'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No tienes permisos para acceder a las funciones de registro diario',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Diario'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Registros Diarios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administra los registros de actividades diarias del condominio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 3.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Crear Nuevo Registro
                  if (_permisos['crearNuevoRegistro'] == true)
                    _buildCard(
                      context: context,
                      title: 'Crear Nuevo Registro',
                      subtitle: 'Registrar una nueva actividad del día actual',
                      icon: Icons.add_circle_outline,
                      color: Colors.green.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrearRegistroScreen(
                              condominioId: widget.condominioId,
                            ),
                          ),
                        );
                      },
                    ),
                  // Registros del Día
                  if (_permisos['registrosDelDia'] == true)
                    _buildCard(
                      context: context,
                      title: 'Registros del Día',
                      subtitle: 'Ver todos los registros del día actual',
                      icon: Icons.today,
                      color: Colors.blue.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistrosDelDiaScreen(
                              condominioId: widget.condominioId,
                            ),
                          ),
                        );
                      },
                    ),
                  // Historial de Registros
                  if (_permisos['historialRegistros'] == true)
                    _buildCard(
                      context: context,
                      title: 'Historial de Registros',
                      subtitle: 'Consultar registros de días anteriores',
                      icon: Icons.history,
                      color: Colors.orange.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistorialRegistrosScreen(
                              condominioId: widget.condominioId,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}