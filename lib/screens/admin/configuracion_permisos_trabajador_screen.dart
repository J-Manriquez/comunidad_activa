import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/trabajador_model.dart';
import '../../services/firestore_service.dart';

class ConfiguracionPermisosTrabajadorScreen extends StatefulWidget {
  final UserModel currentUser;
  final TrabajadorModel trabajador;

  const ConfiguracionPermisosTrabajadorScreen({
    super.key,
    required this.currentUser,
    required this.trabajador,
  });

  @override
  State<ConfiguracionPermisosTrabajadorScreen> createState() =>
      _ConfiguracionPermisosTrabajadorScreenState();
}

class _ConfiguracionPermisosTrabajadorScreenState
    extends State<ConfiguracionPermisosTrabajadorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Map<String, bool> _funcionesDisponibles;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Definición de funciones disponibles con sus descripciones
  final Map<String, Map<String, dynamic>> _funcionesInfo = {
    // Gestión de Correspondencia - Sub-funciones
    'configuracionCorrespondencias': {
      'titulo': 'Configuración de Correspondencias',
      'descripcion': 'Gestionar configuraciones del sistema de correspondencias',
      'icono': Icons.settings,
      'color': Colors.blue,
      'categoria': 'Gestión de Correspondencia',
    },
    'ingresarCorrespondencia': {
      'titulo': 'Ingresar Correspondencia',
      'descripcion': 'Registrar nuevas correspondencias en el sistema',
      'icono': Icons.add_box,
      'color': Colors.blue,
      'categoria': 'Gestión de Correspondencia',
    },
    'correspondenciasActivas': {
      'titulo': 'Correspondencias Activas',
      'descripcion': 'Ver correspondencias pendientes de entrega',
      'icono': Icons.mail,
      'color': Colors.green,
      'categoria': 'Gestión de Correspondencia',
    },
    'historialCorrespondencias': {
      'titulo': 'Historial de Correspondencias',
      'descripcion': 'Ver correspondencias ya entregadas',
      'icono': Icons.history,
      'color': Colors.orange,
      'categoria': 'Gestión de Correspondencia',
    },
    // Control de Acceso - Sub-funciones
    'gestionCamposAdicionales': {
      'titulo': 'Gestión de Campos Adicionales',
      'descripcion': 'Configurar campos personalizados del formulario',
      'icono': Icons.add_box_outlined,
      'color': Colors.green,
      'categoria': 'Control de Acceso',
    },
    'gestionCamposActivos': {
      'titulo': 'Gestión de Campos Activos',
      'descripcion': 'Activar/desactivar campos del formulario',
      'icono': Icons.toggle_on_outlined,
      'color': Colors.orange,
      'categoria': 'Control de Acceso',
    },
    'crearRegistroAcceso': {
      'titulo': 'Crear Registro de Acceso',
      'descripcion': 'Crear nuevos registros de acceso',
      'icono': Icons.add_circle_outline,
      'color': Colors.blue,
      'categoria': 'Control de Acceso',
    },
    'controlDiario': {
      'titulo': 'Control Diario',
      'descripcion': 'Registrar ingresos y salidas diarias',
      'icono': Icons.today_outlined,
      'color': Colors.purple,
      'categoria': 'Control de Acceso',
    },
    'historialControlAcceso': {
      'titulo': 'Historial de Control de Acceso',
      'descripcion': 'Consultar registros históricos de acceso',
      'icono': Icons.history_outlined,
      'color': Colors.teal,
      'categoria': 'Control de Acceso',
    },
    // Gestión de Estacionamientos - Sub-funciones
    'configuracionEstacionamientos': {
      'titulo': 'Configuración de Estacionamientos',
      'descripcion': 'Configurar espacios y parámetros de estacionamiento',
      'icono': Icons.settings,
      'color': Colors.blue,
      'categoria': 'Gestión de Estacionamientos',
    },
    'solicitudesEstacionamientos': {
      'titulo': 'Solicitudes de Estacionamientos',
      'descripcion': 'Gestionar solicitudes de espacios de estacionamiento',
      'icono': Icons.request_page,
      'color': Colors.orange,
      'categoria': 'Gestión de Estacionamientos',
    },
    'listaEstacionamientos': {
      'titulo': 'Lista de Estacionamientos',
      'descripcion': 'Ver y administrar todos los estacionamientos',
      'icono': Icons.list_alt,
      'color': Colors.green,
      'categoria': 'Gestión de Estacionamientos',
    },
    'estacionamientosVisitas': {
      'titulo': 'Estacionamientos de Visitas',
      'descripcion': 'Gestionar estacionamientos para visitantes',
      'icono': Icons.people_outline,
      'color': Colors.purple,
      'categoria': 'Gestión de Estacionamientos',
    },
    // Gestión de Espacios Comunes - Sub-funciones
    'gestionEspaciosComunes': {
      'titulo': 'Gestión de Espacios Comunes',
      'descripcion': 'Crear, editar y eliminar espacios comunes',
      'icono': Icons.business,
      'color': Colors.blue,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'solicitudesReservas': {
      'titulo': 'Solicitudes de Reservas',
      'descripcion': 'Aprobar o rechazar reservas de espacios comunes',
      'icono': Icons.event_available,
      'color': Colors.orange,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'revisionesPrePostUso': {
      'titulo': 'Revisiones Pre y Post Uso',
      'descripcion': 'Realizar revisiones antes o después del uso de espacios',
      'icono': Icons.rate_review,
      'color': Colors.green,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'solicitudesRechazadas': {
      'titulo': 'Solicitudes Rechazadas',
      'descripcion': 'Ver reservas que han sido rechazadas',
      'icono': Icons.cancel,
      'color': Colors.red,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'historialRevisiones': {
      'titulo': 'Historial de Revisiones',
      'descripcion': 'Ver todas las revisiones realizadas',
      'icono': Icons.history,
      'color': Colors.purple,
      'categoria': 'Gestión de Espacios Comunes',
    },
    // Gestión de Gastos Comunes - Sub-funciones
    'verTotalGastos': {
      'titulo': 'Ver Total de Gastos',
      'descripcion': 'Visualizar el total de gastos de todos los residentes',
      'icono': Icons.visibility,
      'color': Colors.blue,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'porcentajesPorResidentes': {
      'titulo': 'Porcentajes por Residentes',
      'descripcion': 'Gestionar distribución de gastos por vivienda',
      'icono': Icons.pie_chart,
      'color': Colors.purple,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosFijos': {
      'titulo': 'Gastos Fijos',
      'descripcion': 'Administrar gastos recurrentes mensuales',
      'icono': Icons.home,
      'color': Colors.blue,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosVariables': {
      'titulo': 'Gastos Variables',
      'descripcion': 'Gestionar gastos que varían mes a mes',
      'icono': Icons.trending_up,
      'color': Colors.orange,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosAdicionales': {
      'titulo': 'Gastos Adicionales',
      'descripcion': 'Administrar gastos extraordinarios o por período',
      'icono': Icons.add_circle,
      'color': Colors.green,
      'categoria': 'Gestión de Gastos Comunes',
    },
    // Otras funciones principales
    'gestionReclamos': {
      'titulo': 'Gestión de Reclamos',
      'descripcion': 'Administración de reclamos y quejas de residentes',
      'icono': Icons.report_problem,
      'color': Colors.red,
    },
    // Gestión de Multas - Sub-funciones
    'crearMulta': {
      'titulo': 'Crear Multa',
      'descripcion': 'Aplicar multas a residentes específicos',
      'icono': Icons.add_circle,
      'color': Colors.green,
      'categoria': 'Gestión de Multas',
    },
    'gestionadorMultas': {
      'titulo': 'Gestionador de Multas',
      'descripcion': 'Configurar tipos y valores de multas',
      'icono': Icons.settings,
      'color': Colors.blue,
      'categoria': 'Gestión de Multas',
    },
    'historialMultas': {
      'titulo': 'Historial de Multas',
      'descripcion': 'Ver todas las multas creadas',
      'icono': Icons.history,
      'color': Colors.orange,
      'categoria': 'Gestión de Multas',
    },
    'gestionPublicacionesAdmin': {
      'titulo': 'Gestión de Publicaciones (Admin)',
      'descripcion': 'Creación y administración de publicaciones comunitarias',
      'icono': Icons.article,
      'color': Colors.indigo,
      'categoria': 'Gestión de Publicaciones',
    },
    'publicacionesTrabajadores': {
      'titulo': 'Publicaciones',
      'descripcion': 'Ver publicaciones dirigidas a trabajadores',
      'icono': Icons.feed,
      'color': Colors.blue,
      'categoria': 'Gestión de Publicaciones',
    },
    // Bloqueo de Visitas - Sub-funciones
    'crearBloqueoVisitas': {
      'titulo': 'Crear Bloqueo de Visitas',
      'descripcion': 'Crear nuevos bloqueos para visitantes específicos',
      'icono': Icons.add_circle,
      'color': Colors.red,
      'categoria': 'Bloqueo de Visitas',
    },
    'visualizarVisitasBloqueadas': {
      'titulo': 'Visualizar Visitas Bloqueadas',
      'descripcion': 'Ver y gestionar la lista de visitas bloqueadas',
      'icono': Icons.visibility,
      'color': Colors.orange,
      'categoria': 'Bloqueo de Visitas',
    },
    'gestionMensajes': {
      'titulo': 'Gestión de Mensajes',
      'descripcion': 'Comunicación directa con residentes',
      'icono': Icons.message,
      'color': Colors.cyan,
    },
    'reportesYEstadisticas': {
      'titulo': 'Reportes y Estadísticas',
      'descripcion': 'Acceso a reportes y estadísticas del sistema',
      'icono': Icons.analytics,
      'color': Colors.brown,
    },
  };

  @override
  void initState() {
    super.initState();
    _funcionesDisponibles = Map.from(widget.trabajador.funcionesDisponibles);
  }

  Future<void> _guardarCambios() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar el trabajador con las nuevas funciones
      final trabajadorActualizado = widget.trabajador.copyWith(
        funcionesDisponibles: _funcionesDisponibles,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId!)
          .doc('usuarios')
          .collection('trabajadores')
          .doc(widget.trabajador.uid)
          .update(trabajadorActualizado.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar cambios
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar permisos: $e'),
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

  void _toggleFuncion(String funcion, bool valor) {
    setState(() {
      _funcionesDisponibles[funcion] = valor;
      _hasChanges = true;
    });
  }

  void _activarTodas() {
    setState(() {
      for (String key in _funcionesDisponibles.keys) {
        _funcionesDisponibles[key] = true;
      }
      _hasChanges = true;
    });
  }

  void _desactivarTodas() {
    setState(() {
      for (String key in _funcionesDisponibles.keys) {
        _funcionesDisponibles[key] = false;
      }
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Permisos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _guardarCambios,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con información del trabajador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade500,
                ],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    _getIconoPorTipo(widget.trabajador.tipoTrabajador),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.trabajador.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTipoTrabajadorDisplay(widget.trabajador.tipoTrabajador),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_funcionesDisponibles.values.where((v) => v).length} de ${_funcionesDisponibles.length} funciones activas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botones de acción rápida
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _activarTodas,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Activar Todas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _desactivarTodas,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Desactivar Todas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de funciones
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Sección de Gestión de Correspondencia
                _buildSeccionHeader('Gestión de Correspondencia'),
                ..._buildFuncionesPorCategoria('Gestión de Correspondencia'),
                const SizedBox(height: 16),
                
                // Sección de Control de Acceso
                _buildSeccionHeader('Control de Acceso'),
                ..._buildFuncionesPorCategoria('Control de Acceso'),
                const SizedBox(height: 16),
                
                // Sección de Gestión de Estacionamientos
                _buildSeccionHeader('Gestión de Estacionamientos'),
                ..._buildFuncionesPorCategoria('Gestión de Estacionamientos'),
                const SizedBox(height: 16),
                
                // Sección de Gestión de Espacios Comunes
                _buildSeccionHeader('Gestión de Espacios Comunes'),
                ..._buildFuncionesPorCategoria('Gestión de Espacios Comunes'),
                const SizedBox(height: 16),
                
                // Sección de Gestión de Gastos Comunes
                _buildSeccionHeader('Gestión de Gastos Comunes'),
                ..._buildFuncionesPorCategoria('Gestión de Gastos Comunes'),
                const SizedBox(height: 16),
                
                // Sección de Gestión de Multas
                _buildSeccionHeader('Gestión de Multas'),
                ..._buildFuncionesPorCategoria('Gestión de Multas'),
                const SizedBox(height: 16),
                
                // Sección de Gestión de Publicaciones
                _buildSeccionHeader('Gestión de Publicaciones'),
                ..._buildFuncionesPorCategoria('Gestión de Publicaciones'),
                const SizedBox(height: 16),
                
                // Sección de Bloqueo de Visitas
                _buildSeccionHeader('Bloqueo de Visitas'),
                ..._buildFuncionesPorCategoria('Bloqueo de Visitas'),
                const SizedBox(height: 16),
                
                // Sección de Otras Funciones
                _buildSeccionHeader('Otras Funciones'),
                ..._buildFuncionesPorCategoria(null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  List<Widget> _buildFuncionesPorCategoria(String? categoria) {
    final funcionesFiltradas = _funcionesInfo.entries
        .where((entry) => 
            categoria == null 
                ? entry.value['categoria'] == null
                : entry.value['categoria'] == categoria)
        .toList();

    return funcionesFiltradas.map((entry) {
      final funcion = entry.key;
      final info = entry.value;
      final isActive = _funcionesDisponibles[funcion] ?? false;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (info['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              info['icono'] as IconData,
              color: info['color'] as Color,
              size: 24,
            ),
          ),
          title: Text(
            info['titulo'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              info['descripcion'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          trailing: Switch(
            value: isActive,
            onChanged: (value) => _toggleFuncion(funcion, value),
            activeColor: info['color'] as Color,
          ),
        ),
      );
    }).toList();
  }

  IconData _getIconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return Icons.person_pin;
      case 'seguridad':
      case 'guardia':
        return Icons.security;
      case 'limpieza':
      case 'personalaseo':
        return Icons.cleaning_services;
      case 'mantenimiento':
        return Icons.build;
      case 'jardineria':
        return Icons.grass;
      case 'administracion':
        return Icons.admin_panel_settings;
      default:
        return Icons.work;
    }
  }

  String _getTipoTrabajadorDisplay(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'conserje':
        return 'Conserje';
      case 'seguridad':
      case 'guardia':
        return 'Seguridad';
      case 'limpieza':
      case 'personalaseo':
        return 'Personal de Aseo';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'jardineria':
        return 'Jardinería';
      case 'administracion':
        return 'Administración';
      case 'otro':
        return widget.trabajador.cargoEspecifico ?? 'Otro';
      default:
        return tipo;
    }
  }
}