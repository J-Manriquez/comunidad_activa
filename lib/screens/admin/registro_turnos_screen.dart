import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/turno_trabajador_model.dart';
import '../../services/turnos_service.dart';
import '../../services/firestore_service.dart';

class RegistroTurnosScreen extends StatefulWidget {
  const RegistroTurnosScreen({super.key});

  @override
  State<RegistroTurnosScreen> createState() => _RegistroTurnosScreenState();
}

class _RegistroTurnosScreenState extends State<RegistroTurnosScreen> {
  final TurnosService _turnosService = TurnosService();
  final FirestoreService _firestoreService = FirestoreService();
  
  Map<String, List<TurnoTrabajador>> _turnosPorFecha = {};
  bool _isLoading = true;
  String? _condominioId;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _condominioId = await _firestoreService.getCondominioId();
      if (_condominioId != null) {
        await _cargarTurnos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar: $e')),
        );
      }
    }
  }

  Future<void> _cargarTurnos() async {
    if (_condominioId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      Map<String, List<TurnoTrabajador>> turnosPorFecha = {};
      
      // Iterar por cada día en el rango de fechas
      DateTime fechaActual = _fechaInicio;
      while (fechaActual.isBefore(_fechaFin.add(const Duration(days: 1)))) {
        String fechaStr = DateFormat('dd-MM-yyyy').format(fechaActual);
        
        try {
          final turnosDia = await _turnosService.obtenerTurnosRegistradosPorFecha(_condominioId!, fechaStr);
          if (turnosDia.isNotEmpty) {
            turnosPorFecha[fechaStr] = turnosDia;
          }
        } catch (e) {
          // Si no hay turnos para ese día, continuar
        }
        
        fechaActual = fechaActual.add(const Duration(days: 1));
      }
      
      setState(() {
        _turnosPorFecha = turnosPorFecha;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar turnos: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
      });
      await _cargarTurnos();
    }
  }

  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateFormat('dd-MM-yyyy').parse(fechaStr);
      return DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(fecha);
    } catch (e) {
      return fechaStr;
    }
  }

  String _formatearFechaCorta(String fechaStr) {
    try {
      final fecha = DateFormat('dd-MM-yyyy').parse(fechaStr);
      return DateFormat('d MMM', 'es_ES').format(fecha);
    } catch (e) {
      return fechaStr;
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'inicio':
        return Colors.green;
      case 'termino':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'inicio':
        return Icons.login;
      case 'termino':
        return Icons.logout;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar fechas de más reciente a más antigua
    final fechasOrdenadas = _turnosPorFecha.keys.toList()
      ..sort((a, b) {
        final fechaA = DateFormat('dd-MM-yyyy').parse(a);
        final fechaB = DateFormat('dd-MM-yyyy').parse(b);
        return fechaB.compareTo(fechaA); // Orden descendente
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Turnos'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarRangoFechas,
            tooltip: 'Seleccionar rango de fechas',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
          ),
        ),
        child: Column(
          children: [
            // Header con información del rango
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 48,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registro de Turnos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    '${DateFormat('d MMM yyyy').format(_fechaInicio)} - ${DateFormat('d MMM yyyy').format(_fechaFin)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de turnos por fecha
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _turnosPorFecha.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay registros de turnos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'en el rango de fechas seleccionado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarTurnos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: fechasOrdenadas.length,
                            itemBuilder: (context, index) {
                              final fecha = fechasOrdenadas[index];
                              final turnos = _turnosPorFecha[fecha]!;
                              return _buildFechaCard(fecha, turnos);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaCard(String fecha, List<TurnoTrabajador> turnos) {
    // Agrupar turnos por trabajador
    Map<String, List<TurnoTrabajador>> turnosPorTrabajador = {};
    for (var turno in turnos) {
      final key = '${turno.nombre}_${turno.uidUsuario}';
      if (!turnosPorTrabajador.containsKey(key)) {
        turnosPorTrabajador[key] = [];
      }
      turnosPorTrabajador[key]!.add(turno);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la fecha
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatearFecha(fecha),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${turnos.length} registros',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de trabajadores y sus turnos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: turnosPorTrabajador.entries.map((entry) {
                final turnosTrabajador = entry.value;
                final primerTurno = turnosTrabajador.first;
                
                // Ordenar turnos por hora
                turnosTrabajador.sort((a, b) => a.hora.compareTo(b.hora));
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del trabajador
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32),
                            radius: 16,
                            child: Text(
                              primerTurno.nombre.isNotEmpty 
                                  ? primerTurno.nombre[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primerTurno.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  primerTurno.tipoTrabajador,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Registros de turnos
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: turnosTrabajador.map((turno) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getColorEstado(turno.estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getColorEstado(turno.estado).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconoEstado(turno.estado),
                                  size: 14,
                                  color: _getColorEstado(turno.estado),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${turno.hora} - ${turno.estado}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getColorEstado(turno.estado),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}