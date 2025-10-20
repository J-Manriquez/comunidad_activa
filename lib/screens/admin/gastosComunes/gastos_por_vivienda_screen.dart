import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/gastos_comunes_service.dart';

class GastosPorViviendaScreen extends StatefulWidget {
  final UserModel currentUser;

  const GastosPorViviendaScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  _GastosPorViviendaScreenState createState() => _GastosPorViviendaScreenState();
}

class _GastosPorViviendaScreenState extends State<GastosPorViviendaScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  Map<String, Map<String, dynamic>> _gastosCalculados = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarGastosPorVivienda();
  }

  Future<void> _cargarGastosPorVivienda() async {
    print('🔄 Iniciando cálculo de gastos por vivienda');
    print('👤 Usuario: ${widget.currentUser.uid}');
    print('👤 Condominio: ${widget.currentUser.condominioId}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Solicitando cálculo de gastos por residente para condominio ${widget.currentUser.condominioId}');
      final gastosCalculados = await _gastosService.calcularGastosPorResidente(
        condominioId: widget.currentUser.condominioId.toString(),
      );

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

      setState(() {
        _gastosCalculados = gastosCalculados;
        _isLoading = false;
      });

      if (gastosCalculados.isEmpty) {
        print('⚠️ No hay viviendas activas para mostrar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay viviendas activas para mostrar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error al calcular gastos: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular gastos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos por Vivienda'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarGastosPorVivienda,
              child: _gastosCalculados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay viviendas activas para mostrar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _gastosCalculados.length,
                      itemBuilder: (context, index) {
                        final viviendaKey = _gastosCalculados.keys.elementAt(index);
                        final datos = _gastosCalculados[viviendaKey]!;
                        
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
    );
  }
}