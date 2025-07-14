import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/estacionamiento_service.dart';
import '../../services/notification_service.dart';
import '../../models/estacionamiento_model.dart';
import '../../models/user_model.dart';
import '../../widgets/pagination_widget.dart';

class SeleccionEstacionamientoResidenteScreen extends StatefulWidget {
  const SeleccionEstacionamientoResidenteScreen({Key? key}) : super(key: key);

  @override
  State<SeleccionEstacionamientoResidenteScreen> createState() => _SeleccionEstacionamientoResidenteScreenState();
}

class _SeleccionEstacionamientoResidenteScreenState extends State<SeleccionEstacionamientoResidenteScreen> {
  final AuthService _authService = AuthService();
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _numeroController = TextEditingController();
  
  dynamic _currentUser; // Puede ser ResidenteModel o UserModel
  EstacionamientoConfigModel? _configuracion;
  List<EstacionamientoModel> _estacionamientosDisponibles = [];
  List<EstacionamientoModel> _estacionamientosAsignados = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Set<String> _selectedNumbers = {};
  int _currentGroup = 0;
  int _itemsPerGroup = 10;

  @override
  void initState() {
    super.initState();
    print('🟡 [SELECCION_ESTACIONAMIENTO] Iniciando pantalla de selección de estacionamiento');
    _cargarDatos();
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      print('🟡 [SELECCION_ESTACIONAMIENTO] Iniciando carga de datos');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener datos del usuario actual
      print('🟡 [SELECCION_ESTACIONAMIENTO] Obteniendo datos del usuario actual');
      _currentUser = await _authService.getCurrentResidenteData();
      if (_currentUser == null) {
        print('🔴 [SELECCION_ESTACIONAMIENTO] Usuario no encontrado');
        throw Exception('Usuario no encontrado');
      }
      print('🟢 [SELECCION_ESTACIONAMIENTO] Usuario cargado: ${_currentUser!.nombre} - ${_currentUser!.descripcionVivienda}');
      print('🟡 [SELECCION_ESTACIONAMIENTO] Condominio: ${_currentUser!.condominioId}');
      
      if (_currentUser?.condominioId == null) {
        print('🔴 [SELECCION_ESTACIONAMIENTO] Usuario no tiene condominio asignado');
        throw Exception('Usuario no tiene condominio asignado');
      }

      // Obtener configuración
      print('🟡 [SELECCION_ESTACIONAMIENTO] Obteniendo configuración de estacionamientos');
      final configuracionData = await _estacionamientoService.obtenerConfiguracion(_currentUser!.condominioId!);
      if (configuracionData == null) {
        print('🔴 [SELECCION_ESTACIONAMIENTO] Configuración no encontrada');
        throw Exception('Configuración de estacionamientos no encontrada');
      }
      _configuracion = EstacionamientoConfigModel.fromFirestore(configuracionData);
      print('🟢 [SELECCION_ESTACIONAMIENTO] Configuración cargada:');
      print('   - Permitir selección: ${_configuracion!.permitirSeleccion}');
      print('   - Auto asignación: ${_configuracion!.autoAsignacion}');
      print('   - Activo: ${_configuracion!.activo}');
      
      // Obtener estacionamientos disponibles y asignados
      print('🟡 [SELECCION_ESTACIONAMIENTO] Obteniendo lista de estacionamientos');
      final todosEstacionamientos = await _estacionamientoService.obtenerEstacionamientos(
        _currentUser!.condominioId!,
        soloVisitas: false,
      );
      print('🟡 [SELECCION_ESTACIONAMIENTO] Total estacionamientos encontrados: ${todosEstacionamientos.length}');
      
      _estacionamientosDisponibles = todosEstacionamientos
          .where((est) => est.viviendaAsignada == null || est.viviendaAsignada!.isEmpty)
          .toList();
      
      _estacionamientosAsignados = todosEstacionamientos
          .where((est) => est.viviendaAsignada == _currentUser!.descripcionVivienda)
          .toList();
      
      print('🟢 [SELECCION_ESTACIONAMIENTO] Estacionamientos disponibles: ${_estacionamientosDisponibles.length}');
      print('🟢 [SELECCION_ESTACIONAMIENTO] Estacionamientos asignados: ${_estacionamientosAsignados.length}');
      for (final est in _estacionamientosDisponibles) {
        print('   - Disponible N°${est.nroEstacionamiento} (ID: ${est.id})');
      }
      for (final est in _estacionamientosAsignados) {
        print('   - Asignado N°${est.nroEstacionamiento} (ID: ${est.id})');
      }
      
      // Ordenar por número
      _estacionamientosDisponibles.sort((a, b) {
        final numA = int.tryParse(a.nroEstacionamiento) ?? 0;
        final numB = int.tryParse(b.nroEstacionamiento) ?? 0;
        return numA.compareTo(numB);
      });

      setState(() {
        _isLoading = false;
        // Resetear la página actual si está fuera del rango válido usando grupos lógicos
        final grupos = _calcularGruposLogicos();
        final maxGroup = grupos.isNotEmpty ? grupos.length - 1 : 0;
        _currentGroup = _currentGroup.clamp(0, maxGroup);
      });
      print('🟢 [SELECCION_ESTACIONAMIENTO] Datos cargados exitosamente');
    } catch (e) {
      print('🔴 [SELECCION_ESTACIONAMIENTO] Error al cargar datos: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarEstacionamientos() async {
    print('🟡 [SELECCION_ESTACIONAMIENTO] Iniciando procesamiento de selecciones');
    if (_selectedNumbers.isEmpty) {
      print('🔴 [SELECCION_ESTACIONAMIENTO] No se ha seleccionado ningún estacionamiento');
      _mostrarSnackBar('Por favor selecciona al menos un estacionamiento', isError: true);
      return;
    }

    print('🟡 [SELECCION_ESTACIONAMIENTO] Números seleccionados: ${_selectedNumbers.join(", ")}');

    // Verificar que todos los estacionamientos estén disponibles
    final estacionamientosSeleccionados = <EstacionamientoModel>[];
    for (final numero in _selectedNumbers) {
      final estacionamiento = _estacionamientosDisponibles
          .where((est) => est.nroEstacionamiento == numero)
          .firstOrNull;
      
      if (estacionamiento == null) {
        print('🔴 [SELECCION_ESTACIONAMIENTO] Estacionamiento N°$numero no encontrado en disponibles');
        _mostrarSnackBar('El estacionamiento N°$numero no está disponible', isError: true);
        return;
      }
      estacionamientosSeleccionados.add(estacionamiento);
    }

    print('🟢 [SELECCION_ESTACIONAMIENTO] Todos los estacionamientos están disponibles');
    print('🟡 [SELECCION_ESTACIONAMIENTO] Modo de asignación: ${!_configuracion!.autoAsignacion ? "Automática" : "Requiere aprobación"}');

    try {
      setState(() {
        _isProcessing = true;
      });

      // Corregir la lógica: si autoAsignacion es false, se asigna automáticamente
      // si autoAsignacion es true, requiere aprobación del administrador
      if (!_configuracion!.autoAsignacion) {
        print('🟡 [SELECCION_ESTACIONAMIENTO] Procesando asignación automática (autoAsignacion=false)');
        // Asignación automática
        for (final estacionamiento in estacionamientosSeleccionados) {
          await _asignarEstacionamientoDirectamente(estacionamiento);
        }
      } else {
        print('🟡 [SELECCION_ESTACIONAMIENTO] Enviando solicitudes al administrador (autoAsignacion=true)');
        // Enviar solicitudes al administrador
        for (final estacionamiento in estacionamientosSeleccionados) {
          await _enviarSolicitudAdministrador(estacionamiento);
        }
      }
    } catch (e) {
      print('🔴 [SELECCION_ESTACIONAMIENTO] Error al procesar selecciones: $e');
      _mostrarSnackBar('Error al procesar las selecciones: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _asignarEstacionamientoDirectamente(EstacionamientoModel estacionamiento) async {
    try {
      print('🟡 [SELECCION_ESTACIONAMIENTO] Iniciando asignación directa');
      print('🟡 [SELECCION_ESTACIONAMIENTO] Datos de asignación:');
      print('   - Estacionamiento ID: ${estacionamiento.id}');
      print('   - Número estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('   - Condominio ID: ${_currentUser!.condominioId}');
      print('   - Descripción vivienda: ${_currentUser!.descripcionVivienda}');
      print('   - Usuario ID: ${_currentUser!.uid}');
      print('   - Nombre usuario: ${_currentUser!.nombre}');
      
      print('🟡 [SELECCION_ESTACIONAMIENTO] Actualizando estacionamiento en base de datos');
      await _estacionamientoService.actualizarEstacionamiento(
        _currentUser!.condominioId!,
        estacionamiento.id,
        {
          'viviendaAsignada': _currentUser!.descripcionVivienda,
          'fechaAsignacion': DateTime.now().toIso8601String(),
        },
      );
      
      print('🟢 [SELECCION_ESTACIONAMIENTO] Estacionamiento asignado exitosamente en base de datos');
      
      _mostrarSnackBar('Estacionamiento ${estacionamiento.nroEstacionamiento} asignado exitosamente');
      
      print('🟢 [SELECCION_ESTACIONAMIENTO] Asignación directa completada, regresando a pantalla anterior');
      // Volver a la pantalla anterior
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('🔴 [SELECCION_ESTACIONAMIENTO] Error en asignación directa: $e');
      throw Exception('Error al asignar estacionamiento: $e');
    }
  }

  Future<void> _enviarSolicitudAdministrador(EstacionamientoModel estacionamiento) async {
    try {
      print('🟡 [SELECCION_ESTACIONAMIENTO] Iniciando envío de solicitud al administrador');
      print('🟡 [SELECCION_ESTACIONAMIENTO] Datos de solicitud:');
      print('   - Estacionamiento ID: ${estacionamiento.id}');
      print('   - Número estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('   - Solicitante ID: ${_currentUser!.uid}');
      print('   - Solicitante nombre: ${_currentUser!.nombre}');
      print('   - Solicitante vivienda: ${_currentUser!.descripcionVivienda}');
      print('   - Condominio ID: ${_currentUser!.condominioId}');
      
      // Actualizar el estacionamiento con la solicitud pendiente
      print('🟡 [SELECCION_ESTACIONAMIENTO] Actualizando estado del estacionamiento a "pendiente"');
      await _estacionamientoService.actualizarEstacionamiento(
        _currentUser!.condominioId!,
        estacionamiento.id,
        {
          'estadoSolicitud': 'pendiente',
          'fechaHoraSolicitud': DateTime.now().toIso8601String(),
          'idSolicitante': [_currentUser!.uid],
          'nombreSolicitante': [_currentUser!.nombre],
          'viviendaSolicitante': [_currentUser!.descripcionVivienda],
        },
      );
      print('🟢 [SELECCION_ESTACIONAMIENTO] Estado del estacionamiento actualizado exitosamente');
      
      // Enviar notificación al administrador
      print('🟡 [SELECCION_ESTACIONAMIENTO] Enviando notificación al administrador');
      await _notificationService.createCondominioNotification(
        condominioId: _currentUser!.condominioId!,
        tipoNotificacion: 'solicitud_estacionamiento',
        contenido: '${_currentUser!.nombre} (${_currentUser!.descripcionVivienda}) solicita el estacionamiento N° ${estacionamiento.nroEstacionamiento}',
        additionalData: {
          'estacionamientoId': estacionamiento.id,
          'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
          'solicitanteId': _currentUser!.uid,
          'solicitanteNombre': _currentUser!.nombre,
          'solicitanteVivienda': _currentUser!.descripcionVivienda,
        },
      );
      print('🟢 [SELECCION_ESTACIONAMIENTO] Notificación enviada al administrador exitosamente');
      
      print('🟢 [SELECCION_ESTACIONAMIENTO] Solicitud completada exitosamente');
      
      _mostrarSnackBar('Solicitud enviada al administrador. Recibirás una notificación con la respuesta.');
      
      print('🟢 [SELECCION_ESTACIONAMIENTO] Regresando a pantalla anterior');
      // Volver a la pantalla anterior
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('🔴 [SELECCION_ESTACIONAMIENTO] Error al enviar solicitud: $e');
      throw Exception('Error al enviar solicitud: $e');
    }
  }

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Estacionamiento'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
            Text('Cargando estacionamientos disponibles...'),
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
              'Error al cargar datos',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildEstacionamientosDisponibles(),
          const SizedBox(height: 20),
          _buildSeleccionForm(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
                  'Información',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Vivienda: ${_currentUser?.descripcionVivienda ?? 'No asignada'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              !_configuracion!.autoAsignacion
                ? 'La asignación será automática una vez selecciones estacionamientos.'
                : 'Tus solicitudes serán enviadas al administrador para aprobación.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_estacionamientosAsignados.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Estacionamientos asignados: ${_estacionamientosAsignados.map((e) => e.nroEstacionamiento).join(", ")}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Método para calcular grupos basados en rangos de números
  List<Map<String, dynamic>> _calcularGruposLogicos() {
    if (_estacionamientosDisponibles.isEmpty) return [];
    
    // Obtener todos los números de estacionamientos disponibles
    final numeros = _estacionamientosDisponibles
        .map((e) => int.tryParse(e.nroEstacionamiento) ?? 0)
        .where((n) => n > 0)
        .toList();
    
    if (numeros.isEmpty) return [];
    
    numeros.sort();
    final maxNumero = numeros.last;
    
    // Crear grupos basados en rangos de 10 (1-10, 11-20, etc.)
    final grupos = <Map<String, dynamic>>[];
    for (int i = 1; i <= maxNumero; i += _itemsPerGroup) {
      final rangoInicio = i;
      final rangoFin = (i + _itemsPerGroup - 1).clamp(i, maxNumero);
      
      // Filtrar estacionamientos que están en este rango
      final estacionamientosEnRango = _estacionamientosDisponibles
          .where((est) {
            final num = int.tryParse(est.nroEstacionamiento) ?? 0;
            return num >= rangoInicio && num <= rangoFin;
          })
          .toList();
      
      // Ordenar estacionamientos por número dentro del grupo
      estacionamientosEnRango.sort((a, b) {
        final numA = int.tryParse(a.nroEstacionamiento) ?? 0;
        final numB = int.tryParse(b.nroEstacionamiento) ?? 0;
        return numA.compareTo(numB);
      });
      
      // Solo agregar el grupo si tiene al menos un estacionamiento
      if (estacionamientosEnRango.isNotEmpty) {
        grupos.add({
          'inicio': rangoInicio,
          'fin': rangoFin,
          'estacionamientos': estacionamientosEnRango,
          'label': '$rangoInicio-$rangoFin',
        });
      }
    }
    
    return grupos;
  }

  Widget _buildEstacionamientosDisponibles() {
    if (_estacionamientosDisponibles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estacionamientos Disponibles (0)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No hay estacionamientos disponibles en este momento.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final grupos = _calcularGruposLogicos();
    final totalGroups = grupos.length;
    final validCurrentGroup = _currentGroup.clamp(0, totalGroups - 1);
    final currentGroupItems = grupos.isNotEmpty ? grupos[validCurrentGroup]['estacionamientos'] as List<EstacionamientoModel> : <EstacionamientoModel>[];
    final currentGroupLabel = grupos.isNotEmpty ? grupos[validCurrentGroup]['label'] as String : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estacionamientos Disponibles (${_estacionamientosDisponibles.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
          // Barra de grupos con rangos lógicos
          if (totalGroups > 1)
            Container(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalGroups,
                itemBuilder: (context, index) {
                  final grupo = grupos[index];
                  final isSelected = index == validCurrentGroup;
                  final label = grupo['label'] as String;
                  final cantidadEnGrupo = (grupo['estacionamientos'] as List).length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (index != _currentGroup) {
                          setState(() {
                            _currentGroup = index;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue[900]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          '$label ($cantidadEnGrupo)',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
          // Estacionamientos del grupo actual
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentGroupItems.map((estacionamiento) {
              final isSelected = _selectedNumbers.contains(estacionamiento.nroEstacionamiento);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedNumbers.remove(estacionamiento.nroEstacionamiento);
                    } else {
                      _selectedNumbers.add(estacionamiento.nroEstacionamiento);
                    }
                    _numeroController.text = _selectedNumbers.join(', ');
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[900]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      estacionamiento.nroEstacionamiento,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSeleccionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Estacionamientos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vivienda:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _currentUser?.descripcionVivienda ?? 'No asignada',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estacionamientos Seleccionados (${_selectedNumbers.length}):',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _numeroController,
                        decoration: InputDecoration(
                          hintText: 'Toca los estacionamientos arriba',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        readOnly: true,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing || _estacionamientosDisponibles.isEmpty || _selectedNumbers.isEmpty
                    ? null
                    : _seleccionarEstacionamientos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Procesando...'),
                        ],
                      )
                    : Text(
                        _configuracion!.autoAsignacion
                            ? 'Enviar Solicitudes (${_selectedNumbers.length})'
                            : 'Asignar Estacionamientos (${_selectedNumbers.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}