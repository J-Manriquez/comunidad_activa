import 'package:flutter/material.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../models/estacionamiento_model.dart';
import '../../../widgets/pagination_widget.dart';

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
  int _paginaActual = 0;
  final int _elementosPorPagina = 10;
  bool _mostrarResumen = true;
  
  int get _totalPaginas => (_estacionamientos.length / _elementosPorPagina).ceil();
  
  List<EstacionamientoModel> get _estacionamientosPaginaActual {
    final inicio = _paginaActual * _elementosPorPagina;
    final fin = (inicio + _elementosPorPagina).clamp(0, _estacionamientos.length);
    return _estacionamientos.sublist(inicio, fin);
  }

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
        // Resetear página actual si está fuera de rango
        final maxPagina = (_estacionamientos.length / _elementosPorPagina).ceil() - 1;
        if (_paginaActual > maxPagina) {
          _paginaActual = maxPagina.clamp(0, maxPagina);
        }
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
  
  Color _obtenerColorFondo(String estado) {
    switch (estado) {
      case 'Prestado':
        return Colors.orange.shade50;
      case 'Asignado':
        return Colors.blue.shade50;
      case 'Disponible':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
  
  Color _obtenerColorBorde(String estado) {
    switch (estado) {
      case 'Prestado':
        return Colors.orange.shade200;
      case 'Asignado':
        return Colors.blue.shade200;
      case 'Disponible':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _construirCardEstacionamiento(EstacionamientoModel estacionamiento) {
    final estado = _obtenerEstadoEstacionamiento(estacionamiento);
    final colorEstado = _obtenerColorEstado(estado);
    final colorFondo = _obtenerColorFondo(estado);
    final colorBorde = _obtenerColorBorde(estado);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorBorde, width: 2),
      ),
      color: colorFondo,
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado con número y estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estacionamiento ${estacionamiento.nroEstacionamiento}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                  const SizedBox(height: 8),
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
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            
            // Información de asignación
            if (estacionamiento.viviendaAsignada != null && estacionamiento.viviendaAsignada!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asignado a: ${estacionamiento.viviendaAsignada}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
              // Información de préstamo
              if (estacionamiento.prestado == true) ...[
                if (estacionamiento.viviendaPrestamo != null && estacionamiento.viviendaPrestamo!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prestado a: ${estacionamiento.viviendaPrestamo}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              
                // Fechas de préstamo
                if (estacionamiento.fechaHoraInicio != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inicio: ${_formatearFecha(estacionamiento.fechaHoraInicio!)}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                
                if (estacionamiento.fechaHoraFin != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fin: ${_formatearFecha(estacionamiento.fechaHoraFin!)}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            
              // Si está disponible
              if (estado == 'Disponible') ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disponible para asignación',
                        style: const TextStyle(fontSize: 14, color: Colors.green),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
  
  Widget _construirNavegacionPaginas() {
    if (_totalPaginas <= 1) {
      return const SizedBox.shrink();
    }
    
    return PaginationWidget(
      currentPage: (_paginaActual + 1).clamp(1, _totalPaginas),
      totalPages: _totalPaginas,
      itemsPerPage: _elementosPorPagina,
      totalItems: _estacionamientos.length,
      onPageChanged: (int page) {
        final nuevaPagina = (page - 1).clamp(0, _totalPaginas - 1);
        if (nuevaPagina != _paginaActual) {
          setState(() {
            _paginaActual = nuevaPagina;
          });
        }
      },
      groupLabel: '',
    );
  }
  
  Widget _construirGridEstacionamientos() {
    final estacionamientosPagina = _estacionamientosPaginaActual;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: estacionamientosPagina.map((estacionamiento) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 32) / 2,
            child: _construirCardEstacionamiento(estacionamiento),
          );
        }).toList(),
      ),
    );
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
              : SingleChildScrollView(
                  child: Column(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Resumen de Estacionamientos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarResumen = !_mostrarResumen;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarResumen ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.blue.shade700,
                                  ),
                                  tooltip: _mostrarResumen ? 'Ocultar resumen' : 'Mostrar resumen',
                                ),
                              ],
                            ),
                            if (_mostrarResumen) ...[
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
                              const SizedBox(height: 8),
                              
                            ],
                          ],
                        ),
                      ),
                      
                      // Navegación de páginas
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: _construirNavegacionPaginas(),
                      ),
                      
                      // Grid de estacionamientos
                      _construirGridEstacionamientos(),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
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