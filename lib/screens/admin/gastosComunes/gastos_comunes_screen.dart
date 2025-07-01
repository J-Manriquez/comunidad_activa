import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/gasto_comun_model.dart';
import '../../../services/gastos_comunes_service.dart';
import 'gasto_detalle_screen.dart';

class GastosComunesScreen extends StatefulWidget {
  final UserModel currentUser;

  const GastosComunesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  _GastosComunesScreenState createState() => _GastosComunesScreenState();
}

class _GastosComunesScreenState extends State<GastosComunesScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  Map<TipoGasto, List<GastoComunModel>> _gastos = {};
  Map<TipoGasto, int> _totales = {};
  bool _isLoading = true;
  int _totalGeneral = 0;

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
      final gastos = await _gastosService.obtenerTodosLosGastos(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      final Map<TipoGasto, int> totales = {};
      int totalGeneral = 0;

      for (final tipo in TipoGasto.values) {
        final gastosDelTipo = gastos[tipo] ?? [];
        final total = gastosDelTipo.fold<int>(0, (sum, gasto) => sum + gasto.monto);
        totales[tipo] = total;
        totalGeneral += total;
      }

      setState(() {
        _gastos = gastos;
        _totales = totales;
        _totalGeneral = totalGeneral;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Comunes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarGastos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen total
                    _buildResumenTotal(),
                    const SizedBox(height: 24),
                    
                    // Título
                    const Text(
                      'Categorías de Gastos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cards de categorías
                    _buildCategoriaCard(
                      tipo: TipoGasto.fijo,
                      icon: Icons.home,
                      color: Colors.blue,
                      descripcion: 'Gastos recurrentes mensuales',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildCategoriaCard(
                      tipo: TipoGasto.variable,
                      icon: Icons.trending_up,
                      color: Colors.orange,
                      descripcion: 'Gastos que varían mes a mes',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildCategoriaCard(
                      tipo: TipoGasto.adicional,
                      icon: Icons.add_circle,
                      color: Colors.green,
                      descripcion: 'Gastos extraordinarios o por período',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumenTotal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Gastos Comunes del Mes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalGeneral.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            )}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard({
    required TipoGasto tipo,
    required IconData icon,
    required Color color,
    required String descripcion,
  }) {
    final gastos = _gastos[tipo] ?? [];
    final total = _totales[tipo] ?? 0;
    final cantidad = gastos.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navegarADetalle(tipo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos ${tipo.nombre}s',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$cantidad ${cantidad == 1 ? 'gasto' : 'gastos'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${total.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          )}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Flecha
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarADetalle(TipoGasto tipo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastoDetalleScreen(
          currentUser: widget.currentUser,
          tipoGasto: tipo,
        ),
      ),
    );

    // Recargar datos si hubo cambios
    if (result == true) {
      _cargarGastos();
    }
  }
}