import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/gasto_comun_model.dart';
import '../../../services/gastos_comunes_service.dart';
import 'gasto_form_screen.dart';

class GastoDetalleScreen extends StatefulWidget {
  final UserModel currentUser;
  final TipoGasto tipoGasto;

  const GastoDetalleScreen({
    Key? key,
    required this.currentUser,
    required this.tipoGasto,
  }) : super(key: key);

  @override
  _GastoDetalleScreenState createState() => _GastoDetalleScreenState();
}

class _GastoDetalleScreenState extends State<GastoDetalleScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  List<GastoComunModel> _gastos = [];
  bool _isLoading = true;
  int _totalGastos = 0;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gastos = await _gastosService.obtenerGastosPorTipo(
        condominioId: widget.currentUser.condominioId.toString(),
        tipo: widget.tipoGasto,
      );

      final total = gastos.fold<int>(0, (sum, gasto) => sum + gasto.monto);

      setState(() {
        _gastos = gastos;
        _totalGastos = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar gastos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarGasto(GastoComunModel gasto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el gasto "${gasto.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _gastosService.eliminarGasto(
          condominioId: widget.currentUser.condominioId.toString(),
          gastoId: gasto.id,
          tipo: widget.tipoGasto,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        _cargarGastos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getColorForTipo() {
    switch (widget.tipoGasto) {
      case TipoGasto.fijo:
        return Colors.blue;
      case TipoGasto.variable:
        return Colors.orange;
      case TipoGasto.adicional:
        return Colors.green;
    }
  }

  IconData _getIconForTipo() {
    switch (widget.tipoGasto) {
      case TipoGasto.fijo:
        return Icons.home;
      case TipoGasto.variable:
        return Icons.trending_up;
      case TipoGasto.adicional:
        return Icons.add_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForTipo();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos ${widget.tipoGasto.nombre}s'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navegarAFormulario,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarGastos,
              child: Column(
                children: [
                  // Header con total
                  _buildHeader(color),
                  
                  // Lista de gastos
                  Expanded(
                    child: _gastos.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _gastos.length,
                            itemBuilder: (context, index) {
                              final gasto = _gastos[index];
                              return _buildGastoCard(gasto, color);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAFormulario,
        backgroundColor: color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getIconForTipo(),
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '${_gastos.length} ${_gastos.length == 1 ? 'gasto' : 'gastos'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \$${_totalGastos.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            )}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForTipo(),
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay gastos ${widget.tipoGasto.nombre}s',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar el primer gasto',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGastoCard(GastoComunModel gasto, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gasto.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') {
                      _navegarAFormulario(gasto: gasto);
                    } else if (value == 'eliminar') {
                      _eliminarGasto(gasto);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Monto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '\$${gasto.monto.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]}.',
                )}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Tipo de cobro
            Row(
              children: [
                Icon(
                  gasto.tipoCobro == 'igual para todos' 
                      ? Icons.people 
                      : Icons.percent,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  gasto.tipoCobro,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            // Período (solo para gastos adicionales)
            if (widget.tipoGasto == TipoGasto.adicional && gasto.periodo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Período: ${gasto.periodo}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navegarAFormulario({GastoComunModel? gasto}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastoFormScreen(
          currentUser: widget.currentUser,
          tipoGasto: widget.tipoGasto,
          gasto: gasto,
        ),
      ),
    );

    // Recargar datos si hubo cambios
    if (result == true) {
      _cargarGastos();
    }
  }
}