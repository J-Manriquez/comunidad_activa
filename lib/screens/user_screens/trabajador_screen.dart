import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trabajador_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/test/screen_navigator_widget.dart';
import '../admin/correspondencia/correspondencias_activas_screen.dart';
import '../admin/correspondencia/configuracion_correspondencia_screen.dart';
import '../admin/correspondencia/ingresar_correspondencia_screen.dart';
import '../admin/correspondencia/historial_correspondencias_screen.dart';
import '../admin/controlAcceso/gestion_campos_adicionales_screen.dart';
import '../admin/controlAcceso/campos_activos_screen.dart';
import '../admin/controlAcceso/formulario_control_acceso_screen.dart';
import '../admin/controlAcceso/control_diario_screen.dart';
import '../admin/controlAcceso/historial_control_acceso_screen.dart';
import '../admin/controlAcceso/control_acceso_screen.dart';
import '../admin/estacionamientos/estacionamientos_admin_screen.dart';
import '../admin/estacionamientos/configuracion_estacionamientos_screen.dart';
import '../admin/estacionamientos/solicitudes_estacionamiento_admin_screen.dart';
import '../admin/estacionamientos/lista_estacionamientos_screen.dart';
import '../admin/estacionamientos/estacionamientos_visitas_screen.dart';
import '../admin/espaciosComunes/espacios_comunes_screen.dart';
import '../admin/espaciosComunes/lista_espacios_comunes_screen.dart';
import '../admin/espaciosComunes/solicitudes_reservas_screen.dart';
import '../admin/espaciosComunes/revisiones_post_uso_screen.dart';
import '../admin/espaciosComunes/solicitudes_rechazadas_screen.dart';
import '../admin/espaciosComunes/historial_revisiones_screen.dart';
import '../admin/gastosComunes/gastos_comunes_screen.dart';
import '../admin/gastosComunes/gasto_detalle_screen.dart';
import '../admin/gastosComunes/listas_porcentajes_screen.dart';
import '../../models/gasto_comun_model.dart';
import '../admin/comunicaciones/admin_reclamos_screen.dart';
import '../admin/comunicaciones/gestion_tipos_reclamos_screen.dart';
import '../admin/comunicaciones/gestion_multas_screen.dart';
import '../admin/comunicaciones/historial_multas_screen.dart';
import '../admin/comunicaciones/multas_admin_screen.dart';
import '../admin/comunidad_screen.dart';
import '../admin/comunicaciones/gestion_publicaciones_screen.dart';
import '../admin/comunicaciones/publicaciones_trabajadores_screen.dart';
import '../admin/comunicaciones/mensajes_admin_screen.dart';
import '../admin/bloqueo_visitas_screen.dart';
import '../admin/visitasBloqueadas/crear_bloqueo_visita_screen.dart';
import '../admin/registro_diario/crear_registro_screen.dart';
import '../admin/registro_diario/registros_del_dia_screen.dart';
import '../admin/registro_diario/historial_registros_screen.dart';
import '../../models/user_model.dart';

class TrabajadorScreen extends StatefulWidget {
  final String condominioId;

  const TrabajadorScreen({super.key, required this.condominioId});

  @override
  State<TrabajadorScreen> createState() => _TrabajadorScreenState();
}

class _TrabajadorScreenState extends State<TrabajadorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  TrabajadorModel? _trabajador;
  UserModel? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosTrabajador();
  }

  Future<void> _cargarDatosTrabajador() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Cargar datos del trabajador
      final trabajadorDoc = await FirebaseFirestore.instance
          .collection(widget.condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .doc(user.uid)
          .get();

      if (!trabajadorDoc.exists) {
        throw Exception('Trabajador no encontrado');
      }

      _trabajador = TrabajadorModel.fromFirestore(trabajadorDoc);

      // Crear UserModel para compatibilidad con pantallas existentes
      _currentUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        nombre: _trabajador!.nombre,
        tipoUsuario: UserType.trabajador,
        condominioId: _trabajador!.condominioId,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatosTrabajador,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_trabajador == null || _currentUser == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos del trabajador'),
      );
    }

    // Pantalla principal con widget de navegación
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del trabajador
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work,
                          color: Colors.orange.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _trabajador!.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text('Email: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(child: Text(_trabajador!.email)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.badge, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text('Tipo: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(child: Text(_trabajador!.tipoTrabajador)),
                      ],
                    ),
                    if (_trabajador!.cargoEspecifico != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.work_outline, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Cargo: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Expanded(child: Text(_trabajador!.cargoEspecifico!)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.orange.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trabajador',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Widget de navegación de pantallas
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navegación de pantallas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: ScreenNavigatorWidget(
                        currentUser: _currentUser!,
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