import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/estacionamiento_service.dart';
import '../../models/estacionamiento_model.dart';
import '../../models/user_model.dart';
import '../admin/estacionamientos/estacionamientos_visitas_screen.dart';
import 'seleccion_estacionamiento_residente_screen.dart';

class EstacionamientosResidenteScreen extends StatefulWidget {
  const EstacionamientosResidenteScreen({Key? key}) : super(key: key);

  @override
  State<EstacionamientosResidenteScreen> createState() => _EstacionamientosResidenteScreenState();
}

class _EstacionamientosResidenteScreenState extends State<EstacionamientosResidenteScreen> {
  final AuthService _authService = AuthService();
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  
  dynamic _currentUser; // Puede ser ResidenteModel o UserModel
  EstacionamientoConfigModel? _configuracion;
  EstacionamientoModel? _estacionamientoAsignado;
  List<EstacionamientoModel> _estacionamientosAsignados = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Iniciando pantalla de estacionamientos residente');
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Iniciando carga de datos');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener datos del usuario actual
      _currentUser = await _authService.getCurrentResidenteData();
      if (_currentUser == null) {
        print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Usuario no encontrado');
        throw Exception('Usuario no encontrado');
      }
      print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Usuario cargado: ${_currentUser!.nombre} - ${_currentUser!.descripcionVivienda}');
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Condominio: ${_currentUser?.condominioId}');
      
      if (_currentUser?.condominioId == null) {
        throw Exception('Usuario no tiene condominio asignado');
      }

      // Verificar si los estacionamientos están activos
      final configuracionData = await _estacionamientoService.obtenerConfiguracion(_currentUser!.condominioId!);
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Configuración obtenida: $configuracionData');
      
      if (configuracionData.isEmpty) {
        print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Configuración no encontrada');
        throw Exception('No se encontró configuración de estacionamientos');
      }

      _configuracion = EstacionamientoConfigModel.fromFirestore(configuracionData);
      print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Configuración cargada:');
      print('   - Activo: ${_configuracion!.activo}');
      print('   - Permitir selección: ${_configuracion!.permitirSeleccion}');
      print('   - Auto asignación: ${_configuracion!.autoAsignacion}');
      print('   - Permitir reservas: ${_configuracion!.permitirReservas}');
      
      if (!_configuracion!.activo) {
        print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Sistema de estacionamientos no activo');
        throw Exception('Los estacionamientos no están activos');
      }

      // Buscar estacionamientos asignados (independientemente de la configuración)
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Buscando estacionamientos asignados para vivienda: ${_currentUser!.descripcionVivienda}');
      await _buscarEstacionamientoAsignado();

      setState(() {
        _isLoading = false;
      });
      print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Datos cargados exitosamente');
    } catch (e) {
      print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Error al cargar datos: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarEstacionamientoAsignado() async {
    try {
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Iniciando búsqueda de estacionamiento asignado');
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Obteniendo lista de estacionamientos para condominio: ${_currentUser!.condominioId}');
      
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(
        _currentUser!.condominioId!,
        soloVisitas: false,
      );
      
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Total estacionamientos encontrados: ${estacionamientos.length}');
      
      // Buscar TODOS los estacionamientos asignados a la vivienda del usuario
      final viviendaUsuario = _currentUser!.descripcionVivienda;
      print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Buscando estacionamientos para vivienda: "$viviendaUsuario"');
      
      // Log de todos los estacionamientos para debug
      for (int i = 0; i < estacionamientos.length; i++) {
        final est = estacionamientos[i];
        print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Estacionamiento $i: N°${est.nroEstacionamiento} - Vivienda: "${est.viviendaAsignada}" - Es visita: ${est.estVisita}');
      }
      
      // Obtener TODOS los estacionamientos asignados a esta vivienda
      final estacionamientosAsignados = estacionamientos
          .where((est) => est.viviendaAsignada == viviendaUsuario && !est.estVisita)
          .toList();
      
      print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Estacionamientos asignados encontrados: ${estacionamientosAsignados.length}');
      for (final est in estacionamientosAsignados) {
        print('   - N°${est.nroEstacionamiento} (ID: ${est.id})');
      }
      
      // Para compatibilidad con el resto del código, usar el primer estacionamiento o crear placeholder
      _estacionamientoAsignado = estacionamientosAsignados.isNotEmpty
          ? estacionamientosAsignados.first
          : EstacionamientoModel(
              id: 'sin-asignar',
              estVisita: false,
              nroEstacionamiento: 'Sin asignar',
            );
      
      // Guardar la lista completa para mostrar en la UI
      _estacionamientosAsignados = estacionamientosAsignados;
      
      if (_estacionamientoAsignado?.nroEstacionamiento == 'Sin asignar') {
        print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Resultado: No se encontró estacionamiento asignado para la vivienda');
      } else {
        print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Resultado: Estacionamiento asignado encontrado - N°${_estacionamientoAsignado!.nroEstacionamiento}');
        print('🟢 [ESTACIONAMIENTOS_RESIDENTE] Detalles del estacionamiento:');
        print('   - ID: ${_estacionamientoAsignado!.id}');
        print('   - Número: ${_estacionamientoAsignado!.nroEstacionamiento}');
        print('   - Vivienda asignada: ${_estacionamientoAsignado!.viviendaAsignada}');
        print('   - Es visita: ${_estacionamientoAsignado!.estVisita}');
        print('   - Prestado: ${_estacionamientoAsignado!.prestado}');
      }
    } catch (e) {
      print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Error al buscar estacionamiento asignado: $e');
      print('🔴 [ESTACIONAMIENTOS_RESIDENTE] Stack trace: ${StackTrace.current}');
      _estacionamientoAsignado = EstacionamientoModel(
        id: 'sin-asignar',
        estVisita: false,
        nroEstacionamiento: 'Sin asignar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estacionamientos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Refrescando datos');
              await _cargarDatos();
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estacionamientos...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estacionamientos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_configuracion == null) {
      return const Center(
        child: Text('No se pudo cargar la configuración'),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfiguracionInfo(),
            const SizedBox(height: 20),
            ..._buildEstacionamientoUnificado(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Información del Sistema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Modo de asignación', 
              _configuracion!.permitirSeleccion ? 'Selección libre' : 'Asignación fija'),
            if (_configuracion!.permitirSeleccion)
              _buildInfoRow('Auto-asignación', 
                _configuracion!.autoAsignacion ? 'Activada' : 'Requiere aprobación'),
            _buildInfoRow('Estacionamientos de visitas', 
              _configuracion!.estVisitas ? 'Disponibles' : 'No disponibles'),
            if (_configuracion!.estVisitas)
              _buildInfoRow('Reservas de visitas', 
                _configuracion!.permitirReservas ? 'Permitidas' : 'Solo uso inmediato'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEstacionamientoUnificado() {
    return [
      Text(
        'Mi Estacionamiento',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      
      // Card unificada para mostrar estacionamiento actual
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _estacionamientosAsignados.isEmpty
                        ? Colors.grey[100]
                        : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _estacionamientosAsignados.isEmpty
                        ? Icons.block
                        : Icons.local_parking,
                      color: _estacionamientosAsignados.isEmpty
                        ? Colors.grey[600]
                        : Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estacionamiento Actual',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _estacionamientosAsignados.isEmpty
                            ? 'No tienes estacionamientos asignados'
                            : _estacionamientosAsignados.length == 1
                              ? 'Estacionamiento N° ${_estacionamientosAsignados.first.nroEstacionamiento}'
                              : 'Estacionamientos: ${_estacionamientosAsignados.map((e) => e.nroEstacionamiento).join(", ")}',
                          style: TextStyle(
                            color: _estacionamientosAsignados.isEmpty
                              ? Colors.grey[600]
                              : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_estacionamientosAsignados.any((e) => e.prestado == true)) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'En uso',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 12),
      
      // Card para gestionar estacionamiento (solo si permite selección)
      if (_configuracion!.permitirSeleccion)
        Card(
          child: InkWell(
            onTap: () {
              print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Usuario tocó card de gestión de estacionamiento');
              print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Navegando a SeleccionEstacionamientoResidenteScreen');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeleccionEstacionamientoResidenteScreen(),
                ),
              ).then((_) {
                print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Regresando de selección de estacionamiento, recargando datos');
                _cargarDatos(); // Recargar al volver
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestionar Estacionamiento',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seleccionar o cambiar estacionamiento',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      
      const SizedBox(height: 12),
      
      // Card para solicitar estacionamiento de visitas
      if (_configuracion!.estVisitas) _buildCardSolicitarVisitas(),
    ];
  }



  Widget _buildCardSolicitarVisitas() {
    return Card(
      child: InkWell(
        onTap: () {
          print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Usuario tocó card de estacionamientos de visitas');
          print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Navegando a EstacionamientosVisitasScreen en modo residente');
          print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Configuración de visitas:');
          print('   - Estacionamientos de visitas activos: ${_configuracion!.estVisitas}');
          print('   - Permitir reservas: ${_configuracion!.permitirReservas}');
          print('🟡 [ESTACIONAMIENTOS_RESIDENTE] Datos del residente para modo visitas:');
          print('   - ID: ${_currentUser!.uid}');
          print('   - Nombre: ${_currentUser!.nombre}');
          print('   - Vivienda: ${_currentUser!.descripcionVivienda}');
          print('   - Condominio: ${_currentUser!.condominioId}');
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EstacionamientosVisitasScreen(
                modoResidente: true,
                datosResidente: {
                  'id': _currentUser!.uid,
                  'nombre': _currentUser!.nombre,
                  'vivienda': _currentUser!.descripcionVivienda,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_add,
                  color: Colors.purple[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitar Estacionamiento de Visitas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reserva un espacio para tus visitantes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}