import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/gasto_comun_model.dart';
import '../../../models/lista_porcentajes_model.dart';
import '../../../services/gastos_comunes_service.dart';
import 'gasto_detalle_screen.dart';
import 'listas_porcentajes_screen.dart';
import 'gastos_por_vivienda_screen.dart';

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
  int _cantidadListasPorcentajes = 0;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    print('🔄 Iniciando carga de gastos comunes');
    //print('📍 Stack trace: ${StackTrace.current}');
    print('👤 Usuario: ${widget.currentUser.uid}');
    print('👤 Condominio: ${widget.currentUser.condominioId}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Solicitando todos los gastos para condominio ${widget.currentUser.condominioId}');
      final gastos = await _gastosService.obtenerTodosLosGastos(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      print('🔍 Solicitando cantidad de listas de porcentajes');
      final cantidadListas = await _gastosService.contarListasPorcentajes(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      print('✅ Gastos obtenidos por tipo:');
      for (final tipo in TipoGasto.values) {
        final gastosDelTipo = gastos[tipo] ?? [];
        print('   - ${tipo.nombre}: ${gastosDelTipo.length} gastos');
      }
      print('✅ Cantidad de listas de porcentajes: $cantidadListas');

      final Map<TipoGasto, int> totales = {};
      int totalGeneral = 0;

      for (final tipo in TipoGasto.values) {
        final gastosDelTipo = gastos[tipo] ?? [];
        final total = gastosDelTipo.fold<int>(0, (sum, gasto) => sum + gasto.monto);
        totales[tipo] = total;
        totalGeneral += total;
        print('💰 Total ${tipo.nombre}: $total');
      }
      print('💰 Total general: $totalGeneral');

      setState(() {
        _gastos = gastos;
        _totales = totales;
        _totalGeneral = totalGeneral;
        _cantidadListasPorcentajes = cantidadListas;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar gastos: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      
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
                    
                    // Sección de Listas de Porcentajes
                    _buildSeccionListasPorcentajes(),
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
    return InkWell(
      onTap: _mostrarDetalleGastosPorVivienda,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Toca para ver detalle por vivienda',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildSeccionListasPorcentajes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listas de Porcentajes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _navegarAListasPorcentajes,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pie_chart,
                      color: Colors.purple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Porcentajes por Residente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestionar distribución de gastos por vivienda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '$_cantidadListasPorcentajes ${_cantidadListasPorcentajes == 1 ? 'lista' : 'listas'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Configurar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
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
        ),
      ],
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

  void _navegarAListasPorcentajes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListasPorcentajesScreen(
          currentUser: widget.currentUser,
        ),
      ),
    );

    // Recargar datos si hubo cambios
    if (result == true) {
      _cargarGastos();
    }
  }

  void _mostrarDetalleGastosPorVivienda() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastosPorViviendaScreen(
          currentUser: widget.currentUser,
        ),
      ),
    );

    // Recargar datos si hubo cambios
    if (result == true) {
      _cargarGastos();
    }
  }

  }
