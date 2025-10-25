import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/trabajador_model.dart';
import '../../services/firestore_service.dart';
import 'configuracion_permisos_trabajador_screen.dart';

class GestionTrabajadoresScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionTrabajadoresScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<GestionTrabajadoresScreen> createState() => _GestionTrabajadoresScreenState();
}

class _GestionTrabajadoresScreenState extends State<GestionTrabajadoresScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TrabajadorModel> _trabajadores = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Obtener todos los trabajadores del condominio
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId!)
          .doc('usuarios')
          .collection('trabajadores')
          .get();

      List<TrabajadorModel> trabajadores = [];
      for (var doc in querySnapshot.docs) {
        if (doc.id != '_placeholder') {
          try {
            trabajadores.add(TrabajadorModel.fromFirestore(doc));
          } catch (e) {
            print('Error al procesar trabajador ${doc.id}: $e');
          }
        }
      }

      setState(() {
        _trabajadores = trabajadores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar trabajadores: $e';
        _isLoading = false;
      });
    }
  }

  String _getTipoTrabajadorDisplay(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return 'Conserje';
      case 'seguridad':
        return 'Seguridad';
      case 'limpieza':
        return 'Limpieza';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'jardineria':
        return 'Jardinería';
      case 'administracion':
        return 'Administración';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }

  Color _getColorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return Colors.blue;
      case 'seguridad':
        return Colors.red;
      case 'limpieza':
        return Colors.green;
      case 'mantenimiento':
        return Colors.orange;
      case 'jardineria':
        return Colors.teal;
      case 'administracion':
        return Colors.purple;
      case 'otro':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  IconData _getIconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return Icons.person_outline;
      case 'seguridad':
        return Icons.security;
      case 'limpieza':
        return Icons.cleaning_services;
      case 'mantenimiento':
        return Icons.build;
      case 'jardineria':
        return Icons.grass;
      case 'administracion':
        return Icons.business;
      case 'otro':
        return Icons.work;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Trabajadores'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage.isNotEmpty
                ? Center(
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
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarTrabajadores,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _trabajadores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay trabajadores registrados',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los trabajadores aparecerán aquí cuando se registren',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarTrabajadores,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _trabajadores.length,
                          itemBuilder: (context, index) {
                            final trabajador = _trabajadores[index];
                            return _buildTrabajadorCard(trabajador);
                          },
                        ),
                      ),
      ),
    );
  }

  // Definición de funciones disponibles (debe coincidir con configuracion_permisos_trabajador_screen.dart)
  final Map<String, Map<String, dynamic>> _funcionesInfo = {
    // Gestión de Correspondencia
    'configuracionCorrespondencias': {'categoria': 'Gestión de Correspondencia'},
    'ingresarCorrespondencia': {'categoria': 'Gestión de Correspondencia'},
    'correspondenciasActivas': {'categoria': 'Gestión de Correspondencia'},
    'historialCorrespondencias': {'categoria': 'Gestión de Correspondencia'},
    // Control de Acceso
    'gestionCamposAdicionales': {'categoria': 'Control de Acceso'},
    'gestionCamposActivos': {'categoria': 'Control de Acceso'},
    'crearRegistroAcceso': {'categoria': 'Control de Acceso'},
    'controlDiario': {'categoria': 'Control de Acceso'},
    'historialControlAcceso': {'categoria': 'Control de Acceso'},
    // Gestión de Estacionamientos
    'configuracionEstacionamientos': {'categoria': 'Gestión de Estacionamientos'},
    'gestionEstacionamientos': {'categoria': 'Gestión de Estacionamientos'},
    'historialEstacionamientos': {'categoria': 'Gestión de Estacionamientos'},
    // Gestión de Espacios Comunes
    'configuracionEspaciosComunes': {'categoria': 'Gestión de Espacios Comunes'},
    'gestionEspaciosComunes': {'categoria': 'Gestión de Espacios Comunes'},
    'historialReservas': {'categoria': 'Gestión de Espacios Comunes'},
    // Gestión de Gastos Comunes
    'configuracionGastosComunes': {'categoria': 'Gestión de Gastos Comunes'},
    'gestionGastosComunes': {'categoria': 'Gestión de Gastos Comunes'},
    'historialGastosComunes': {'categoria': 'Gestión de Gastos Comunes'},
    // Gestión de Multas
    'configuracionMultas': {'categoria': 'Gestión de Multas'},
    'gestionMultas': {'categoria': 'Gestión de Multas'},
    'historialMultas': {'categoria': 'Gestión de Multas'},
    // Gestión de Reclamos
    'configuracionReclamos': {'categoria': 'Gestión de Reclamos'},
    'gestionReclamos': {'categoria': 'Gestión de Reclamos'},
    'historialReclamos': {'categoria': 'Gestión de Reclamos'},
    // Gestión de Publicaciones
    'configuracionPublicaciones': {'categoria': 'Gestión de Publicaciones'},
    'gestionPublicaciones': {'categoria': 'Gestión de Publicaciones'},
    'historialPublicaciones': {'categoria': 'Gestión de Publicaciones'},
    // Registro Diario
    'configuracionRegistroDiario': {'categoria': 'Registro Diario'},
    'registroDiario': {'categoria': 'Registro Diario'},
    'historialRegistroDiario': {'categoria': 'Registro Diario'},
    // Bloqueo de Visitas
    'configuracionBloqueoVisitas': {'categoria': 'Bloqueo de Visitas'},
    'bloqueoVisitas': {'categoria': 'Bloqueo de Visitas'},
    'historialBloqueoVisitas': {'categoria': 'Bloqueo de Visitas'},
    // Gestión de Mensajes
    'chatEntreRes': {'categoria': 'Gestión de Mensajes'},
    'chatGrupal': {'categoria': 'Gestión de Mensajes'},
    'chatAdministrador': {'categoria': 'Gestión de Mensajes'},
    'chatConserjeria': {'categoria': 'Gestión de Mensajes'},
    'chatPrivado': {'categoria': 'Gestión de Mensajes'},
  };

  int _contarFuncionesActivas(TrabajadorModel trabajador) {
    // Contar solo las funciones activas que están definidas en _funcionesInfo
    // Excluir las funciones vacías que aparecen en la pantalla principal
    final funcionesVacias = [];
    
    return _funcionesInfo.keys
        .where((key) => !funcionesVacias.contains(key) && (trabajador.funcionesDisponibles[key] ?? false))
        .length;
  }

  Widget _buildTrabajadorCard(TrabajadorModel trabajador) {
    final color = _getColorPorTipo(trabajador.tipoTrabajador);
    final icono = _getIconoPorTipo(trabajador.tipoTrabajador);
    final tipoDisplay = _getTipoTrabajadorDisplay(trabajador.tipoTrabajador);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navegar a la pantalla de configuración de permisos
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracionPermisosTrabajadorScreen(
                currentUser: widget.currentUser,
                trabajador: trabajador,
              ),
            ),
          );
          
          // Si se realizaron cambios, recargar la lista
          if (result == true) {
            _cargarTrabajadores();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con icono del tipo de trabajador
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Información del trabajador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trabajador.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trabajador.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chip con el tipo de trabajador
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        trabajador.cargoEspecifico != null && 
                        trabajador.cargoEspecifico!.isNotEmpty &&
                        trabajador.tipoTrabajador.toLowerCase() == 'otro'
                            ? trabajador.cargoEspecifico!
                            : tipoDisplay,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de funciones activas
              Column(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_contarFuncionesActivas(trabajador)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'funciones',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}