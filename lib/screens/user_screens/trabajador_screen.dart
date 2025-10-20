import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trabajador_model.dart';
import '../../services/firestore_service.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del trabajador
          _buildHeader(),
          const SizedBox(height: 24),
          // Grid de funciones disponibles
          _buildFuncionesGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade600,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              _getIconoPorTipo(_trabajador!.tipoTrabajador),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bienvenido, ${_trabajador!.nombre}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getTipoTrabajadorDisplay(_trabajador!.tipoTrabajador),
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
              '${_trabajador!.funcionesDisponibles.values.where((v) => v).length} funciones disponibles',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuncionesGrid() {
    final funcionesActivas = _trabajador!.funcionesDisponibles.entries
        .where((entry) => entry.value)
        .toList();

    if (funcionesActivas.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes funciones disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacta al administrador para obtener permisos',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funciones Disponibles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: funcionesActivas.length,
          itemBuilder: (context, index) {
            final funcion = funcionesActivas[index].key;
            return _buildFuncionCard(funcion);
          },
        ),
      ],
    );
  }

  Widget _buildFuncionCard(String funcion) {
    final funcionInfo = _getFuncionInfo(funcion);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navegarAFuncion(funcion),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                funcionInfo['color'].withOpacity(0.1),
                funcionInfo['color'].withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: funcionInfo['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  funcionInfo['icono'],
                  color: funcionInfo['color'],
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                funcionInfo['titulo'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getFuncionInfo(String funcion) {
    final funcionesInfo = {
      // Gestión de Correspondencia - Sub-funciones
      'configuracionCorrespondencias': {
        'titulo': 'Configuración Correspondencias',
        'icono': Icons.settings,
        'color': Colors.blue,
      },
      'ingresarCorrespondencia': {
        'titulo': 'Ingresar Correspondencia',
        'icono': Icons.add_box,
        'color': Colors.blue,
      },
      'correspondenciasActivas': {
        'titulo': 'Correspondencias Activas',
        'icono': Icons.mail,
        'color': Colors.green,
      },
      'historialCorrespondencias': {
        'titulo': 'Historial Correspondencias',
        'icono': Icons.history,
        'color': Colors.orange,
      },
      // Control de Acceso - Sub-funciones
      'gestionCamposAdicionales': {
        'titulo': 'Campos Adicionales',
        'icono': Icons.add_box_outlined,
        'color': Colors.green,
      },
      'gestionCamposActivos': {
        'titulo': 'Campos Activos',
        'icono': Icons.toggle_on_outlined,
        'color': Colors.orange,
      },
      'crearRegistroAcceso': {
        'titulo': 'Crear Registro Acceso',
        'icono': Icons.add_circle_outline,
        'color': Colors.blue,
      },
      'controlDiario': {
        'titulo': 'Control Diario',
        'icono': Icons.today_outlined,
        'color': Colors.purple,
      },
      'historialControlAcceso': {
        'titulo': 'Historial Control Acceso',
        'icono': Icons.history_outlined,
        'color': Colors.teal,
      },
      // Gestión de Estacionamientos - Sub-funciones
      'configuracionEstacionamientos': {
        'titulo': 'Configuración Estacionamientos',
        'icono': Icons.settings,
        'color': Colors.blue,
      },
      'solicitudesEstacionamientos': {
        'titulo': 'Solicitudes Estacionamientos',
        'icono': Icons.request_page,
        'color': Colors.orange,
      },
      'listaEstacionamientos': {
        'titulo': 'Lista Estacionamientos',
        'icono': Icons.list_alt,
        'color': Colors.green,
      },
      'estacionamientosVisitas': {
        'titulo': 'Estacionamientos Visitas',
        'icono': Icons.people_outline,
        'color': Colors.purple,
      },
      // Gestión de Espacios Comunes - Sub-funciones
      'gestionEspaciosComunes': {
        'titulo': 'Gestión Espacios Comunes',
        'icono': Icons.business,
        'color': Colors.blue,
      },
      'solicitudesReservas': {
        'titulo': 'Solicitudes Reservas',
        'icono': Icons.event_available,
        'color': Colors.orange,
      },
      'revisionesPrePostUso': {
        'titulo': 'Revisiones Pre y Post Uso',
        'icono': Icons.rate_review,
        'color': Colors.green,
      },
      'solicitudesRechazadas': {
        'titulo': 'Solicitudes Rechazadas',
        'icono': Icons.cancel,
        'color': Colors.red,
      },
      'historialRevisiones': {
        'titulo': 'Historial Revisiones',
        'icono': Icons.history,
        'color': Colors.purple,
      },
      // Gestión de Gastos Comunes - Sub-funciones
      'verTotalGastos': {
        'titulo': 'Ver Total Gastos',
        'icono': Icons.visibility,
        'color': Colors.blue,
      },
      'porcentajesPorResidentes': {
        'titulo': 'Porcentajes Residentes',
        'icono': Icons.pie_chart,
        'color': Colors.purple,
      },
      'gastosFijos': {
        'titulo': 'Gastos Fijos',
        'icono': Icons.home,
        'color': Colors.blue,
      },
      'gastosVariables': {
        'titulo': 'Gastos Variables',
        'icono': Icons.trending_up,
        'color': Colors.orange,
      },
      'gastosAdicionales': {
        'titulo': 'Gastos Adicionales',
        'icono': Icons.add_circle,
        'color': Colors.green,
      },
      // Otras funciones principales
      'gestionReclamos': {
        'titulo': 'Reclamos',
        'icono': Icons.report_problem,
        'color': Colors.red,
      },
      // Gestión de Multas - Sub-funciones
      'crearMulta': {
        'titulo': 'Crear Multa',
        'icono': Icons.add_circle,
        'color': Colors.green,
      },
      'gestionadorMultas': {
        'titulo': 'Gestionador de Multas',
        'icono': Icons.settings,
        'color': Colors.blue,
      },
      'historialMultas': {
        'titulo': 'Historial de Multas',
        'icono': Icons.history,
        'color': Colors.orange,
      },
      // Gestión de Reclamos - Sub-funciones
      'gestionTiposReclamos': {
        'titulo': 'Gestión de Tipos de Reclamos',
        'icono': Icons.category,
        'color': Colors.purple,
      },
      'gestionReclamos': {
        'titulo': 'Gestión de Reclamos',
        'icono': Icons.report_problem,
        'color': Colors.red,
      },
      'gestionPublicacionesAdmin': {
        'titulo': 'Gestión de Publicaciones (Admin)',
        'icono': Icons.article,
        'color': Colors.indigo,
      },
      'publicacionesTrabajadores': {
        'titulo': 'Publicaciones',
        'icono': Icons.feed,
        'color': Colors.blue,
      },
      // Registro Diario - Sub-funciones
      'crearNuevoRegistro': {
        'titulo': 'Crear Nuevo Registro',
        'icono': Icons.add_circle_outline,
        'color': Colors.green,
      },
      'registrosDelDia': {
        'titulo': 'Registros del Día',
        'icono': Icons.today,
        'color': Colors.blue,
      },
      'historialRegistros': {
        'titulo': 'Historial de Registros',
        'icono': Icons.history,
        'color': Colors.orange,
      },
      // Bloqueo de Visitas - Sub-funciones
      'crearBloqueoVisitas': {
        'titulo': 'Crear Bloqueo de Visitas',
        'icono': Icons.add_circle,
        'color': Colors.red,
      },
      'visualizarVisitasBloqueadas': {
        'titulo': 'Visualizar Visitas Bloqueadas',
        'icono': Icons.visibility,
        'color': Colors.orange,
      },
      // Gestión de Mensajes - Sub-funciones
      'chatCondominio': {
        'titulo': 'Chat del Condominio',
        'icono': Icons.chat,
        'color': Colors.blue,
      },
      'chatConserjeria': {
        'titulo': 'Chat de Conserjería',
        'icono': Icons.chat_bubble,
        'color': Colors.green,
      },
      'chatResidentes': {
        'titulo': 'Chat con Residentes',
        'icono': Icons.people,
        'color': Colors.purple,
      },
      'chatAdministrador': {
        'titulo': 'Chat con Administrador',
        'icono': Icons.admin_panel_settings,
        'color': Colors.orange,
      },
      'gestionMensajes': {
        'titulo': 'Mensajes',
        'icono': Icons.message,
        'color': Colors.cyan,
      },
    };

    return funcionesInfo[funcion] ?? {
      'titulo': 'Función',
      'icono': Icons.work,
      'color': Colors.grey,
    };
  }

  void _navegarAFuncion(String funcion) {
    if (_currentUser == null) return;

    Widget? screen;

    switch (funcion) {
      // Gestión de Correspondencia - Sub-funciones
      case 'configuracionCorrespondencias':
        screen = ConfiguracionCorrespondenciaScreen(
          condominioId: widget.condominioId,
        );
        break;
      case 'ingresarCorrespondencia':
        screen = IngresarCorrespondenciaScreen(
          condominioId: widget.condominioId,
        );
        break;
      case 'correspondenciasActivas':
        screen = CorrespondenciasActivasScreen(
          condominioId: widget.condominioId,
          currentUser: _currentUser!,
        );
        break;
      case 'historialCorrespondencias':
        screen = HistorialCorrespondenciasScreen(
          condominioId: widget.condominioId,
          currentUser: _currentUser!,
        );
        break;
      // Control de Acceso - Sub-funciones
      case 'gestionCamposAdicionales':
        screen = GestionCamposAdicionalesScreen(
          currentUser: _currentUser!,
        );
        break;
      case 'gestionCamposActivos':
        screen = CamposActivosScreen(
          currentUser: _currentUser!,
        );
        break;
      case 'crearRegistroAcceso':
        screen = FormularioControlAccesoScreen(
          currentUser: _currentUser!.toResidenteModel(),
        );
        break;
      case 'controlDiario':
        screen = ControlDiarioScreen(
          currentUser: _currentUser!,
        );
        break;
      case 'historialControlAcceso':
        screen = HistorialControlAccesoScreen(
          currentUser: _currentUser!,
        );
        break;
      // Gestión de Estacionamientos - Sub-funciones
      case 'configuracionEstacionamientos':
        screen = ConfiguracionEstacionamientosScreen(condominioId: widget.condominioId);
        break;
      case 'solicitudesEstacionamientos':
        screen = SolicitudesEstacionamientoAdminScreen(condominioId: widget.condominioId);
        break;
      case 'listaEstacionamientos':
        screen = ListaEstacionamientosScreen(condominioId: widget.condominioId);
        break;
      case 'estacionamientosVisitas':
        screen = EstacionamientosVisitasScreen(condominioId: widget.condominioId);
        break;
      // Gestión de Espacios Comunes - Sub-funciones
      case 'gestionEspaciosComunes':
        screen = ListaEspaciosComunesScreen(currentUser: _currentUser!);
        break;
      case 'solicitudesReservas':
        screen = SolicitudesReservasScreen(currentUser: _currentUser!);
        break;
      case 'revisionesPrePostUso':
        screen = RevisionesUsoScreen(currentUser: _currentUser!);
        break;
      case 'solicitudesRechazadas':
        screen = SolicitudesRechazadasScreen(currentUser: _currentUser!);
        break;
      case 'historialRevisiones':
        screen = HistorialRevisionesScreen(currentUser: _currentUser!);
        break;
      // Otras funciones principales
      case 'verTotalGastos':
        screen = GastosComunesScreen(currentUser: _currentUser!);
        break;
      case 'porcentajesPorResidentes':
        screen = ListasPorcentajesScreen(currentUser: _currentUser!);
        break;
      case 'gastosFijos':
        screen = GastoDetalleScreen(
          currentUser: _currentUser!,
          tipoGasto: TipoGasto.fijo,
        );
        break;
      case 'gastosVariables':
        screen = GastoDetalleScreen(
          currentUser: _currentUser!,
          tipoGasto: TipoGasto.variable,
        );
        break;
      case 'gastosAdicionales':
        screen = GastoDetalleScreen(
          currentUser: _currentUser!,
          tipoGasto: TipoGasto.adicional,
        );
        break;
      // Gestión de Reclamos - Sub-funciones
      case 'gestionTiposReclamos':
        screen = GestionTiposReclamosScreen(currentUser: _currentUser!);
        break;
      case 'gestionReclamos':
        screen = AdminReclamosScreen(currentUser: _currentUser!);
        break;
      case 'crearMulta':
        screen = ComunidadScreen(
          condominioId: _currentUser!.condominioId!,
        );
        break;
      case 'gestionadorMultas':
        screen = GestionMultasScreen(currentUser: _currentUser!);
        break;
      case 'historialMultas':
        screen = HistorialMultasScreen(currentUser: _currentUser!);
        break;
      case 'gestionPublicacionesAdmin':
        screen = GestionPublicacionesScreen(currentUser: _currentUser!);
        break;
      case 'publicacionesTrabajadores':
        screen = PublicacionesTrabajadoresScreen(currentUser: _currentUser!);
        break;
      // Registro Diario - Sub-funciones
      case 'crearNuevoRegistro':
        screen = CrearRegistroScreen(condominioId: widget.condominioId);
        break;
      case 'registrosDelDia':
        screen = RegistrosDelDiaScreen(condominioId: widget.condominioId);
        break;
      case 'historialRegistros':
        screen = HistorialRegistrosScreen(condominioId: widget.condominioId);
        break;
      // Bloqueo de Visitas - Sub-funciones
      case 'crearBloqueoVisitas':
        screen = CrearBloqueoVisitaScreen(currentUser: _currentUser!);
        break;
      case 'visualizarVisitasBloqueadas':
        screen = BloqueoVisitasScreen(currentUser: _currentUser!);
        break;
      // Gestión de Mensajes - Sub-funciones
      
      case 'gestionMensajes':
        screen = MensajesAdminScreen(currentUser: _currentUser!);
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen!),
      );
    }
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
        return _trabajador?.cargoEspecifico ?? 'Otro';
      default:
        return tipo;
    }
  }
}