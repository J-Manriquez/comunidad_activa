import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/estacionamiento_service.dart';
import '../../services/firestore_service.dart';
import '../../models/estacionamiento_model.dart';
import '../../models/user_model.dart';
import '../../models/residente_model.dart';

class PrestamosEstacionamientoScreen extends StatefulWidget {
  final ResidenteModel currentUser;

  const PrestamosEstacionamientoScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<PrestamosEstacionamientoScreen> createState() =>
      _PrestamosEstacionamientoScreenState();
}

class _PrestamosEstacionamientoScreenState
    extends State<PrestamosEstacionamientoScreen> {
  final EstacionamientoService _estacionamientoService =
      EstacionamientoService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  List<EstacionamientoModel> _misEstacionamientos = [];
  List<Map<String, dynamic>> _residentes = [];
  EstacionamientoModel? _estacionamientoSeleccionado;
  Map<String, dynamic>? _residenteSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar estacionamientos del usuario
      await _cargarMisEstacionamientos();

      // Cargar residentes
      await _cargarResidentes();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarMisEstacionamientos() async {
    final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(
      widget.currentUser.condominioId!,
      soloVisitas: false,
    );

    // Filtrar solo los estacionamientos asignados al usuario actual
    final misEstacionamientos = estacionamientos
        .where((est) => est.viviendaAsignada == widget.currentUser.descripcionVivienda)
        .toList();

    setState(() {
      _misEstacionamientos = misEstacionamientos;
      // Si solo tiene un estacionamiento, seleccionarlo automáticamente
      if (_misEstacionamientos.length == 1) {
        _estacionamientoSeleccionado = _misEstacionamientos.first;
      }
    });
  }

  Future<void> _cargarResidentes() async {
    try {
      final residentes = await _firestoreService.obtenerResidentesConVivienda(
        widget.currentUser.condominioId!,
      );

      // Filtrar al usuario actual
      final residentesFiltrados = residentes
          .where((residente) => residente['uid'] != widget.currentUser.uid)
          .toList();

      setState(() {
        _residentes = residentesFiltrados;
      });
    } catch (e) {
      print('Error al cargar residentes: $e');
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      final TimeOfDay? horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (horaSeleccionada != null) {
        final fechaCompleta = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          fechaSeleccionada.day,
          horaSeleccionada.hour,
          horaSeleccionada.minute,
        );

        setState(() {
          if (esInicio) {
            _fechaInicio = fechaCompleta;
            // Si la fecha de fin es anterior a la de inicio, resetearla
            if (_fechaFin != null && _fechaFin!.isBefore(fechaCompleta)) {
              _fechaFin = null;
            }
          } else {
            _fechaFin = fechaCompleta;
          }
        });
      }
    }
  }

  Future<void> _guardarPrestamo() async {
    if (_estacionamientoSeleccionado == null ||
        _residenteSeleccionado == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior a la fecha de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Debug: Imprimir datos antes de guardar
      print('🔍 Datos del préstamo:');
      print('  - Estacionamiento ID: ${_estacionamientoSeleccionado!.id}');
      print('  - Fecha inicio: ${_fechaInicio!.toIso8601String()}');
      print('  - Fecha fin: ${_fechaFin!.toIso8601String()}');
      print('  - Residente seleccionado: $_residenteSeleccionado');
      print('  - Vivienda préstamo: ${_residenteSeleccionado!['vivienda']}');
      
      final datosActualizacion = {
        'fechaHoraInicio': _fechaInicio!.toIso8601String(),
        'fechaHoraFin': _fechaFin!.toIso8601String(),
        'prestado': true,
        'viviendaPrestamo': _residenteSeleccionado!['vivienda'],
      };
      
      print('  - Datos a actualizar: $datosActualizacion');
      
      // Actualizar el estacionamiento con los datos del préstamo
      final resultado = await _estacionamientoService.actualizarEstacionamiento(
        widget.currentUser.condominioId!,
        _estacionamientoSeleccionado!.id,
        datosActualizacion,
      );
      
      print('  - Resultado actualización: $resultado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préstamo registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error al guardar préstamo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar préstamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Prestar Estacionamiento'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prestar Estacionamiento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selección de estacionamiento (solo si tiene más de uno)
              if (_misEstacionamientos.length > 1) ...[
                _buildSeccionSeleccionEstacionamiento(),
                const SizedBox(height: 24),
              ],

              // Selección de residente
              _buildSeccionSeleccionResidente(),
              const SizedBox(height: 24),

              // Selección de fechas
              _buildSeccionFechas(),
              const SizedBox(height: 32),

              // Botón guardar
              _buildBotonGuardar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionSeleccionEstacionamiento() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_parking,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selecciona tu estacionamiento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _misEstacionamientos.length,
              itemBuilder: (context, index) {
                final estacionamiento = _misEstacionamientos[index];
                final isSelected = _estacionamientoSeleccionado?.id == estacionamiento.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _estacionamientoSeleccionado = estacionamiento;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_parking,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estacionamiento.nroEstacionamiento,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionSeleccionResidente() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.person,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selecciona el residente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_residentes.isEmpty)
              const Text(
                'No hay residentes disponibles',
                style: TextStyle(color: Colors.grey),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: _residentes.length,
                itemBuilder: (context, index) {
                  final residente = _residentes[index];
                  final isSelected = _residenteSeleccionado?['uid'] == residente['uid'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _residenteSeleccionado = residente;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            residente['nombre'] ?? 'Sin nombre',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vivienda ${residente['vivienda']}',
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey.shade600,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFechas() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.calendar_today,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Período del préstamo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCampoFecha(
                    'Desde',
                    _fechaInicio,
                    () => _seleccionarFecha(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCampoFecha(
                    'Hasta',
                    _fechaFin,
                    () => _seleccionarFecha(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoFecha(String label, DateTime? fecha, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fecha != null ? _formatearFecha(fecha) : 'Seleccionar',
              style: TextStyle(
                fontSize: 14,
                color: fecha != null ? Colors.grey.shade800 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    final bool puedeGuardar = _estacionamientoSeleccionado != null &&
        _residenteSeleccionado != null &&
        _fechaInicio != null &&
        _fechaFin != null &&
        !_isProcessing;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: puedeGuardar ? _guardarPrestamo : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Registrar Préstamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}