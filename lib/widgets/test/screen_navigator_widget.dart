import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/trabajador_model.dart';
import '../../models/comite_model.dart';
import '../../models/reserva_model.dart';
import '../../models/gasto_comun_model.dart';
import '../../services/firestore_service.dart';

// Importaciones de pantallas de administrador
import '../../screens/admin/admin_screen.dart';
import '../../screens/admin/comunicaciones/admin_notifications_screen.dart';
import '../../screens/admin/comunicaciones/admin_reclamos_screen.dart';
import '../../screens/admin/comunicaciones/crear_publicacion_screen.dart';
import '../../screens/admin/comunicaciones/gestion_multas_screen.dart';
import '../../screens/admin/comunicaciones/gestion_publicaciones_screen.dart';
import '../../screens/admin/comunicaciones/gestion_tipos_reclamos_screen.dart';
import '../../screens/admin/comunicaciones/historial_multas_screen.dart' as admin_historial;
import '../../screens/admin/comunicaciones/mensajes_admin_screen.dart';
import '../../screens/admin/comunicaciones/multas_admin_screen.dart';
import '../../screens/admin/comunicaciones/publicaciones_trabajadores_screen.dart';
import '../../screens/admin/correspondencia/configuracion_correspondencia_screen.dart';
import '../../screens/admin/correspondencia/correspondencias_activas_screen.dart';
import '../../screens/admin/correspondencia/correspondencias_screen.dart';
import '../../screens/admin/correspondencia/historial_correspondencias_screen.dart';
import '../../screens/admin/correspondencia/ingresar_correspondencia_screen.dart';
import '../../screens/admin/controlAcceso/campos_activos_screen.dart';
import '../../screens/admin/controlAcceso/control_acceso_screen.dart';
import '../../screens/admin/controlAcceso/control_diario_screen.dart';
import '../../screens/admin/controlAcceso/formulario_control_acceso_screen.dart';
import '../../screens/admin/controlAcceso/gestion_campos_adicionales_screen.dart';
import '../../screens/admin/controlAcceso/historial_control_acceso_screen.dart';
import '../../screens/admin/espaciosComunes/crear_editar_espacio_screen.dart';
import '../../screens/admin/espaciosComunes/crear_revision_screen.dart';
import '../../screens/admin/espaciosComunes/espacios_comunes_screen.dart';
import '../../screens/admin/espaciosComunes/historial_revisiones_screen.dart';
import '../../screens/admin/espaciosComunes/lista_espacios_comunes_screen.dart';
import '../../screens/admin/espaciosComunes/revisiones_post_uso_screen.dart';
import '../../screens/admin/espaciosComunes/solicitudes_rechazadas_screen.dart';
import '../../screens/admin/espaciosComunes/solicitudes_reservas_screen.dart';
import '../../screens/admin/estacionamientos/asignar_estacionamientos_screen.dart';
import '../../screens/admin/estacionamientos/configuracion_estacionamientos_screen.dart';
import '../../screens/admin/estacionamientos/estacionamientos_admin_screen.dart';
import '../../screens/admin/estacionamientos/estacionamientos_visitas_screen.dart';
import '../../screens/admin/estacionamientos/lista_estacionamientos_screen.dart';
import '../../screens/admin/estacionamientos/solicitudes_estacionamiento_admin_screen.dart';
import '../../screens/admin/gastosComunes/gasto_detalle_screen.dart';
import '../../screens/admin/gastosComunes/gasto_form_screen.dart';
import '../../screens/admin/gastosComunes/gastos_comunes_screen.dart';
import '../../screens/admin/gastosComunes/gastos_por_vivienda_screen.dart';
import '../../screens/admin/gastosComunes/lista_porcentaje_form_screen.dart';
import '../../screens/admin/gastosComunes/listas_porcentajes_screen.dart';
import '../../screens/admin/registro_diario/crear_registro_screen.dart';
import '../../screens/admin/registro_diario/historial_registros_screen.dart';
import '../../screens/admin/registro_diario/registros_del_dia_screen.dart';
import '../../screens/admin/bloqueo_visitas_screen.dart';
import '../../screens/admin/visitasBloqueadas/crear_bloqueo_visita_screen.dart';
import '../../screens/admin/comunidad_screen.dart';
import '../../screens/admin/gestion_comite_screen.dart';
import '../../screens/admin/gestion_trabajadores_screen.dart';
import '../../screens/admin/settings_screen.dart';

// Importaciones de pantallas de residente
import '../../screens/residente/residente_screen.dart';
import '../../screens/residente/comunicaciones/crear_reclamo_screen.dart';
import '../../screens/residente/comunicaciones/historial_multas_screen.dart' as residente_historial;
import '../../screens/residente/comunicaciones/mensajes_residente_screen.dart';
import '../../screens/residente/comunicaciones/publicaciones_residente_screen.dart';
import '../../screens/residente/comunicaciones/r_multas_screen.dart';
import '../../screens/residente/comunicaciones/r_notifications_screen.dart';
import '../../screens/residente/comunicaciones/r_reclamos_screen.dart';
import '../../screens/residente/correspondencia/correspondencias_residente_screen.dart';
import '../../screens/residente/correspondencia/historial_correspondencias_residente_screen.dart';
import '../../screens/residente/espacios_comunes_residente_screen.dart';
import '../../screens/residente/estacionamientos_residente_screen.dart';
import '../../screens/residente/gastos_comunes_residente_screen.dart';
import '../../screens/residente/prestamos_estacionamiento_screen.dart';
import '../../screens/residente/r_config_screen.dart';
import '../../screens/residente/r_seleccion_vivienda_screen.dart';
import '../../screens/residente/revisiones_espacios_residente_screen.dart';
import '../../screens/residente/seleccion_estacionamiento_residente_screen.dart';
import '../../screens/residente/solicitar_espacio_screen.dart';
import '../../screens/residente/visitas_bloqueadas_residente_screen.dart';

// Importaciones de pantallas de comité y trabajador
import '../../screens/user_screens/comite_screen.dart';
import '../../screens/user_screens/trabajador_screen.dart';

// Importaciones adicionales necesarias
import '../../screens/home_screen.dart';
// import '../../screens/welcome_screen.dart'; // Archivo no existe
// import '../../screens/login_screen.dart'; // Archivo no existe
// import '../../screens/register_screen.dart'; // Archivo no existe
import '../../screens/chat_screen.dart';
import '../../screens/registro_acceso_screen.dart';
import '../../screens/admin/registro_diario_screen.dart';
import '../../screens/admin/gestion_turnos_screen.dart';
import '../../screens/admin/gestion_turnos_definidos_screen.dart';
import '../../screens/admin/registro_turnos_screen.dart';
import '../../screens/residente/mensajes_trabajador_screen.dart';
// import '../../screens/admin/comunicaciones/ver_publicacion_screen.dart'; // Archivo no existe
// import '../../screens/admin/crear_editar_accesos_predeterminados_screen.dart'; // Archivo no existe

class ScreenNavigatorWidget extends StatefulWidget {
  final UserModel currentUser;

  const ScreenNavigatorWidget({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ScreenNavigatorWidget> createState() => _ScreenNavigatorWidgetState();
}

class _ScreenNavigatorWidgetState extends State<ScreenNavigatorWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  TrabajadorModel? _trabajador;
  ComiteModel? _comite;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    if (widget.currentUser.tipoUsuario == UserType.trabajador) {
      _trabajador = await _firestoreService.getTrabajadorData(
        widget.currentUser.condominioId!,
        widget.currentUser.uid,
      );
    } else if (widget.currentUser.tipoUsuario == UserType.comite ||
        (widget.currentUser.tipoUsuario == UserType.residente && widget.currentUser.esComite == true)) {
      _comite = await _firestoreService.getComiteData(
        widget.currentUser.condominioId!,
        widget.currentUser.uid,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navegador de Pantallas - ${_getUserTypeTitle()}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildScreenSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserTypeTitle() {
    return 'Todas las Pantallas - Test Navigator';
  }

  List<Widget> _buildScreenSections() {
    // Organizar todas las pantallas por categorías funcionales
    List<Widget> allSections = [];

    // 1. Pantallas Principales / Dashboard
    List<Widget> dashboardScreens = [];
    dashboardScreens.add(_buildScreenTile('Home', Icons.home, () => _navigateToScreen(HomeScreen())));
    dashboardScreens.add(_buildScreenTile('Admin Dashboard', Icons.admin_panel_settings, () => _navigateToScreen(AdminScreen(condominioId: widget.currentUser.condominioId!))));
    dashboardScreens.add(_buildScreenTile('Residente Dashboard', Icons.person, () => _navigateToScreen(ResidenteScreen(condominioId: widget.currentUser.condominioId!))));
    dashboardScreens.add(_buildScreenTile('Trabajador Dashboard', Icons.work, () => _navigateToScreen(TrabajadorScreen(condominioId: widget.currentUser.condominioId!))));
    dashboardScreens.add(_buildScreenTile('Comité Dashboard', Icons.dashboard, () => _navigateToScreen(ComiteScreen(condominioId: widget.currentUser.condominioId!))));
    allSections.add(_buildSection('🏠 Pantallas Principales', dashboardScreens));

    // 2. Gestión de Usuarios y Residentes
    List<Widget> userManagementScreens = [];
    userManagementScreens.add(_buildScreenTile('Gestión Comité', Icons.group, () => _navigateToScreen(GestionComiteScreen(currentUser: widget.currentUser))));
    userManagementScreens.add(_buildScreenTile('Gestión Trabajadores', Icons.work, () => _navigateToScreen(GestionTrabajadoresScreen(currentUser: widget.currentUser))));
    userManagementScreens.add(_buildScreenTile('Configurar Comunidad', Icons.apartment, () => _navigateToScreen(ComunidadScreen(condominioId: widget.currentUser.condominioId!))));
    userManagementScreens.add(_buildScreenTile('Configuraciones', Icons.settings, () => _navigateToScreen(SettingsScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))));
    allSections.add(_buildSection('👥 Gestión de Usuarios', userManagementScreens));

    // 3. Finanzas y Gastos
    List<Widget> financeScreens = [];
    financeScreens.add(_buildScreenTile('Gastos Comunes', Icons.receipt, () => _navigateToScreen(GastosComunesScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))));
    financeScreens.add(_buildScreenTile('Gastos por Vivienda', Icons.home_work, () => _navigateToScreen(GastosPorViviendaScreen(currentUser: widget.currentUser))));
    financeScreens.add(_buildScreenTile('Formulario Gastos', Icons.add_box, () => _navigateToScreen(GastoFormScreen(currentUser: widget.currentUser, tipoGasto: TipoGasto.fijo))));
    financeScreens.add(_buildScreenTile('Listas Porcentajes', Icons.pie_chart, () => _navigateToScreen(ListasPorcentajesScreen(currentUser: widget.currentUser))));
    financeScreens.add(_buildScreenTile('Form. Porcentaje', Icons.percent, () => _navigateToScreen(ListaPorcentajeFormScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('💰 Finanzas y Gastos', financeScreens));

    // 4. Correspondencia
    List<Widget> correspondenceScreens = [];
    correspondenceScreens.add(_buildScreenTile('Correspondencias', Icons.mail, () => _navigateToScreen(CorrespondenciasScreen(currentUser: widget.currentUser))));
    correspondenceScreens.add(_buildScreenTile('Correspondencias Activas', Icons.mark_email_unread, () => _navigateToScreen(CorrespondenciasActivasScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))));
    correspondenceScreens.add(_buildScreenTile('Ingresar Correspondencia', Icons.add_to_photos, () => _navigateToScreen(IngresarCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))));
    correspondenceScreens.add(_buildScreenTile('Historial Correspondencias', Icons.history_edu, () => _navigateToScreen(HistorialCorrespondenciasScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))));
    correspondenceScreens.add(_buildScreenTile('Configuración Correspondencia', Icons.settings_applications, () => _navigateToScreen(ConfiguracionCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))));
    allSections.add(_buildSection('📧 Correspondencia', correspondenceScreens));

    // 5. Control de Acceso
    List<Widget> accessControlScreens = [];
    accessControlScreens.add(_buildScreenTile('Control de Acceso', Icons.security, () => _navigateToScreen(ControlAccesoScreen(currentUser: widget.currentUser))));
    accessControlScreens.add(_buildScreenTile('Historial Control', Icons.history, () => _navigateToScreen(HistorialControlAccesoScreen(currentUser: widget.currentUser))));
    accessControlScreens.add(_buildScreenTile('Formulario Control', Icons.assignment, () => _navigateToScreen(FormularioControlAccesoScreen(currentUser: widget.currentUser.toResidenteModel()))));
    accessControlScreens.add(_buildScreenTile('Control Diario', Icons.today, () => _navigateToScreen(ControlDiarioScreen(currentUser: widget.currentUser))));
    accessControlScreens.add(_buildScreenTile('Gestión Campos Adicionales', Icons.add_circle, () => _navigateToScreen(GestionCamposAdicionalesScreen(currentUser: widget.currentUser))));
    accessControlScreens.add(_buildScreenTile('Campos Activos', Icons.toggle_on, () => _navigateToScreen(CamposActivosScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('🔐 Control de Acceso', accessControlScreens));

    // 6. Comunicaciones
    List<Widget> communicationScreens = [];
    communicationScreens.add(_buildScreenTile('Mensajes Admin', Icons.message, () => _navigateToScreen(MensajesAdminScreen(currentUser: widget.currentUser))));
    communicationScreens.add(_buildScreenTile('Mensajes Residente', Icons.message, () => _navigateToScreen(MensajesResidenteScreen(currentUser: widget.currentUser))));
    communicationScreens.add(_buildScreenTile('Mensajes Trabajador', Icons.work, () => _navigateToScreen(MensajesTrabajadorScreen(currentUser: widget.currentUser))));
    communicationScreens.add(_buildScreenTile('Notificaciones Admin', Icons.notifications, () => _navigateToScreen(AdminNotificationsScreen(condominioId: widget.currentUser.condominioId!))));
    communicationScreens.add(_buildScreenTile('Notificaciones Residente', Icons.notifications, () => _navigateToScreen(ResidenteNotificationsScreen(condominioId: widget.currentUser.condominioId!))));
    communicationScreens.add(_buildScreenTile('Chat', Icons.chat, () => _navigateToScreen(ChatScreen(
      currentUser: widget.currentUser,
      chatId: 'test',
      nombreChat: 'Test Chat',
      esGrupal: false,
    ))));
    allSections.add(_buildSection('💬 Comunicaciones', communicationScreens));

    // 7. Publicaciones
    List<Widget> publicationScreens = [];
    publicationScreens.add(_buildScreenTile('Crear Publicación', Icons.add_box, () => _navigateToScreen(CrearPublicacionScreen(currentUser: widget.currentUser))));
    publicationScreens.add(_buildScreenTile('Gestión Publicaciones', Icons.article, () => _navigateToScreen(GestionPublicacionesScreen(currentUser: widget.currentUser))));
    publicationScreens.add(_buildScreenTile('Publicaciones Trabajadores', Icons.work_history, () => _navigateToScreen(PublicacionesTrabajadoresScreen(currentUser: widget.currentUser))));
    publicationScreens.add(_buildScreenTile('Publicaciones Residente', Icons.article, () => _navigateToScreen(PublicacionesResidenteScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('📢 Publicaciones', publicationScreens));

    // 8. Reclamos y Multas
    List<Widget> complaintsScreens = [];
    complaintsScreens.add(_buildScreenTile('Admin Reclamos', Icons.report_problem, () => _navigateToScreen(AdminReclamosScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Reclamos Residente', Icons.report_problem, () => _navigateToScreen(ReclamosResidenteScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Crear Reclamo', Icons.add_box, () => _navigateToScreen(CrearReclamoScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Tipos de Reclamos', Icons.category, () => _navigateToScreen(GestionTiposReclamosScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Multas Admin', Icons.gavel, () => _navigateToScreen(MultasAdminScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Multas Residente', Icons.gavel, () => _navigateToScreen(MultasResidenteScreen(currentUser: widget.currentUser))));
    complaintsScreens.add(_buildScreenTile('Gestión Multas', Icons.monetization_on, () => _navigateToScreen(GestionMultasScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('⚠️ Reclamos y Multas', complaintsScreens));

    // 9. Espacios Comunes
    List<Widget> commonAreasScreens = [];
    commonAreasScreens.add(_buildScreenTile('Espacios Comunes Admin', Icons.meeting_room, () => _navigateToScreen(EspaciosComunesScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Espacios Comunes Residente', Icons.location_city, () => _navigateToScreen(EspaciosComunesResidenteScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Lista Espacios', Icons.list, () => _navigateToScreen(ListaEspaciosComunesScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Crear/Editar Espacio', Icons.add_business, () => _navigateToScreen(CrearEditarEspacioScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Solicitudes Reservas', Icons.event_available, () => _navigateToScreen(SolicitudesReservasScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Solicitudes Rechazadas', Icons.cancel, () => _navigateToScreen(SolicitudesRechazadasScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Solicitar Espacio', Icons.event_available, () => _navigateToScreen(SolicitarEspacioScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Revisiones Post Uso', Icons.checklist, () => _navigateToScreen(RevisionesUsoScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Historial Revisiones', Icons.history_toggle_off, () => _navigateToScreen(HistorialRevisionesScreen(currentUser: widget.currentUser))));
    commonAreasScreens.add(_buildScreenTile('Revisiones Espacios Residente', Icons.rate_review, () => _navigateToScreen(RevisionesEspaciosResidenteScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('🏢 Espacios Comunes', commonAreasScreens));

    // 10. Estacionamientos
    List<Widget> parkingScreens = [];
    parkingScreens.add(_buildScreenTile('Estacionamientos Admin', Icons.local_parking, () => _navigateToScreen(EstacionamientosAdminScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Estacionamientos Residente', Icons.local_parking, () => _navigateToScreen(EstacionamientosResidenteScreen())));
    parkingScreens.add(_buildScreenTile('Configurar Estacionamientos', Icons.settings, () => _navigateToScreen(ConfiguracionEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Asignar Estacionamientos', Icons.assignment, () => _navigateToScreen(AsignarEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Lista Estacionamientos', Icons.list, () => _navigateToScreen(ListaEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Estacionamientos Visitas', Icons.directions_car, () => _navigateToScreen(EstacionamientosVisitasScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Solicitudes Estacionamiento', Icons.request_page, () => _navigateToScreen(SolicitudesEstacionamientoAdminScreen(condominioId: widget.currentUser.condominioId!))));
    parkingScreens.add(_buildScreenTile('Préstamos Estacionamiento', Icons.swap_horiz, () => _navigateToScreen(PrestamosEstacionamientoScreen(currentUser: widget.currentUser.toResidenteModel()))));
    parkingScreens.add(_buildScreenTile('Selección Estacionamiento', Icons.where_to_vote, () => _navigateToScreen(SeleccionEstacionamientoResidenteScreen())));
    allSections.add(_buildSection('🚗 Estacionamientos', parkingScreens));

    // 11. Bloqueo de Visitas
    List<Widget> visitBlockingScreens = [];
    visitBlockingScreens.add(_buildScreenTile('Bloqueo de Visitas Admin', Icons.block, () => _navigateToScreen(BloqueoVisitasScreen(currentUser: widget.currentUser))));
    visitBlockingScreens.add(_buildScreenTile('Crear Bloqueo', Icons.add_moderator, () => _navigateToScreen(CrearBloqueoVisitaScreen(currentUser: widget.currentUser))));
    visitBlockingScreens.add(_buildScreenTile('Visitas Bloqueadas Residente', Icons.block, () => _navigateToScreen(VisitasBloqueadasResidenteScreen(currentUser: widget.currentUser))));
    allSections.add(_buildSection('🚫 Bloqueo de Visitas', visitBlockingScreens));

    // 12. Registro Diario
     List<Widget> dailyRecordScreens = [];
     dailyRecordScreens.add(_buildScreenTile('Crear Registro', Icons.add_circle, () => _navigateToScreen(CrearRegistroScreen(condominioId: widget.currentUser.condominioId!))));
     dailyRecordScreens.add(_buildScreenTile('Historial Registros', Icons.history, () => _navigateToScreen(HistorialRegistrosScreen(condominioId: widget.currentUser.condominioId!))));
     dailyRecordScreens.add(_buildScreenTile('Registros del Día', Icons.today, () => _navigateToScreen(RegistrosDelDiaScreen(condominioId: widget.currentUser.condominioId!))));
     allSections.add(_buildSection('📝 Registro Diario', dailyRecordScreens));

    // 13. Configuración de Usuario
    List<Widget> userConfigScreens = [];
    userConfigScreens.add(_buildScreenTile('Configuración Residente', Icons.settings, () => _navigateToScreen(ResidenteConfigScreen(condominioId: widget.currentUser.condominioId!))));
    userConfigScreens.add(_buildScreenTile('Selección Vivienda', Icons.home_work, () => _navigateToScreen(ResidenteSeleccionViviendaScreen(condominioId: widget.currentUser.condominioId!))));
    allSections.add(_buildSection('⚙️ Configuración de Usuario', userConfigScreens));

    return allSections;
  }

  List<Widget> _buildAdminScreens() {
    return [
      _buildSection('Pantalla Principal', [
        _buildScreenTile('Dashboard Administrador', Icons.dashboard, () => _navigateToScreen(AdminScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Configuración y Permisos', [
        // Comentado temporalmente hasta verificar la implementación
        // _buildScreenTile('Funciones y Permisos', Icons.security, () => _navigateToScreen(FuncionesPermisosScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))),
        // _buildScreenTile('Permisos Trabajador', Icons.admin_panel_settings, () => _navigateToScreen(ConfiguracionPermisosTrabajadorScreen(condominioId: widget.currentUser.condominioId!))),
        // _buildScreenTile('Permisos Comité', Icons.admin_panel_settings_outlined, () => _navigateToScreen(ConfiguracionPermisosComiteScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Admin Screen', Icons.admin_panel_settings, () => _navigateToScreen(AdminScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Configurar Comunidad', Icons.apartment, () => _navigateToScreen(ComunidadScreen(condominioId: widget.currentUser.condominioId!))),
        // _buildScreenTile('Configurar Viviendas', Icons.home_work, () => _navigateToScreen(ViviendasScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Configuraciones', Icons.settings, () => _navigateToScreen(SettingsScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))),
      ]),
      _buildSection('Comunicaciones', [
        _buildScreenTile('Mensajes Admin', Icons.message, () => _navigateToScreen(MensajesAdminScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Notificaciones Admin', Icons.notifications, () => _navigateToScreen(AdminNotificationsScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Crear Publicación', Icons.add_box, () => _navigateToScreen(CrearPublicacionScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Gestión Publicaciones', Icons.article, () => _navigateToScreen(GestionPublicacionesScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Publicaciones Trabajadores', Icons.work_history, () => _navigateToScreen(PublicacionesTrabajadoresScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Ver Publicación', Icons.visibility, () => _navigateToScreen(VerPublicacionScreen(
        //   publicacion: null, // Placeholder - necesita una publicación real
        //   currentUser: widget.currentUser,
        //   esAdministrador: true,
        // ))),
        // Reclamos y Multas section
        _buildScreenTile('Admin Reclamos', Icons.report_problem, () => _navigateToScreen(AdminReclamosScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Tipos de Reclamos', Icons.category, () => _navigateToScreen(GestionTiposReclamosScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Multas Admin', Icons.gavel, () => _navigateToScreen(MultasAdminScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Gestión Multas', Icons.monetization_on, () => _navigateToScreen(GestionMultasScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Historial Multas', Icons.history, () => _navigateToScreen(HistorialMultasScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Crear Multa', Icons.add_circle, () => _navigateToScreen(CrearMultaScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Correspondencia', [
        _buildScreenTile('Correspondencias', Icons.mail, () => _navigateToScreen(CorrespondenciasScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Correspondencias Activas', Icons.mark_email_unread, () => _navigateToScreen(CorrespondenciasActivasScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Ingresar Correspondencia', Icons.add_to_photos, () => _navigateToScreen(IngresarCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Historial Correspondencias', Icons.history_edu, () => _navigateToScreen(HistorialCorrespondenciasScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Configuración Correspondencia', Icons.settings_applications, () => _navigateToScreen(ConfiguracionCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Control de Acceso', [
        _buildScreenTile('Control de Acceso', Icons.security, () => _navigateToScreen(ControlAccesoScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Historial Control', Icons.history, () => _navigateToScreen(HistorialControlAccesoScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Formulario Control', Icons.assignment, () => _navigateToScreen(FormularioControlAccesoScreen(currentUser: widget.currentUser.toResidenteModel()))),
        _buildScreenTile('Control Diario', Icons.today, () => _navigateToScreen(ControlDiarioScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Registro de Acceso', Icons.login, () => _navigateToScreen(RegistroAccesoScreen())),
        // _buildScreenTile('Accesos Predeterminados', Icons.settings_input_component, () => _navigateToScreen(CrearEditarAccesosPredeterminadosScreen())),
      ]),
      _buildSection('Espacios Comunes', [
        _buildScreenTile('Espacios Comunes', Icons.meeting_room, () => _navigateToScreen(EspaciosComunesScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Lista Espacios', Icons.list, () => _navigateToScreen(ListaEspaciosComunesScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Crear/Editar Espacio', Icons.add_business, () => _navigateToScreen(CrearEditarEspacioScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Solicitudes Reservas', Icons.event_available, () => _navigateToScreen(SolicitudesReservasScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Solicitudes Rechazadas', Icons.cancel, () => _navigateToScreen(SolicitudesRechazadasScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Reservas Espacios', Icons.event, () => _navigateToScreen(ReservasEspaciosScreen(
        //   reserva: ReservaModel(
        //     id: 'test',
        //     espacioComunId: 'test',
        //     fechaHoraSolicitud: DateTime.now().toIso8601String(),
        //     fechaHoraReserva: DateTime.now().toIso8601String(),
        //     participantes: ['test'],
        //     estado: 'pendiente',
        //     idSolicitante: ['test'],
        //     nombreEspacioComun: 'Espacio Test',
        //     vivienda: 'Casa 1',
        //   ),
        // ))),
        // _buildScreenTile('Historial Reservas', Icons.history, () => _navigateToScreen(HistorialReservasScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Revisiones Post Uso', Icons.checklist, () => _navigateToScreen(RevisionesUsoScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Historial Revisiones', Icons.history_toggle_off, () => _navigateToScreen(HistorialRevisionesScreen(currentUser: widget.currentUser))),
      ]),
      _buildSection('Estacionamientos', [
        // _buildScreenTile('Estacionamientos', Icons.local_parking, () => _navigateToScreen(EstacionamientosScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Configurar Estacionamientos', Icons.settings, () => _navigateToScreen(ConfiguracionEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Asignar Estacionamientos', Icons.assignment, () => _navigateToScreen(AsignarEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))),
        // _buildScreenTile('Historial Estacionamientos', Icons.history, () => _navigateToScreen(HistorialEstacionamientosScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Gastos Comunes', [
        _buildScreenTile('Gastos Comunes', Icons.account_balance_wallet, () => _navigateToScreen(GastosComunesScreen(currentUser: widget.currentUser, condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Formulario Gasto', Icons.receipt_long, () => _navigateToScreen(GastoFormScreen(currentUser: widget.currentUser, tipoGasto: TipoGasto.fijo))),
        // _buildScreenTile('Detalle Gasto', Icons.receipt, () => _navigateToScreen(GastoDetalleScreen(gastoId: 'test', condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Gastos por Vivienda', Icons.home_outlined, () => _navigateToScreen(GastosPorViviendaScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Listas Porcentajes', Icons.pie_chart, () => _navigateToScreen(ListasPorcentajesScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Form. Porcentaje', Icons.percent, () => _navigateToScreen(ListaPorcentajeFormScreen(currentUser: widget.currentUser))),
      ]),
      _buildSection('Registro Diario', [
        // _buildScreenTile('Registro Diario', Icons.assignment, () => _navigateToScreen(RegistroDiarioScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))),
      ]),
      _buildSection('Bloqueo de Visitas', [
        _buildScreenTile('Bloqueo de Visitas', Icons.block, () => _navigateToScreen(BloqueoVisitasScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Crear Bloqueo', Icons.add_moderator, () => _navigateToScreen(CrearBloqueoVisitaScreen(currentUser: widget.currentUser))),
      ]),
      _buildSection('Gestión de Turnos', [
        // _buildScreenTile('Gestión Turnos', Icons.schedule, () => _navigateToScreen(GestionTurnosScreen())),
        // _buildScreenTile('Turnos Definidos', Icons.event_note, () => _navigateToScreen(GestionTurnosDefinidosScreen())),
        // _buildScreenTile('Registro Turnos', Icons.access_time, () => _navigateToScreen(RegistroTurnosScreen())),
      ]),
      _buildSection('Pantallas Generales', [
        _buildScreenTile('Chat', Icons.chat, () => _navigateToScreen(ChatScreen(
          currentUser: widget.currentUser,
          chatId: 'test',
          nombreChat: 'Test Chat',
          esGrupal: false,
        ))),
        // _buildScreenTile('Welcome', Icons.waving_hand, () => _navigateToScreen(WelcomeScreen())),
        // _buildScreenTile('Login', Icons.login, () => _navigateToScreen(LoginScreen())),
        // _buildScreenTile('Register', Icons.person_add, () => _navigateToScreen(RegisterScreen())),
      ]),
    ];
  }

  List<Widget> _buildResidenteScreens() {
    return [
      _buildSection('Pantalla Principal', [
        // _buildScreenTile('Home', Icons.home, () => _navigateToScreen(HomeScreen())),
        _buildScreenTile('Residente Dashboard', Icons.dashboard, () => _navigateToScreen(ResidenteScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Configuración', [
        _buildScreenTile('Configuración', Icons.settings, () => _navigateToScreen(ResidenteConfigScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Selección Vivienda', Icons.home_work, () => _navigateToScreen(ResidenteSeleccionViviendaScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Comunicaciones', [
        _buildScreenTile('Mensajes', Icons.message, () => _navigateToScreen(MensajesResidenteScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Notificaciones', Icons.notifications, () => _navigateToScreen(ResidenteNotificationsScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Publicaciones', Icons.article, () => _navigateToScreen(PublicacionesResidenteScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Ver Publicación', Icons.visibility, () => _navigateToScreen(VerPublicacionScreen(
        //   publicacion: null, // Placeholder - necesita una publicación real
        //   currentUser: widget.currentUser,
        //   esAdministrador: false,
        // ))),
        _buildScreenTile('Mensajes Trabajador', Icons.work, () => _navigateToScreen(MensajesTrabajadorScreen(currentUser: widget.currentUser))),
      ]),
      _buildSection('Reclamos y Multas', [
        _buildScreenTile('Reclamos', Icons.report_problem, () => _navigateToScreen(ReclamosResidenteScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Crear Reclamo', Icons.add_box, () => _navigateToScreen(CrearReclamoScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Multas', Icons.gavel, () => _navigateToScreen(MultasResidenteScreen(currentUser: widget.currentUser))),
        // _buildScreenTile('Historial Multas', Icons.history, () => _navigateToScreen(HistorialMultasScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Correspondencia', [
        _buildScreenTile('Correspondencias', Icons.mail, () => _navigateToScreen(CorrespondenciasResidenteScreen(condominioId: widget.currentUser.condominioId!))),
        _buildScreenTile('Historial Correspondencias', Icons.history, () => _navigateToScreen(HistorialCorrespondenciasResidenteScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
      _buildSection('Servicios', [
        _buildScreenTile('Espacios Comunes', Icons.location_city, () => _navigateToScreen(EspaciosComunesResidenteScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Estacionamientos', Icons.local_parking, () => _navigateToScreen(EstacionamientosResidenteScreen())),
        _buildScreenTile('Gastos Comunes', Icons.account_balance_wallet, () => _navigateToScreen(GastosComunesResidenteScreen())),
        _buildScreenTile('Préstamos Estacionamiento', Icons.swap_horiz, () => _navigateToScreen(PrestamosEstacionamientoScreen(currentUser: widget.currentUser.toResidenteModel()))),
        _buildScreenTile('Revisiones Espacios', Icons.rate_review, () => _navigateToScreen(RevisionesEspaciosResidenteScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Selección Estacionamiento', Icons.where_to_vote, () => _navigateToScreen(SeleccionEstacionamientoResidenteScreen())),
        _buildScreenTile('Solicitar Espacio', Icons.event_available, () => _navigateToScreen(SolicitarEspacioScreen(currentUser: widget.currentUser))),
        _buildScreenTile('Visitas Bloqueadas', Icons.block, () => _navigateToScreen(VisitasBloqueadasResidenteScreen(currentUser: widget.currentUser))),
      ]),
    ];
  }

  List<Widget> _buildTrabajadorScreens() {
    // Para el widget de test, mostrar todas las pantallas de trabajador sin verificar permisos
    List<Widget> sections = [
      _buildSection('Trabajador - Pantalla Principal', [
        _buildScreenTile('Home', Icons.home, () => _navigateToScreen(HomeScreen())),
        _buildScreenTile('Trabajador Dashboard', Icons.dashboard, () => _navigateToScreen(TrabajadorScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
    ];

    // Correspondencia - Mostrar todas sin verificar permisos
    List<Widget> correspondenciaScreens = [];
    correspondenciaScreens.add(_buildScreenTile('Configuración Correspondencia', Icons.settings, () => _navigateToScreen(ConfiguracionCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))));
    correspondenciaScreens.add(_buildScreenTile('Ingresar Correspondencia', Icons.add_box, () => _navigateToScreen(IngresarCorrespondenciaScreen(condominioId: widget.currentUser.condominioId!))));
    correspondenciaScreens.add(_buildScreenTile('Correspondencias Activas', Icons.mail, () => _navigateToScreen(CorrespondenciasActivasScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))));
    correspondenciaScreens.add(_buildScreenTile('Historial Correspondencias', Icons.history, () => _navigateToScreen(HistorialCorrespondenciasScreen(condominioId: widget.currentUser.condominioId!, currentUser: widget.currentUser))));
    sections.add(_buildSection('Trabajador - Correspondencia', correspondenciaScreens));

    // Control de Acceso - Mostrar todas sin verificar permisos
    List<Widget> controlAccesoScreens = [];
    controlAccesoScreens.add(_buildScreenTile('Gestión Campos Adicionales', Icons.add_circle, () => _navigateToScreen(GestionCamposAdicionalesScreen(currentUser: widget.currentUser))));
    controlAccesoScreens.add(_buildScreenTile('Campos Activos', Icons.toggle_on, () => _navigateToScreen(CamposActivosScreen(currentUser: widget.currentUser))));
    controlAccesoScreens.add(_buildScreenTile('Formulario Control Acceso', Icons.assignment, () => _navigateToScreen(FormularioControlAccesoScreen(currentUser: widget.currentUser.toResidenteModel(), esDesdeRegistroAcceso: false))));
    controlAccesoScreens.add(_buildScreenTile('Control Diario', Icons.today, () => _navigateToScreen(ControlDiarioScreen(currentUser: widget.currentUser))));
    controlAccesoScreens.add(_buildScreenTile('Historial Control Acceso', Icons.history, () => _navigateToScreen(HistorialControlAccesoScreen(currentUser: widget.currentUser))));
    sections.add(_buildSection('Trabajador - Control de Acceso', controlAccesoScreens));

    return sections;
  }

  List<Widget> _buildComiteScreens() {
    // Para el widget de test, mostrar todas las pantallas de comité sin verificar permisos
    List<Widget> sections = [
      _buildSection('Comité - Pantalla Principal', [
        _buildScreenTile('Comité Dashboard', Icons.dashboard, () => _navigateToScreen(ComiteScreen(condominioId: widget.currentUser.condominioId!))),
      ]),
    ];

    // Agregar pantallas de gestión del comité
    List<Widget> gestionScreens = [];
    gestionScreens.add(_buildScreenTile('Gestión Comité', Icons.group, () => _navigateToScreen(GestionComiteScreen(currentUser: widget.currentUser))));
    gestionScreens.add(_buildScreenTile('Gestión Trabajadores', Icons.work, () => _navigateToScreen(GestionTrabajadoresScreen(currentUser: widget.currentUser))));
    sections.add(_buildSection('Comité - Gestión', gestionScreens));
    
    return sections;
  }

  Widget _buildSection(String title, List<Widget> screens) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: screens,
      ),
    );
  }

  Widget _buildScreenTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}