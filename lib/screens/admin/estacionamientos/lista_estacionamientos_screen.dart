import 'package:flutter/material.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../models/estacionamiento_model.dart';

class ListaEstacionamientosScreen extends StatefulWidget {
  final String condominioId;

  const ListaEstacionamientosScreen({super.key, required this.condominioId});

  @override
  State<ListaEstacionamientosScreen> createState() => _ListaEstacionamientosScreenState();
}

class _ListaEstacionamientosScreenState extends State<ListaEstacionamientosScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  List<EstacionamientoModel> _estacionamientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstacionamientos();
  }

  Future<void> _cargarEstacionamientos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(
        widget.condominioId,
        soloVisitas: false, // Obtener todos los estacionamientos normales
      );
      
      // Ordenar por número de estacionamiento
      estacionamientos.sort((a, b) {
        final numA = int.tryParse(a.nroEstacionamiento) ?? 0;
        final numB = int.tryParse(b.nroEstacionamiento) ?? 0;
        return numA.compareTo(numB);
      });
      
      setState(() {
        _estacionamientos = estacionamientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar estacionamientos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _obtenerEstadoEstacionamiento(EstacionamientoModel estacionamiento) {
    if (estacionamiento.prestado == true) {
      return 'Prestado';
    } else if (estacionamiento.viviendaAsignada != null && estacionamiento.viviendaAsignada!.isNotEmpty) {
      return 'Asignado';
    } else {
      return 'Disponible';
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Prestado':
        return Colors.orange;
      case 'Asignado':
        return Colors.blue;
      case 'Disponible':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _construirCardEstacionamiento(EstacionamientoModel estacionamiento) {
    final estado = _obtenerEstadoEstacionamiento(estacionamiento);
    final colorEstado = _obtenerColorEstado(estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con número y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estacionamiento ${estacionamiento.nroEstacionamiento}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorEstado,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información de asignación
            if (estacionamiento.viviendaAsignada != null && estacionamiento.viviendaAsignada!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.home, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Asignado a: ${estacionamiento.viviendaAsignada}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Información de préstamo
            if (estacionamiento.prestado == true) ...[
              if (estacionamiento.viviendaPrestamo != null && estacionamiento.viviendaPrestamo!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Prestado a: ${estacionamiento.viviendaPrestamo}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Fechas de préstamo
              if (estacionamiento.fechaHoraInicio != null) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Inicio: ${_formatearFecha(estacionamiento.fechaHoraInicio!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              if (estacionamiento.fechaHoraFin != null) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Fin: ${_formatearFecha(estacionamiento.fechaHoraFin!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
            
            // Si está disponible
            if (estado == 'Disponible') ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Disponible para asignación',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fechaString) {
    try {
      final fecha = DateTime.parse(fechaString);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Estacionamientos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cargarEstacionamientos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estacionamientos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_parking,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay estacionamientos configurados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumen
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Estacionamientos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _construirEstadistica(
                                'Total',
                                _estacionamientos.length.toString(),
                                Colors.blue,
                              ),
                              _construirEstadistica(
                                'Disponibles',
                                _estacionamientos.where((e) => _obtenerEstadoEstacionamiento(e) == 'Disponible').length.toString(),
                                Colors.green,
                              ),
                              _construirEstadistica(
                                'Asignados',
                                _estacionamientos.where((e) => _obtenerEstadoEstacionamiento(e) == 'Asignado').length.toString(),
                                Colors.blue,
                              ),
                              _construirEstadistica(
                                'Prestados',
                                _estacionamientos.where((e) => _obtenerEstadoEstacionamiento(e) == 'Prestado').length.toString(),
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de estacionamientos
                    Expanded(
                      child: ListView.builder(
                        itemCount: _estacionamientos.length,
                        itemBuilder: (context, index) {
                          return _construirCardEstacionamiento(_estacionamientos[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _construirEstadistica(String titulo, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}