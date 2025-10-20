import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/trabajador_model.dart';
import '../../../models/comite_model.dart';
import '../../../services/firestore_service.dart';
import 'gestion_campos_adicionales_screen.dart';
import 'campos_activos_screen.dart';
import 'control_diario_screen.dart';
import 'historial_control_acceso_screen.dart';

class ControlAccesoScreen extends StatefulWidget {
  final UserModel? currentUser;

  const ControlAccesoScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  State<ControlAccesoScreen> createState() => _ControlAccesoScreenState();
}

class _ControlAccesoScreenState extends State<ControlAccesoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, bool> _permisos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    if (widget.currentUser == null) return;

    try {
      // Verificar si es trabajador
      if (widget.currentUser!.tipoUsuario == UserType.trabajador) {
        final trabajador = await _firestoreService.getTrabajadorData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid,
        );
        if (trabajador != null) {
          setState(() {
            _permisos = {
              'gestionCamposAdicionales': trabajador.funcionesDisponibles['gestionCamposAdicionales'] ?? false,
              'gestionCamposActivos': trabajador.funcionesDisponibles['gestionCamposActivos'] ?? false,
              'crearRegistroAcceso': trabajador.funcionesDisponibles['crearRegistroAcceso'] ?? false,
              'controlDiario': trabajador.funcionesDisponibles['controlDiario'] ?? false,
              'historialControlAcceso': trabajador.funcionesDisponibles['historialControlAcceso'] ?? false,
            };
            _isLoading = false;
          });
        }
      }
      // Verificar si es comité
      else if (widget.currentUser!.tipoUsuario == UserType.comite ||
               (widget.currentUser!.tipoUsuario == UserType.residente && widget.currentUser!.esComite == true)) {
        final comite = await _firestoreService.getComiteData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid,
        );
        if (comite != null) {
          setState(() {
            _permisos = {
              'gestionCamposAdicionales': comite.funcionesDisponibles['gestionCamposAdicionales'] ?? false,
              'gestionCamposActivos': comite.funcionesDisponibles['gestionCamposActivos'] ?? false,
              'crearRegistroAcceso': comite.funcionesDisponibles['crearRegistroAcceso'] ?? false,
              'controlDiario': comite.funcionesDisponibles['controlDiario'] ?? false,
              'historialControlAcceso': comite.funcionesDisponibles['historialControlAcceso'] ?? false,
            };
            _isLoading = false;
          });
        }
      }
      // Si es administrador, permitir todo
      else if (widget.currentUser!.tipoUsuario == UserType.administrador) {
        setState(() {
          _permisos = {
            'gestionCamposAdicionales': true,
            'gestionCamposActivos': true,
            'crearRegistroAcceso': true,
            'controlDiario': true,
            'historialControlAcceso': true,
          };
          _isLoading = false;
        });
      }
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
        appBar: AppBar(
          title: const Text('Control de Acceso'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Acceso'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Control de Acceso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administra el sistema de control de acceso del condominio',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      // Gestión de Campos Adicionales
                      if (_permisos['gestionCamposAdicionales'] == true)
                        _buildNavigationCard(
                          context,
                          title: 'Gestión de Campos\nAdicionales',
                          subtitle: 'Configura campos personalizados',
                          icon: Icons.add_box_outlined,
                          color: Colors.green,
                          onTap: () {
                            if (widget.currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GestionCamposAdicionalesScreen(
                                    currentUser: widget.currentUser!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      // Campos Activos
                      if (_permisos['gestionCamposActivos'] == true)
                        _buildNavigationCard(
                          context,
                          title: 'Campos Activos',
                          subtitle: 'Activa/desactiva campos del formulario',
                          icon: Icons.toggle_on_outlined,
                          color: Colors.orange,
                          onTap: () {
                            if (widget.currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CamposActivosScreen(
                                    currentUser: widget.currentUser!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      // Control Diario
                      if (_permisos['controlDiario'] == true || _permisos['crearRegistroAcceso'] == true)
                        _buildNavigationCard(
                          context,
                          title: 'Control Diario',
                          subtitle: 'Registra ingresos y salidas',
                          icon: Icons.today_outlined,
                          color: Colors.blue,
                          onTap: () {
                            if (widget.currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ControlDiarioScreen(
                                    currentUser: widget.currentUser!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: Usuario no válido'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      // Historial de Control de Acceso
                      if (_permisos['historialControlAcceso'] == true)
                        _buildNavigationCard(
                          context,
                          title: 'Historial de\nControl de Acceso',
                          subtitle: 'Consulta registros históricos',
                          icon: Icons.history_outlined,
                          color: Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistorialControlAccesoScreen(currentUser: widget.currentUser),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}