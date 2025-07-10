import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/gasto_comun_model.dart';
import '../../../models/lista_porcentajes_model.dart';
import '../../../services/gastos_comunes_service.dart';
import 'gasto_detalle_screen.dart';
import 'listas_porcentajes_screen.dart';

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
    print('🔄 Iniciando cálculo de gastos por vivienda');
    //print('📍 Stack trace: ${StackTrace.current}');
    print('👤 Usuario: ${widget.currentUser.uid}');
    print('👤 Condominio: ${widget.currentUser.condominioId}');
    
    // Mostrar loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('🔍 Solicitando cálculo de gastos por residente para condominio ${widget.currentUser.condominioId}');
      final gastosCalculados = await _gastosService.calcularGastosPorResidente(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Cerrar loading dialog
      Navigator.of(context).pop();

      print('✅ Gastos calculados: ${gastosCalculados.length} viviendas');
      
      // Verificar datos recibidos
      gastosCalculados.forEach((viviendaKey, datos) {
        print('📊 Vivienda: ${datos['descripcion'] ?? viviendaKey}');
        print('   - Monto total: ${datos['montoTotal']}');
        print('   - Monto gastos: ${datos['montoGastos']}');
        print('   - Monto multas: ${datos['montoMultas']}');
        print('   - Residentes: ${(datos['residentes'] as List).length}');
        print('   - Detalle gastos: ${(datos['detalleGastos'] as List).length} items');
        print('   - Detalle multas: ${(datos['detalleMultas'] as List).length} items');
        
        // Verificar si la suma de gastos y multas coincide con el total
        int montoGastos = datos['montoGastos'] as int? ?? 0;
        int montoMultas = datos['montoMultas'] as int? ?? 0;
        int montoTotal = datos['montoTotal'] as int? ?? 0;
        int sumaCalculada = montoGastos + montoMultas;
        
        if (sumaCalculada != montoTotal) {
          print('⚠️ ADVERTENCIA: La suma de gastos ($montoGastos) y multas ($montoMultas) = $sumaCalculada no coincide con el total ($montoTotal) para vivienda ${datos['descripcion']}');
        }
      });

      if (gastosCalculados.isEmpty) {
        print('⚠️ No hay viviendas activas para mostrar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay viviendas activas para mostrar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar bottom sheet con el detalle
      print('🔄 Mostrando bottom sheet con detalle de gastos por vivienda');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDetalleGastosBottomSheet(gastosCalculados),
      );
    } catch (e) {
      // Cerrar loading dialog
      Navigator.of(context).pop();
      
      print('❌ Error al calcular gastos: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular gastos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetalleGastosBottomSheet(Map<String, Map<String, dynamic>> gastosCalculados) {
    print('🔄 Construyendo bottom sheet de detalle de gastos por vivienda');
    print('📊 Número de viviendas a mostrar: ${gastosCalculados.length}');
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Gastos por Vivienda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Lista de viviendas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gastosCalculados.length,
              itemBuilder: (context, index) {
                final viviendaKey = gastosCalculados.keys.elementAt(index);
                final datos = gastosCalculados[viviendaKey]!;
                
                print('🏠 Construyendo item $index: ${datos['descripcion'] ?? viviendaKey}');
                print('   - Monto gastos: ${datos['montoGastos']}');
                print('   - Monto multas: ${datos['montoMultas']}');
                print('   - Monto total: ${datos['montoTotal']}');
                
                // Verificar si hay multas pero no se muestran
                final montoMultas = datos['montoMultas'] as int? ?? 0;
                if (montoMultas > 0) {
                  print('   ✅ Vivienda tiene multas: $montoMultas');
                } else {
                  print('   ℹ️ Vivienda no tiene multas');
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      datos['descripcion'] ?? viviendaKey,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${(datos['residentes'] as List).length} residente(s)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtotal Gastos
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${datos['montoGastos'].toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Gastos',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Subtotal Multas
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${datos['montoMultas'].toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'Multas',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Subtotal Espacios Comunes
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(datos['montoEspaciosComunes'] ?? 0).toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.purple,
                              ),
                            ),
                            const Text(
                              'Espacios',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Log para verificar multas
                        Builder(builder: (context) {
                          final montoMultas = datos['montoMultas'] as int? ?? 0;
                          final detalleMultas = datos['detalleMultas'] as List? ?? [];
                          print('   📊 Multas en UI: $montoMultas (${detalleMultas.length} items)');
                          return const SizedBox.shrink();
                        }),
                        // Total
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${datos['montoTotal'].toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalle de gastos:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...((datos['detalleGastos'] as List<Map<String, dynamic>>)
                                .map((gasto) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              gasto['descripcion'] ?? 'Sin descripción',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Text(
                                            '\$${gasto['monto'].toString().replaceAllMapped(
                                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                              (Match m) => '${m[1]}.',
                                            )}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList()),
                            
                            // Mostrar detalle de multas si existen y agregar logging
                            // print('   🔄 Verificando multas para mostrar: ${(datos['detalleMultas'] as List<dynamic>).length} items');
                            if ((datos['detalleMultas'] as List<dynamic>).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Detalle de multas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...((datos['detalleMultas'] as List<Map<String, dynamic>>)
                                  .map((multa) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    multa['tipoMulta'] ?? 'Multa',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '\$${multa['valor'].toString().replaceAllMapped(
                                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                    (Match m) => '${m[1]}.',
                                                  )}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (multa['contenido'] != null && multa['contenido'].toString().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  multa['contenido'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ))
                                  .toList()),
                            ],
                            
                            // Mostrar detalle de espacios comunes si existen
                            if ((datos['detalleEspaciosComunes'] as List<dynamic>).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Detalle de espacios comunes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...((datos['detalleEspaciosComunes'] as List<Map<String, dynamic>>)
                                  .map((espacio) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    espacio['nombreEspacio'] ?? 'Espacio',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.purple,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '\$${espacio['total'].toString().replaceAllMapped(
                                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                                    (Match m) => '${m[1]}.',
                                                  )}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (espacio['fecha'] != null && espacio['fecha'].toString().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  'Fecha: ${espacio['fecha']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            if ((espacio['costoEspacio'] ?? 0) > 0 || (espacio['costoRevisiones'] ?? 0) > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  'Espacio: \$${(espacio['costoEspacio'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} | Revisiones: \$${(espacio['costoRevisiones'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ))
                                  .toList()),
                            ],
                            
                            const SizedBox(height: 16),
                            const Divider(),
                            
                            // Resumen de totales
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal Gastos:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${datos['montoGastos'].toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                                  )}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal Multas:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${datos['montoMultas'].toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                                  )}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal Espacios:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${datos['montoEspaciosComunes'].toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                                  )}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Text(
                                      'TOTAL A PAGAR:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Text(
                                      '\$${datos['montoTotal'].toString().replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]}.',
                                      )}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                               'Detalle anterior (solo gastos):',
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                               ),
                            ),
                            const SizedBox(height: 8),
                            ...(datos['detalleGastos'] as List<Map<String, dynamic>>)
                                .map((gasto) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          gasto['descripcion'],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      if (gasto['porcentaje'] != null)
                                        Text(
                                          '${gasto['porcentaje']}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '\$${gasto['monto'].toString().replaceAllMapped(
                                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                          (Match m) => '${m[1]}.',
                                        )}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}