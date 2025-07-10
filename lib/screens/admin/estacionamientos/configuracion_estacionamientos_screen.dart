import 'package:flutter/material.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../models/estacionamiento_model.dart';
import 'modal_configurar_estacionamientos.dart';

class ConfiguracionEstacionamientosScreen extends StatefulWidget {
  final String condominioId;

  const ConfiguracionEstacionamientosScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<ConfiguracionEstacionamientosScreen> createState() =>
      _ConfiguracionEstacionamientosScreenState();
}

class _ConfiguracionEstacionamientosScreenState
    extends State<ConfiguracionEstacionamientosScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  
  bool _isLoading = true;
  bool _permitirSeleccion = false;
  bool _autoAsignacion = false;
  bool _estVisitas = false;
  
  EstacionamientoConfigModel? _configuracion;
  List<String> _numeracionActual = [];
  List<String> _numeracionVisitasActual = [];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final configuracion = await _estacionamientoService
          .obtenerConfiguracion(widget.condominioId);
      
      if (mounted) {
        setState(() {
          _configuracion = configuracion;
          _permitirSeleccion = configuracion?.permitirSeleccion ?? false;
          _autoAsignacion = configuracion?.autoAsignacion ?? false;
          _estVisitas = configuracion?.estVisitas ?? false;
          _numeracionActual = configuracion?.numeracion ?? [];
          _numeracionVisitasActual = configuracion?.numeracionEstVisitas ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actualizarPermitirSeleccion(bool value) async {
    try {
      await _estacionamientoService.actualizarConfiguracionSeleccion(
        widget.condominioId,
        value,
        _autoAsignacion,
      );
      
      setState(() {
        _permitirSeleccion = value;
        if (!value) {
          _autoAsignacion = false;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Selección de estacionamientos habilitada'
                : 'Selección de estacionamientos deshabilitada',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarAutoAsignacion(bool value) async {
    try {
      await _estacionamientoService.actualizarConfiguracionSeleccion(
        widget.condominioId,
        _permitirSeleccion,
        value,
      );
      
      setState(() {
        _autoAsignacion = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto-asignación activada (requiere aprobación)'
                : 'Auto-asignación desactivada',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarEstVisitas(bool value) async {
    try {
      await _estacionamientoService.cambiarEstadoEstacionamientosVisitas(
        widget.condominioId,
        value,
      );
      
      setState(() {
        _estVisitas = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Estacionamientos de visitas activados'
                : 'Estacionamientos de visitas desactivados',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarModalConfiguracion({bool esVisita = false}) {
    showDialog(
      context: context,
      builder: (context) => ModalConfigurarEstacionamientos(
        condominioId: widget.condominioId,
        esVisita: esVisita,
        numeracionActual: esVisita ? _numeracionVisitasActual : _numeracionActual,
        onConfiguracionGuardada: () {
          _cargarConfiguracion();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Estacionamientos'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración de Estacionamientos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de configuración de selección
              _buildSeleccionCard(),
              
              const SizedBox(height: 16),
              
              // Card de configuración de estacionamientos
              _buildEstacionamientosCard(),
              
              const SizedBox(height: 16),
              
              // Card de estacionamientos de visitas
              _buildEstacionamientosVisitasCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeleccionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Selección de Estacionamientos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _permitirSeleccion,
                  onChanged: _actualizarPermitirSeleccion,
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _permitirSeleccion
                  ? 'Los residentes pueden seleccionar su estacionamiento'
                  : 'Los estacionamientos se asignan automáticamente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            // Sub-switch para auto-asignación
            if (_permitirSeleccion) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.approval,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requiere Aprobación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Las selecciones necesitan aprobación del administrador',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _autoAsignacion,
                      onChanged: _actualizarAutoAsignacion,
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstacionamientosCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _mostrarModalConfiguracion(esVisita: false),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configurar Estacionamientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _numeracionActual.isEmpty
                    ? 'Toca para configurar los números de estacionamientos'
                    : 'Estacionamientos configurados: ${_numeracionActual.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_numeracionActual.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _numeracionActual.take(10).map((numero) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        numero,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(_numeracionActual.length > 10
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${_numeracionActual.length - 10} más',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]
                        : []),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstacionamientosVisitasCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.purple.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.car_rental,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Estacionamientos de Visitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _estVisitas,
                  onChanged: _actualizarEstVisitas,
                  activeColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _estVisitas
                  ? 'Los residentes pueden solicitar estacionamientos para visitas'
                  : 'Los estacionamientos de visitas están desactivados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            // Card para configurar estacionamientos de visitas
            if (_estVisitas) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _mostrarModalConfiguracion(esVisita: true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Colors.purple,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Configurar Estacionamientos de Visitas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.purple,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _numeracionVisitasActual.isEmpty
                            ? 'Toca para configurar los números de estacionamientos de visitas'
                            : 'Estacionamientos de visitas: ${_numeracionVisitasActual.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_numeracionVisitasActual.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _numeracionVisitasActual.take(8).map((numero) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                numero,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList()
                            ..addAll(_numeracionVisitasActual.length > 8
                                ? [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${_numeracionVisitasActual.length - 8}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ]
                                : []),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}