import 'package:flutter/material.dart';
import '../models/lista_porcentajes_model.dart';
import '../services/gastos_comunes_service.dart';

class SeleccionViviendaBloqueoModal extends StatefulWidget {
  final String condominioId;
  final Function(String vivienda) onSeleccion;
  final String titulo;

  const SeleccionViviendaBloqueoModal({
    super.key,
    required this.condominioId,
    required this.onSeleccion,
    this.titulo = 'Seleccionar Vivienda de Bloqueo',
  });

  @override
  State<SeleccionViviendaBloqueoModal> createState() =>
      _SeleccionViviendaBloqueoModalState();
}

class _SeleccionViviendaBloqueoModalState
    extends State<SeleccionViviendaBloqueoModal> {
  final GastosComunesService _gastosService = GastosComunesService();
  Map<String, ViviendaPorcentajeModel> _viviendas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViviendasData();
  }

  Future<void> _loadViviendasData() async {
    try {
      // Obtener viviendas con residentes activos
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
            content: Text('Error al cargar viviendas: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _seleccionarVivienda(String descripcionVivienda) {
    // Directamente seleccionar la vivienda sin mostrar residentes
    widget.onSeleccion(descripcionVivienda);
    // No llamar Navigator.pop() aquí, se maneja en el callback
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
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 5),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay viviendas disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Viviendas Activas',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Seleccione la vivienda donde se aplicará el bloqueo de visita',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 2.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _viviendas.length,
                                  itemBuilder: (context, index) {
                                    final entry = _viviendas.entries.elementAt(index);
                                    final descripcionVivienda = entry.value.descripcionVivienda;
                                    
                                    return GestureDetector(
                                      onTap: () => _seleccionarVivienda(descripcionVivienda),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          border: Border.all(
                                            color: Colors.red.shade300,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.shade100,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Center(
                                            child: Text(
                                              descripcionVivienda,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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