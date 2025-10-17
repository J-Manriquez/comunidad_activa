import 'package:flutter/material.dart';
import '../../../../models/estacionamiento_model.dart';
import '../../../../services/estacionamiento_service.dart';
import '../../../../services/control_acceso_service.dart';

class SeleccionEstacionamientoModal extends StatefulWidget {
  final String condominioId;
  final Function(String estacionamiento) onSeleccion;
  final String titulo;
  final String? viviendaSeleccionada; // Nueva propiedad para la vivienda seleccionada
  final bool esResidente; // Nueva propiedad para identificar si es un residente

  const SeleccionEstacionamientoModal({
    super.key,
    required this.condominioId,
    required this.onSeleccion,
    this.titulo = 'Seleccionar Estacionamiento',
    this.viviendaSeleccionada, // Parámetro opcional
    this.esResidente = false, // Por defecto es administrador
  });

  @override
  State<SeleccionEstacionamientoModal> createState() =>
      _SeleccionEstacionamientoModalState();
}

class _SeleccionEstacionamientoModalState
    extends State<SeleccionEstacionamientoModal> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  List<EstacionamientoModel> _estacionamientos = [];
  List<EstacionamientoModel> _estacionamientosFiltrados = [];
  bool _isLoading = true;
  String _filtroSeleccionado = 'todos';
  final TextEditingController _searchController = TextEditingController();
  bool _usaEstacionamientoVisitas = false;
  bool _estVisitasConfig = false;

  @override
  void initState() {
    super.initState();
    // Establecer filtro inicial basado en si hay vivienda seleccionada
    if (widget.viviendaSeleccionada != null) {
      _filtroSeleccionado = 'vivienda';
    }
    _loadEstacionamientosData();
    _loadControlAccesoConfig();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEstacionamientosData() async {
    try {
      // Obtener todos los estacionamientos
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(
        widget.condominioId,
      );

      if (mounted) {
        setState(() {
          _estacionamientos = estacionamientos;
          _isLoading = false;
        });
        // Filtrar después de cargar los datos
        _filtrarEstacionamientos();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estacionamientos: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadControlAccesoConfig() async {
    try {
      // Cargar configuración de control de acceso
      final config = await _controlAccesoService.getControlAcceso(widget.condominioId);
      if (mounted && config != null) {
        setState(() {
          _usaEstacionamientoVisitas = config.usaEstacionamientoVisitas;
        });
      }
      
      // Cargar configuración de estacionamientos para obtener estVisitas
      final estacionamientoConfig = await _estacionamientoService.obtenerConfiguracion(widget.condominioId);
      if (mounted) {
        setState(() {
          _estVisitasConfig = estacionamientoConfig['estVisitas'] ?? false;
        });
      }
    } catch (e) {
      // Si hay error, mantener los valores por defecto (false)
      print('Error al cargar configuración: $e');
    }
  }

  void _filtrarEstacionamientos() {
    setState(() {
      List<EstacionamientoModel> filtrados = _estacionamientos;

      // Filtrar por tipo
      if (_filtroSeleccionado == 'residentes') {
        filtrados = filtrados.where((e) => !e.estVisita).toList();
      } else if (_filtroSeleccionado == 'visitas') {
        filtrados = filtrados.where((e) => e.estVisita).toList();
      } else if (_filtroSeleccionado == 'vivienda' && widget.viviendaSeleccionada != null) {
        // Filtrar estacionamientos de la vivienda seleccionada
        filtrados = filtrados.where((e) {
          // Estacionamientos asignados directamente a la vivienda
          bool esDeVivienda = e.viviendaAsignada == widget.viviendaSeleccionada;
          
          // Estacionamientos prestados a la vivienda (campo viviendaPrestamo)
          bool esPrestadoAVivienda = e.viviendaPrestamo == widget.viviendaSeleccionada;
          
          // Excluir estacionamientos que la vivienda ha prestado a otros
          // (es decir, estacionamientos donde viviendaAsignada es la vivienda seleccionada
          // pero viviendaPrestamo es diferente y prestado es true)
          bool haPrestadoAOtros = e.viviendaAsignada == widget.viviendaSeleccionada && 
                                  e.prestado == true && 
                                  e.viviendaPrestamo != null && 
                                  e.viviendaPrestamo != widget.viviendaSeleccionada;
          
          return (esDeVivienda || esPrestadoAVivienda) && !haPrestadoAOtros;
        }).toList();
      }

      // Filtrar por búsqueda
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        filtrados = filtrados.where((e) =>
          e.nroEstacionamiento.toLowerCase().contains(searchTerm) ||
          (e.viviendaAsignada?.toLowerCase().contains(searchTerm) ?? false)
        ).toList();
      }

      _estacionamientosFiltrados = filtrados;
    });
  }

  void _seleccionarEstacionamiento(EstacionamientoModel estacionamiento) {
    final String nombreEstacionamiento = estacionamiento.estVisita 
        ? 'de visitas ${estacionamiento.nroEstacionamiento}'
        : estacionamiento.nroEstacionamiento;
    widget.onSeleccion(nombreEstacionamiento);
  }

  List<ButtonSegment<String>> _buildSegments() {
    List<ButtonSegment<String>> segments = [];

    if (widget.esResidente) {
      // Lógica para residentes
      // Siempre mostrar opción "Vivienda" si hay vivienda seleccionada
      if (widget.viviendaSeleccionada != null) {
        segments.add(
          const ButtonSegment(
            value: 'vivienda',
            label: Text('Vivienda'),
            icon: Icon(Icons.home_outlined, size: 16),
          ),
        );
      }
      
      // Mostrar opción "Visitas" solo si estVisitas es true, usaEstacionamientoVisitas es true y hay estacionamientos de visitas
      if (_estVisitasConfig && _usaEstacionamientoVisitas && _estacionamientos.any((e) => e.estVisita)) {
        segments.add(
          const ButtonSegment(
            value: 'visitas',
            label: Text('Visitas'),
            icon: Icon(Icons.people, size: 16),
          ),
        );
      }
    } else {
      // Lógica para administradores (comportamiento original)
      // Mostrar opción "Vivienda" solo si hay vivienda seleccionada
      if (widget.viviendaSeleccionada != null) {
        segments.add(
          const ButtonSegment(
            value: 'vivienda',
            label: Text('Vivienda'),
            icon: Icon(Icons.home_outlined, size: 16),
          ),
        );
      } else {
        segments.add(
          const ButtonSegment(
            value: 'todos',
            label: Text('Todos'),
            icon: Icon(Icons.all_inclusive, size: 16),
          ),
        );
      }
      
      segments.add(
        const ButtonSegment(
          value: 'residentes',
          label: Text('Residentes'),
          icon: Icon(Icons.home, size: 16),
        ),
      );
      
      // Mostrar opción "Visitas" solo si estVisitas es true y hay estacionamientos de visitas
      if (_estVisitasConfig && _estacionamientos.any((e) => e.estVisita)) {
        segments.add(
          const ButtonSegment(
            value: 'visitas',
            label: Text('Visitas'),
            icon: Icon(Icons.people, size: 16),
          ),
        );
      }
    }

    return segments;
  }

  Widget _buildEstacionamientoCard(EstacionamientoModel estacionamiento) {
    final bool esVisita = estacionamiento.estVisita;
    final bool tieneVivienda = estacionamiento.viviendaAsignada != null && 
                               estacionamiento.viviendaAsignada!.isNotEmpty;
    
    // Verificar si es un estacionamiento prestado a la vivienda seleccionada
    final bool esPrestado = widget.viviendaSeleccionada != null && 
                           estacionamiento.viviendaPrestamo == widget.viviendaSeleccionada;
    
    // Determinar colores según el tipo y si está prestado
    Color backgroundColor;
    Color iconColor;
    
    if (esPrestado) {
      backgroundColor = Colors.green.shade100;
      iconColor = Colors.green.shade700;
    } else if (esVisita) {
      backgroundColor = Colors.orange.shade100;
      iconColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.blue.shade100;
      iconColor = Colors.blue.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(
            Icons.local_parking,
            color: iconColor,
          ),
        ),
        title: Text(
          esVisita ? 'Estacionamiento de visitas ${estacionamiento.nroEstacionamiento}' : 'Estacionamiento ${estacionamiento.nroEstacionamiento}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esPrestado) ...[
              Text(
                'Prestado por: ${estacionamiento.viviendaAsignada}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Estacionamiento Prestado',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Text(
                esVisita ? 'Estacionamiento de Visitas' : 'Estacionamiento de Residentes',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (tieneVivienda) ...[
                const SizedBox(height: 4),
                Text(
                  'Asignado a: ${estacionamiento.viviendaAsignada}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _seleccionarEstacionamiento(estacionamiento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_parking,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Filtros y búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Barra de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar estacionamiento...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => _filtrarEstacionamientos(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filtros por tipo
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: _buildSegments(),
                          selected: {_filtroSeleccionado},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _filtroSeleccionado = selection.first;
                            });
                            _filtrarEstacionamientos();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de estacionamientos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _estacionamientosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_parking_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron estacionamientos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Intenta cambiar los filtros de búsqueda',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _estacionamientosFiltrados.length,
                          itemBuilder: (context, index) {
                            return _buildEstacionamientoCard(_estacionamientosFiltrados[index]);
                          },
                        ),
            ),

            // Footer con información
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total: ${_estacionamientosFiltrados.length} estacionamientos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}