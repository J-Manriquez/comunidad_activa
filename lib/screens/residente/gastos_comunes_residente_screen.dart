import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/gastos_comunes_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/condominio_model.dart';

class GastosComunesResidenteScreen extends StatefulWidget {
  const GastosComunesResidenteScreen({super.key});

  @override
  State<GastosComunesResidenteScreen> createState() => _GastosComunesResidenteScreenState();
}

class _GastosComunesResidenteScreenState extends State<GastosComunesResidenteScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _gastosResidente;
  bool _isLoading = true;
  String? _error;
  UserModel? _currentUser;
  bool _cobrarMultasConGastos = false;

  @override
  void initState() {
    super.initState();
    _cargarGastosResidente();
  }

  Future<void> _cargarGastosResidente() async {
    try {
      print('🔄 Iniciando carga de gastos para residente');
      //print('📍 Stack trace: ${StackTrace.current}');
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener usuario actual
      _currentUser = await _authService.getCurrentUserData();
      if (_currentUser == null) {
        print('❌ Usuario actual no encontrado');
        throw Exception('Usuario no encontrado');
      }
      
      print('👤 Usuario: ${_currentUser!.uid}');
      print('👤 Condominio: ${_currentUser!.condominioId}');

      // Verificar configuración del condominio
      final condominioDoc = await _firestore
          .collection('condominios')
          .doc(_currentUser!.condominioId.toString())
          .get();
      
      if (condominioDoc.exists) {
        print('📄 Documento del condominio encontrado');
        final condominioData = CondominioModel.fromMap(condominioDoc.data()!);
        _cobrarMultasConGastos = condominioData.cobrarMultasConGastos!;
        print('💰 Configuración cobrarMultasConGastos: $_cobrarMultasConGastos');
        print('📄 Datos del condominio: ${condominioDoc.data()}');
      } else {
        print('⚠️ Documento del condominio no existe');
      }

      // Obtener gastos del residente
      print('🔍 Solicitando gastos del residente ${_currentUser!.uid} en condominio ${_currentUser!.condominioId}');
      final gastos = await _gastosService.obtenerGastosResidente(
        condominioId: _currentUser!.condominioId.toString(),
        residenteId: _currentUser!.uid,
      );

      if (gastos != null) {
        print('✅ Gastos obtenidos correctamente');
        print('📊 Resumen de gastos:');
        print('   - Monto total: ${gastos['montoTotal']}');
        print('   - Monto gastos: ${gastos['montoGastos']}');
        print('   - Monto multas: ${gastos['montoMultas']}');
        print('   - Detalle gastos: ${(gastos['detalleGastos'] as List).length} items');
        print('   - Detalle multas: ${(gastos['detalleMultas'] as List).length} items');
        
        // Verificar si la suma de gastos y multas coincide con el total
        int montoGastos = gastos['montoGastos'] as int? ?? 0;
        int montoMultas = gastos['montoMultas'] as int? ?? 0;
        int montoTotal = gastos['montoTotal'] as int? ?? 0;
        int sumaCalculada = montoGastos + montoMultas;
        
        if (sumaCalculada != montoTotal) {
          print('⚠️ ADVERTENCIA: La suma de gastos ($montoGastos) y multas ($montoMultas) = $sumaCalculada no coincide con el total ($montoTotal)');
        }
        
        // Verificar si hay multas pero no están incluidas en el total
        if (!_cobrarMultasConGastos && montoMultas > 0) {
          print('⚠️ ADVERTENCIA: Hay multas ($montoMultas) pero cobrarMultasConGastos=$_cobrarMultasConGastos');
        }
      } else {
        print('⚠️ No se encontraron gastos para el residente');
      }

      setState(() {
        _gastosResidente = gastos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar gastos: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      setState(() {
        _error = 'Error al cargar gastos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Gastos Comunes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarGastosResidente,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cargando gastos comunes...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarGastosResidente,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_gastosResidente == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron gastos para tu vivienda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumenCard(),
          const SizedBox(height: 20),
          _buildDetalleGastos(),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    print('🔄 Construyendo tarjeta de resumen de gastos');
    // Manejo seguro de datos con valores por defecto
    final montoTotal = (_gastosResidente!['montoTotal'] as int?) ?? 0;
    final montoGastos = (_gastosResidente!['montoGastos'] as int?) ?? montoTotal;
    final montoMultas = (_gastosResidente!['montoMultas'] as int?) ?? 0;
    final vivienda = (_gastosResidente!['descripcion'] as String?) ?? 'Vivienda no especificada';
    
    print('📊 Datos para tarjeta de resumen:');
    print('   - Monto gastos: $montoGastos');
    print('   - Monto multas: $montoMultas');
    print('   - Monto total: $montoTotal');
    print('   - cobrarMultasConGastos: $_cobrarMultasConGastos');
    
    // Verificar si la suma coincide con el total
    final sumaCalculada = montoGastos + (_cobrarMultasConGastos ? montoMultas : 0);
    if (sumaCalculada != montoTotal) {
      print('⚠️ ADVERTENCIA en UI: La suma calculada ($sumaCalculada) no coincide con el total mostrado ($montoTotal)');
    }
    
    // Verificar si hay multas pero no se muestran
    if (!_cobrarMultasConGastos && montoMultas > 0) {
      print('⚠️ ADVERTENCIA en UI: Hay multas ($montoMultas) pero no se mostrarán porque cobrarMultasConGastos=$_cobrarMultasConGastos');
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[400]!,
              Colors.green[600]!,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vivienda,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mostrar subtotales si las multas están incluidas
            if (_cobrarMultasConGastos && montoMultas > 0) ...[              
              // print('✅ Mostrando sección de multas en el resumen'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gastos Comunes:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${_formatearMonto(montoGastos)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Multas:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${_formatearMonto(montoMultas)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.white30,
              ),
              const SizedBox(height: 12),
            ],
            
            const Text(
              'Total a Pagar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_formatearMonto(montoTotal)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleGastos() {
    print('🔄 Construyendo detalle de gastos');
    // Manejo seguro de listas con valores por defecto
    final detalleGastos = (_gastosResidente!['detalleGastos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final detalleMultas = (_gastosResidente!['detalleMultas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    
    print('📊 Detalle de gastos disponibles: ${detalleGastos.length} items');
    print('📊 Detalle de multas disponibles: ${detalleMultas.length} items');

    if (detalleGastos.isEmpty && detalleMultas.isEmpty) {
      print('⚠️ No hay gastos ni multas para mostrar');
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay gastos registrados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    // Agrupar gastos por tipo con manejo seguro
    final Map<String, List<Map<String, dynamic>>> gastosPorTipo = {};
    for (final gasto in detalleGastos) {
      final tipo = (gasto['tipo'] as String?) ?? 'Sin categoría';
      if (!gastosPorTipo.containsKey(tipo)) {
        gastosPorTipo[tipo] = [];
      }
      gastosPorTipo[tipo]!.add(gasto);
    }
    
    print('📊 Gastos agrupados por tipo:');
    gastosPorTipo.forEach((tipo, gastos) {
      print('   - $tipo: ${gastos.length} items');
    });
    
    // Verificar si hay multas pero no se mostrarán
    if (!_cobrarMultasConGastos && detalleMultas.isNotEmpty) {
      print('⚠️ ADVERTENCIA: Hay ${detalleMultas.length} multas en el detalle pero no se mostrarán porque cobrarMultasConGastos=$_cobrarMultasConGastos');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose de Gastos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...gastosPorTipo.entries.map((entry) => _buildTipoGastoCard(entry.key, entry.value)),
        
        // Mostrar desglose de multas si están incluidas y existen
        if (_cobrarMultasConGastos && detalleMultas.isNotEmpty) ...[          
          // print('✅ Mostrando sección de multas (${detalleMultas.length} items)');
          const SizedBox(height: 16),
          _buildMultasCard(detalleMultas),
        ] 
      ],
    );
  }

  Widget _buildTipoGastoCard(String tipo, List<Map<String, dynamic>> gastos) {
    final totalTipo = gastos.fold<int>(0, (sum, gasto) => sum + ((gasto['monto'] as int?) ?? 0));
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: _getIconoTipo(tipo),
        title: Text(
          'Gastos $tipo',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '\$${_formatearMonto(totalTipo)}',
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: gastos.map((gasto) => _buildGastoItem(gasto)).toList(),
      ),
    );
  }

  Widget _buildGastoItem(Map<String, dynamic> gasto) {
    // Manejo seguro de datos del gasto
    final descripcion = (gasto['descripcion'] as String?) ?? 'Sin descripción';
    final monto = (gasto['monto'] as int?) ?? 0;
    final tipoCobro = (gasto['tipoCobro'] as String?) ?? 'No especificado';
    final porcentaje = gasto['porcentaje'] as double?;
    final nombreLista = gasto['nombreLista'] as String?;
    
    print('🔄 Procesando gasto: $descripcion');
    print('📊 Datos del gasto:');
    print('   - Monto: $monto');
    print('   - Tipo Cobro: $tipoCobro');
    print('   - Porcentaje: $porcentaje');
    print('   - Lista: $nombreLista');
    
    // Verificar datos inválidos
    if (monto < 0) {
      print('⚠️ Monto negativo en gasto: $descripcion');
    }
    if (porcentaje != null && (porcentaje < 0 || porcentaje > 100)) {
      print('⚠️ Porcentaje fuera de rango en gasto: $descripcion - Valor: $porcentaje');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '\$${_formatearMonto(monto)}',
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getIconoTipoCobro(tipoCobro),
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _getDescripcionTipoCobro(tipoCobro),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (porcentaje != null && nombreLista != null) ...[            const SizedBox(height: 4),
            Text(
              'Porcentaje: ${porcentaje.toStringAsFixed(1)}% (Lista: $nombreLista)',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Icon _getIconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'fijo':
        return Icon(Icons.attach_money, color: Colors.blue[600]);
      case 'variable':
        return Icon(Icons.trending_up, color: Colors.orange[600]);
      case 'adicional':
        return Icon(Icons.add_circle, color: Colors.purple[600]);
      default:
        return Icon(Icons.receipt, color: Colors.grey[600]);
    }
  }

  IconData _getIconoTipoCobro(String tipoCobro) {
    switch (tipoCobro.toLowerCase()) {
      case 'igual para todos':
        return Icons.balance;
      case 'porcentaje por residente':
        return Icons.percent;
      default:
        return Icons.help_outline;
    }
  }

  String _getDescripcionTipoCobro(String tipoCobro) {
    switch (tipoCobro.toLowerCase()) {
      case 'igual para todos':
        return 'Dividido igualmente';
      case 'porcentaje por residente':
        return 'Por porcentaje asignado';
      default:
        return tipoCobro;
    }
  }

  Widget _buildMultasCard(List<Map<String, dynamic>> multas) {
    print('🔄 Construyendo tarjeta de multas con ${multas.length} multas');
    
    // Calcular el total y verificar los datos
    int totalMultas = 0;
    try {
      totalMultas = multas.fold<int>(
        0,
        (sum, multa) {
          final valor = multa['valor'];
          if (valor == null) {
            print('⚠️ Multa sin valor: $multa');
            return sum;
          }
          
          int valorInt = 0;
          if (valor is int) {
            valorInt = valor;
          } else if (valor is String) {
            try {
              valorInt = int.parse(valor);
            } catch (e) {
              print('⚠️ Error al convertir valor de multa "$valor" a entero: $e');
            }
          } else {
            print('⚠️ Tipo de valor de multa no reconocido: ${valor.runtimeType}');
          }
          
          print('💰 Multa: ${multa['tipoMulta'] ?? 'Sin tipo'} - Valor: $valorInt');
          return sum + valorInt;
        },
      );
    } catch (e) {
      print('❌ Error al calcular total de multas: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
    }
    
    print('💰 Total de multas: $totalMultas');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.gavel, color: Colors.red[600]),
        title: const Text(
          'Multas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '\$${_formatearMonto(totalMultas)}',
          style: TextStyle(
            color: Colors.red[600],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: multas.map((multa) => _buildMultaItem(multa)).toList(),
      ),
    );
  }

  Widget _buildMultaItem(Map<String, dynamic> multa) {
    // Manejo seguro de datos de la multa
    final tipoMulta = (multa['tipoMulta'] as String?) ?? 'Multa sin tipo';
    var valor = 0;
    
    // Manejar diferentes tipos de datos para el valor
    final valorOriginal = multa['valor'];
    if (valorOriginal is int) {
      valor = valorOriginal;
    } else if (valorOriginal is String) {
      try {
        valor = int.parse(valorOriginal);
      } catch (e) {
        print('⚠️ Error al convertir valor de multa "$valorOriginal" a entero: $e');
      }
    } else if (valorOriginal != null) {
      print('⚠️ Tipo de valor de multa no reconocido: ${valorOriginal.runtimeType}');
    } else {
      print('⚠️ Valor de multa es nulo');
    }
    
    final contenido = multa['contenido'] as String?;
    
    print('🔄 Procesando multa: $tipoMulta');
    print('📊 Datos de la multa:');
    print('   - Valor original: $valorOriginal (${valorOriginal?.runtimeType})');
    print('   - Valor procesado: $valor');
    print('   - Contenido: $contenido');
    
    // Verificar datos inválidos
    if (valor < 0) {
      print('⚠️ Valor negativo en multa: $tipoMulta');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tipoMulta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
              Text(
                '\$${_formatearMonto(valor)}',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (contenido != null && contenido.isNotEmpty) ...[            const SizedBox(height: 8),
            Text(
              contenido,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatearMonto(int monto) {
    return monto.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}