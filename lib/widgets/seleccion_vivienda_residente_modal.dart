import 'package:flutter/material.dart';
import '../models/condominio_model.dart';
import '../models/residente_model.dart';
import '../models/lista_porcentajes_model.dart';
import '../services/firestore_service.dart';
import '../services/gastos_comunes_service.dart';

class SeleccionViviendaResidenteModal extends StatefulWidget {
  final String condominioId;
  final Function(String vivienda, String? residenteId, String? residenteNombre) onSeleccion;
  final bool seleccionarResidente;
  final String titulo;

  const SeleccionViviendaResidenteModal({
    super.key,
    required this.condominioId,
    required this.onSeleccion,
    this.seleccionarResidente = true,
    this.titulo = 'Seleccionar Vivienda',
  });

  @override
  State<SeleccionViviendaResidenteModal> createState() =>
      _SeleccionViviendaResidenteModalState();
}

class _SeleccionViviendaResidenteModalState
    extends State<SeleccionViviendaResidenteModal> {
  final FirestoreService _firestoreService = FirestoreService();
  final GastosComunesService _gastosService = GastosComunesService();
  Map<String, ViviendaPorcentajeModel> _viviendas = {};
  bool _isLoading = true;
  String? _viviendaSeleccionada;

  @override
  void initState() {
    super.initState();
    _loadViviendasData();
  }

  Future<void> _loadViviendasData() async {
    try {
      // Usar el mismo método que ListaPorcentajeFormScreen
      final viviendas = await _gastosService.obtenerViviendasConResidentes(
        condominioId: widget.condominioId,
      );

      if (mounted) {
        setState(() {
          _viviendas = viviendas;
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
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }



  void _seleccionarVivienda(String descripcionVivienda) {
    print('📍 _seleccionarVivienda llamado con: $descripcionVivienda');
    print('🔧 widget.seleccionarResidente: ${widget.seleccionarResidente}');
    
    setState(() {
      _viviendaSeleccionada = descripcionVivienda;
    });

    if (widget.seleccionarResidente) {
      print('👥 Mostrando selección de residente para: $descripcionVivienda');
      _mostrarSeleccionResidente(descripcionVivienda);
    } else {
      print('🏠 Selección directa de vivienda: $descripcionVivienda');
      widget.onSeleccion(descripcionVivienda, null, null);
      Navigator.of(context).pop();
    }
  }

  void _mostrarSeleccionResidente(String descripcionVivienda) {
    print('🔍 _mostrarSeleccionResidente llamado con: $descripcionVivienda');
    print('📋 Viviendas disponibles en mapa: ${_viviendas.keys.toList()}');
    
    // Encontrar la vivienda en el mapa
    final vivienda = _viviendas[descripcionVivienda];
    print('🏠 Vivienda encontrada: ${vivienda?.descripcionVivienda}');
    print('👥 Residentes en vivienda: ${vivienda?.listaIdsResidentes.length}');
    
    if (vivienda == null) {
      print('❌ ERROR: No se encontró la vivienda $descripcionVivienda en el mapa');
      return;
    }

    print('✅ Mostrando diálogo de selección de residente');
    showDialog(
      context: context,
      builder: (context) => _ResidenteSelectionDialog(
        condominioId: widget.condominioId,
        vivienda: vivienda,
        onResidenteSeleccionado: (residenteId, residenteNombre) {
          print('👤 Residente seleccionado: $residenteNombre ($residenteId)');
          widget.onSeleccion(descripcionVivienda, residenteId, residenteNombre);
          Navigator.of(context).pop(); // Cerrar diálogo de residentes
          Navigator.of(context).pop(); // Cerrar modal de viviendas
        },
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _viviendas.isEmpty
                      ? const Center(
                          child: Text('No hay viviendas disponibles'),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Viviendas Disponibles',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 3.0, // Aumentado para evitar overflow
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _viviendas.length,
                                  itemBuilder: (context, index) {
                                    final entry = _viviendas.entries.elementAt(index);
                                    final descripcionVivienda = entry.value.descripcionVivienda;
                                    final cantidadResidentes = entry.value.listaIdsResidentes.length;
                                    
                                    print('🏠 Vivienda en grid: $descripcionVivienda con $cantidadResidentes residentes');
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        print('🔍 Seleccionando vivienda: $descripcionVivienda');
                                        _seleccionarVivienda(descripcionVivienda);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          border: Border.all(
                                            color: Colors.blue.shade300,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0), // Reducido padding
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min, // Ajustar al contenido
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  descripcionVivienda,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue.shade700,
                                                    fontSize: 11, // Reducido tamaño de fuente
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2), // Reducido espacio
                                              Flexible(
                                                child: Text(
                                                  '$cantidadResidentes residente${cantidadResidentes != 1 ? 's' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 9, // Reducido tamaño de fuente
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidenteSelectionDialog extends StatefulWidget {
  final String condominioId;
  final ViviendaPorcentajeModel vivienda;
  final Function(String residenteId, String residenteNombre) onResidenteSeleccionado;

  const _ResidenteSelectionDialog({
    required this.condominioId,
    required this.vivienda,
    required this.onResidenteSeleccionado,
  });

  @override
  State<_ResidenteSelectionDialog> createState() =>
      _ResidenteSelectionDialogState();
}

class _ResidenteSelectionDialogState extends State<_ResidenteSelectionDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ResidenteModel> _residentes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarResidentes();
  }

  Future<void> _cargarResidentes() async {
    try {
      print('🔄 Iniciando carga de residentes para vivienda: ${widget.vivienda.descripcionVivienda}');
      
      // Obtener todos los residentes del condominio
      final todosLosResidentes = await _firestoreService.obtenerResidentesCondominio(widget.condominioId);
      print('📊 Total de residentes obtenidos: ${todosLosResidentes.length}');
      
      // Log de todos los residentes para depuración
      for (var residente in todosLosResidentes) {
        print('👤 Residente: ${residente.nombre} - Vivienda: "${residente.descripcionVivienda}" - Seleccionada: ${residente.viviendaSeleccionada}');
      }
      
      // Filtrar residentes que coincidan con la descripción de vivienda
        final residentesFiltrados = todosLosResidentes.where((residente) {
          final coincideVivienda = residente.descripcionVivienda == widget.vivienda.descripcionVivienda;
          // Corregir comparación: el campo puede ser string "seleccionada" o boolean true
          final viviendaSeleccionada = residente.viviendaSeleccionada == true || 
                                     residente.viviendaSeleccionada == "seleccionada";
          
          print('🔍 Evaluando residente ${residente.nombre}:');
          print('   - Vivienda residente: "${residente.descripcionVivienda}"');
          print('   - Vivienda buscada: "${widget.vivienda.descripcionVivienda}"');
          print('   - Coincide vivienda: $coincideVivienda');
          print('   - Valor viviendaSeleccionada: ${residente.viviendaSeleccionada}');
          print('   - Vivienda seleccionada (evaluada): $viviendaSeleccionada');
          print('   - Incluir: ${coincideVivienda && viviendaSeleccionada}');
          
          return coincideVivienda && viviendaSeleccionada;
        }).toList();
      
      print('✅ Residentes filtrados: ${residentesFiltrados.length}');
      for (var residente in residentesFiltrados) {
        print('   - ${residente.nombre} (${residente.email})');
      }
      
      setState(() {
        _residentes = residentesFiltrados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Error al cargar residentes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Residentes de ${widget.vivienda.descripcionVivienda}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _residentes.isEmpty
                ? const Center(
                    child: Text('No hay residentes en esta vivienda'),
                  )
                : ListView.builder(
                    itemCount: _residentes.length,
                    itemBuilder: (context, index) {
                      final residente = _residentes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            residente.nombre.isNotEmpty
                                ? residente.nombre[0].toUpperCase()
                                : 'R',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(residente.nombre),
                        subtitle: Text(residente.email),
                        onTap: () {
                          widget.onResidenteSeleccionado(
                            residente.uid,
                            residente.nombre,
                          );
                        },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}