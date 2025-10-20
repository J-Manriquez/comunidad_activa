import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/comite_model.dart';
import '../../services/firestore_service.dart';
import '../../services/estacionamiento_service.dart';

class ConfiguracionPermisosComiteScreen extends StatefulWidget {
  final UserModel currentUser;
  final ComiteModel miembroComite;

  const ConfiguracionPermisosComiteScreen({
    super.key,
    required this.currentUser,
    required this.miembroComite,
  });

  @override
  State<ConfiguracionPermisosComiteScreen> createState() =>
      _ConfiguracionPermisosComiteScreenState();
}

class _ConfiguracionPermisosComiteScreenState
    extends State<ConfiguracionPermisosComiteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  late Map<String, bool> _funcionesDisponibles;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _estVisitas = false; // Variable para controlar la visibilidad de estacionamientos de visitas
  
  // Estado de visibilidad de las secciones
  final Map<String, bool> _seccionesVisibles = {
    'Gestión de Correspondencia': false,
    'Control de Acceso': false,
    'Gestión de Estacionamientos': false,
    'Gestión de Espacios Comunes': false,
    'Gestión de Gastos Comunes': false,
    'Gestión de Multas': false,
    'Gestión de Reclamos': false,
    'Gestión de Publicaciones': false,
    'Registro Diario': false,
    'Bloqueo de Visitas': false,
    'Gestión de Mensajes': false,
  };

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
      'color': Colors.indigo,
      'categoria': 'Gestión de Estacionamientos',
    },
    'solicitudesEstacionamientos': {
      'titulo': 'Solicitudes de Estacionamientos',
      'descripcion': 'Gestionar solicitudes de estacionamiento',
      'icono': Icons.request_page,
      'color': Colors.indigo,
      'categoria': 'Gestión de Estacionamientos',
    },
    'listaEstacionamientos': {
      'titulo': 'Lista de Estacionamientos',
      'descripcion': 'Ver lista completa de estacionamientos',
      'icono': Icons.list,
      'color': Colors.indigo,
      'categoria': 'Gestión de Estacionamientos',
    },
    'estacionamientosVisitas': {
      'titulo': 'Estacionamientos para Visitas',
      'descripcion': 'Gestionar estacionamientos de visitas',
      'icono': Icons.local_parking,
      'color': Colors.indigo,
      'categoria': 'Gestión de Estacionamientos',
    },
    // Gestión de Espacios Comunes - Sub-funciones
    'gestionEspaciosComunes': {
      'titulo': 'Gestión de Espacios Comunes',
      'descripcion': 'Administrar espacios comunes del condominio',
      'icono': Icons.meeting_room,
      'color': Colors.teal,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'solicitudesReservas': {
      'titulo': 'Solicitudes de Reservas',
      'descripcion': 'Gestionar solicitudes de reserva de espacios',
      'icono': Icons.event_available,
      'color': Colors.teal,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'revisionesPrePostUso': {
      'titulo': 'Revisiones Pre/Post Uso',
      'descripcion': 'Realizar revisiones antes y después del uso',
      'icono': Icons.checklist,
      'color': Colors.teal,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'solicitudesRechazadas': {
      'titulo': 'Solicitudes Rechazadas',
      'descripcion': 'Ver solicitudes rechazadas de espacios',
      'icono': Icons.cancel,
      'color': Colors.teal,
      'categoria': 'Gestión de Espacios Comunes',
    },
    'historialRevisiones': {
      'titulo': 'Historial de Revisiones',
      'descripcion': 'Ver historial de revisiones de espacios',
      'icono': Icons.history,
      'color': Colors.teal,
      'categoria': 'Gestión de Espacios Comunes',
    },
    // Gestión de Gastos Comunes - Sub-funciones
    'verTotalGastos': {
      'titulo': 'Ver Total de Gastos',
      'descripcion': 'Visualizar el total de gastos comunes',
      'icono': Icons.account_balance_wallet,
      'color': Colors.amber,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'porcentajesPorResidentes': {
      'titulo': 'Porcentajes por Residentes',
      'descripcion': 'Gestionar porcentajes de gastos por residente',
      'icono': Icons.pie_chart,
      'color': Colors.amber,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosFijos': {
      'titulo': 'Gastos Fijos',
      'descripcion': 'Administrar gastos fijos del condominio',
      'icono': Icons.attach_money,
      'color': Colors.amber,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosVariables': {
      'titulo': 'Gastos Variables',
      'descripcion': 'Administrar gastos variables del condominio',
      'icono': Icons.trending_up,
      'color': Colors.amber,
      'categoria': 'Gestión de Gastos Comunes',
    },
    'gastosAdicionales': {
      'titulo': 'Gastos Adicionales',
      'descripcion': 'Gestionar gastos adicionales extraordinarios',
      'icono': Icons.add_circle,
      'color': Colors.amber,
      'categoria': 'Gestión de Gastos Comunes',
    },
    // Gestión de Multas - Sub-funciones
    'crearMulta': {
      'titulo': 'Crear Multa',
      'descripcion': 'Crear nuevas multas para residentes',
      'icono': Icons.add,
      'color': Colors.red,
      'categoria': 'Gestión de Multas',
    },
    'gestionadorMultas': {
      'titulo': 'Gestionador de Multas',
      'descripcion': 'Administrar multas existentes',
      'icono': Icons.gavel,
      'color': Colors.red,
      'categoria': 'Gestión de Multas',
    },
    'historialMultas': {
      'titulo': 'Historial de Multas',
      'descripcion': 'Ver historial de multas aplicadas',
      'icono': Icons.history,
      'color': Colors.red,
      'categoria': 'Gestión de Multas',
    },
    // Gestión de Reclamos - Sub-funciones
    'gestionTiposReclamos': {
      'titulo': 'Gestión de Tipos de Reclamos',
      'descripcion': 'Configurar tipos de reclamos disponibles',
      'icono': Icons.category,
      'color': Colors.deepOrange,
      'categoria': 'Gestión de Reclamos',
    },
    'gestionReclamos': {
      'titulo': 'Gestión de Reclamos',
      'descripcion': 'Administrar reclamos de residentes',
      'icono': Icons.report_problem,
      'color': Colors.deepOrange,
      'categoria': 'Gestión de Reclamos',
    },
    // Gestión de Publicaciones - Sub-funciones
    'gestionPublicacionesAdmin': {
      'titulo': 'Gestión de Publicaciones (Admin)',
      'descripcion': 'Administrar publicaciones como administrador',
      'icono': Icons.admin_panel_settings,
      'color': Colors.purple,
      'categoria': 'Gestión de Publicaciones',
    },
    'publicacionesTrabajadores': {
      'titulo': 'Publicaciones de Trabajadores',
      'descripcion': 'Gestionar publicaciones de trabajadores',
      'icono': Icons.announcement,
      'color': Colors.purple,
      'categoria': 'Gestión de Publicaciones',
    },
    // Registro Diario - Sub-funciones
    'crearNuevoRegistro': {
      'titulo': 'Crear Nuevo Registro',
      'descripcion': 'Crear nuevos registros diarios',
      'icono': Icons.add_circle_outline,
      'color': Colors.brown,
      'categoria': 'Registro Diario',
    },
    'registrosDelDia': {
      'titulo': 'Registros del Día',
      'descripcion': 'Ver registros del día actual',
      'icono': Icons.today,
      'color': Colors.brown,
      'categoria': 'Registro Diario',
    },
    'historialRegistros': {
      'titulo': 'Historial de Registros',
      'descripcion': 'Ver historial de registros diarios',
      'icono': Icons.history,
      'color': Colors.brown,
      'categoria': 'Registro Diario',
    },
    // Bloqueo de Visitas - Sub-funciones
    'crearBloqueoVisitas': {
      'titulo': 'Crear Bloqueo de Visitas',
      'descripcion': 'Crear nuevos bloqueos de visitas',
      'icono': Icons.block,
      'color': Colors.orange,
      'categoria': 'Bloqueo de Visitas',
    },
    'visualizarVisitasBloqueadas': {
      'titulo': 'Visualizar Visitas Bloqueadas',
      'descripcion': 'Ver lista de visitas bloqueadas',
      'icono': Icons.visibility_off,
      'color': Colors.orange,
      'categoria': 'Bloqueo de Visitas',
    },
    // Gestión de Mensajes - Sub-funciones
    'chatCondominio': {
      'titulo': 'Chat del Condominio',
      'descripcion': 'Chat general del condominio',
      'icono': Icons.forum,
      'color': Colors.cyan,
      'categoria': 'Gestión de Mensajes',
    },
    'chatConserjeria': {
      'titulo': 'Chat de Conserjería',
      'descripcion': 'Chat específico de conserjería',
      'icono': Icons.support_agent,
      'color': Colors.cyan,
      'categoria': 'Gestión de Mensajes',
    },
    'chatResidentes': {
      'titulo': 'Chat con Residentes',
      'descripcion': 'Comunicación con residentes',
      'icono': Icons.people,
      'color': Colors.cyan,
      'categoria': 'Gestión de Mensajes',
    },
    'chatAdministrador': {
      'titulo': 'Chat con Administrador',
      'descripcion': 'Comunicación directa con el administrador',
      'icono': Icons.admin_panel_settings,
      'color': Colors.cyan,
      'categoria': 'Gestión de Mensajes',
    },
    'gestionMensajes': {
      'titulo': 'Gestión de Mensajes',
      'descripcion': 'Comunicación directa con residentes',
      'icono': Icons.message,
      'color': Colors.cyan,
      'categoria': 'Gestión de Mensajes',
    },
  };

  @override
  void initState() {
    super.initState();
    _funcionesDisponibles = Map.from(widget.miembroComite.funcionesDisponibles);
    _loadEstVisitasConfig();
  }

  Future<void> _loadEstVisitasConfig() async {
    try {
      final config = await _estacionamientoService.obtenerConfiguracion(widget.currentUser.condominioId!);
      if (mounted) {
        setState(() {
          _estVisitas = config['estVisitas'] ?? false;
        });
      }
    } catch (e) {
      print('Error al cargar configuración de estVisitas: $e');
      // En caso de error, mantener el valor por defecto (false)
    }
  }

  void _toggleSeccionVisibilidad(String seccion) {
    setState(() {
      _seccionesVisibles[seccion] = !(_seccionesVisibles[seccion] ?? false);
    });
  }

  int _contarFuncionesActivas() {
    // Contar solo las funciones activas que están definidas en _funcionesInfo
    // Excluir las funciones vacías que aparecen en la pantalla principal
    final funcionesVacias = ['gestionMensajes'];
    
    return _funcionesInfo.keys
        .where((key) => !funcionesVacias.contains(key) && 
                       (_funcionesDisponibles[key] ?? false) &&
                       // Excluir estacionamientosVisitas si estVisitas es false
                       (key != 'estacionamientosVisitas' || _estVisitas))
        .length;
  }

  int _contarFuncionesTotales() {
    // Contar el total de funciones disponibles excluyendo las funciones vacías
    final funcionesVacias = ['gestionMensajes'];
    
    return _funcionesInfo.keys
        .where((key) => !funcionesVacias.contains(key) &&
                       // Excluir estacionamientosVisitas del total si estVisitas es false
                       (key != 'estacionamientosVisitas' || _estVisitas))
        .length;
  }

  List<Widget> _buildFuncionesPorCategoria(String categoria) {
    final funcionesCategoria = _funcionesInfo.entries
        .where((entry) => entry.value['categoria'] == categoria)
        .toList();

    return funcionesCategoria.map((entry) {
      final key = entry.key;
      final info = entry.value;
      
      // Ocultar estacionamientosVisitas si estVisitas es false
      if (key == 'estacionamientosVisitas' && !_estVisitas) {
        return const SizedBox.shrink();
      }
      
      return _buildFuncionCard(
        key: key,
        titulo: info['titulo'],
        descripcion: info['descripcion'],
        icono: info['icono'],
        color: info['color'],
        isActive: _funcionesDisponibles[key] ?? false,
      );
    }).toList();
  }

  Widget _buildFuncionCard({
    required String key,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required bool isActive,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? color.withOpacity(0.5) : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _funcionesDisponibles[key] = !isActive;
            _hasChanges = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive ? color : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icono,
                  color: isActive ? color : Colors.grey.shade500,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? color : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? Colors.grey.shade700 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    _funcionesDisponibles[key] = value;
                    _hasChanges = true;
                  });
                },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Actualizar el miembro del comité con las nuevas funciones
      final miembroActualizado = widget.miembroComite.copyWith(
        funcionesDisponibles: _funcionesDisponibles,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId!)
          .doc('usuarios')
          .collection('comite')
          .doc(widget.miembroComite.uid)
          .update(miembroActualizado.toMap());

      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cambios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos - ${widget.miembroComite.nombre}'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _isLoading ? null : _guardarCambios,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header con información del miembro del comité - Layout horizontal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade700,
                    Colors.purple.shade500,
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.group,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.miembroComite.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.miembroComite.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_contarFuncionesActivas()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'de ${_contarFuncionesTotales()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'activas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Lista de funciones
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sección de Gestión de Correspondencia
                  _buildSeccionHeader('Gestión de Correspondencia'),
                  if (_seccionesVisibles['Gestión de Correspondencia'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Correspondencia'),
                  const SizedBox(height: 16),
                  
                  // Sección de Control de Acceso
                  _buildSeccionHeader('Control de Acceso'),
                  if (_seccionesVisibles['Control de Acceso'] == true)
                    ..._buildFuncionesPorCategoria('Control de Acceso'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Estacionamientos
                  _buildSeccionHeader('Gestión de Estacionamientos'),
                  if (_seccionesVisibles['Gestión de Estacionamientos'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Estacionamientos'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Espacios Comunes
                  _buildSeccionHeader('Gestión de Espacios Comunes'),
                  if (_seccionesVisibles['Gestión de Espacios Comunes'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Espacios Comunes'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Gastos Comunes
                  _buildSeccionHeader('Gestión de Gastos Comunes'),
                  if (_seccionesVisibles['Gestión de Gastos Comunes'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Gastos Comunes'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Multas
                  _buildSeccionHeader('Gestión de Multas'),
                  if (_seccionesVisibles['Gestión de Multas'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Multas'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Reclamos
                  _buildSeccionHeader('Gestión de Reclamos'),
                  if (_seccionesVisibles['Gestión de Reclamos'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Reclamos'),
                  const SizedBox(height: 16),
                  
                  // Sección de Gestión de Publicaciones
                  _buildSeccionHeader('Gestión de Publicaciones'),
                  if (_seccionesVisibles['Gestión de Publicaciones'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Publicaciones'),
                  const SizedBox(height: 16),
                  
                  // Sección de Registro Diario
                  _buildSeccionHeader('Registro Diario'),
                  if (_seccionesVisibles['Registro Diario'] == true)
                    ..._buildFuncionesPorCategoria('Registro Diario'),
                  const SizedBox(height: 16),
                  
                  // Sección de Bloqueo de Visitas
                  _buildSeccionHeader('Bloqueo de Visitas'),
                  if (_seccionesVisibles['Bloqueo de Visitas'] == true)
                    ..._buildFuncionesPorCategoria('Bloqueo de Visitas'),
                  const SizedBox(height: 16),
                
                  // Sección de Gestión de Mensajes
                  _buildSeccionHeader('Gestión de Mensajes'),
                  if (_seccionesVisibles['Gestión de Mensajes'] == true)
                    ..._buildFuncionesPorCategoria('Gestión de Mensajes'),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    final isVisible = _seccionesVisibles[titulo] ?? false;
    
    return GestureDetector(
      onTap: () => _toggleSeccionVisibilidad(titulo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.purple.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
            Icon(
              isVisible ? Icons.expand_less : Icons.expand_more,
              color: Colors.purple.shade700,
            ),
          ],
        ),
      ),
    );
  }
}