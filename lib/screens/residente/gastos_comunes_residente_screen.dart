import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/gastos_comunes_service.dart';
import '../../services/espacios_comunes_service.dart';
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
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _gastosResidente;
  bool _isLoading = true;
  String? _error;
  UserModel? _currentUser;
  bool _cobrarMultasConGastos = false;
  bool _cobrarEspaciosConGastos = false;
  int _montoEspaciosComunes = 0;
  List<Map<String, dynamic>> _detalleEspaciosComunes = [];

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
        _cobrarMultasConGastos = condominioData.cobrarMultasConGastos ?? false; // ✅ Valor por defecto
        _cobrarEspaciosConGastos = condominioData.cobrarEspaciosConGastos ?? false; // ✅ Valor por defecto
        print('💰 Configuración cobrarMultasConGastos: $_cobrarMultasConGastos');
        print('💰 Configuración cobrarEspaciosConGastos: $_cobrarEspaciosConGastos');
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

      // Calcular costos de espacios comunes si está habilitado
      if (_cobrarEspaciosConGastos) {
        await _calcularCostosEspaciosComunes();
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

  Future<void> _calcularCostosEspaciosComunes() async {
    try {
      print('🏢 Calculando costos de espacios comunes para residente ${_currentUser!.uid}');
      
      int costoTotal = 0;
      List<Map<String, dynamic>> detalles = [];
      
      // Obtener todas las reservas aprobadas del usuario
      final reservas = await _espaciosComunesService.obtenerReservasPorResidente(
        _currentUser!.condominioId!,
        _currentUser!.uid!,
      );
      
      final reservasAprobadas = reservas.where((reserva) => reserva.estado == 'aprobada').toList();
      
      for (final reserva in reservasAprobadas) {
        int costoReserva = 0;
        String nombreEspacio = 'Espacio desconocido';
        
        // Obtener datos del espacio común para verificar si tiene precio
        final espacioComun = await _espaciosComunesService.obtenerEspacioComunPorId(
          _currentUser!.condominioId!,
          reserva.espacioId ?? '',
        );
        
        if (espacioComun != null) {
          nombreEspacio = espacioComun.nombre;
          costoReserva += espacioComun.precio ?? 0;
        }
        
        // Sumar costos de revisiones si existen
        List<Map<String, dynamic>> revisionesDetalle = [];
        if (reserva.revisionesUso != null) {
          for (final revision in reserva.revisionesUso!) {
            final costo = revision.costo ?? 0;
            if (costo > 0) {
              costoReserva += costo;
              revisionesDetalle.add({
                'tipo': revision.tipoRevision == 'pre' ? 'Pre-uso' : 'Post-uso',
                'costo': costo,
                'descripcion': revision.descripcion ?? '',
              });
            }
          }
        }
        
        // Solo agregar si hay algún costo
        if (costoReserva > 0) {
          costoTotal += costoReserva;
          
          // Calcular costo total de revisiones
          int costoTotalRevisiones = 0;
          for (final revision in revisionesDetalle) {
            costoTotalRevisiones += revision['costo'] as int;
          }
          
          detalles.add({
            'nombreEspacio': nombreEspacio,
            'fecha': reserva.fechaUso?.toString().split(' ')[0] ?? 'Sin fecha',
            'costoEspacio': espacioComun?.precio ?? 0,
            'costoRevisiones': costoTotalRevisiones,
            'revisiones': revisionesDetalle,
            'total': costoReserva,
          });
        }
      }
      
      _montoEspaciosComunes = costoTotal;
      _detalleEspaciosComunes = detalles;
      
      print('💰 Total espacios comunes: $costoTotal');
      print('📋 Detalles: ${detalles.length} reservas con costo');
      
    } catch (e) {
      print('❌ Error al calcular costos de espacios comunes: $e');
      _montoEspaciosComunes = 0;
      _detalleEspaciosComunes = [];
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
    
    // Calcular total incluyendo espacios comunes si está habilitado
    final montoTotalConEspacios = montoTotal + (_cobrarEspaciosConGastos ? _montoEspaciosComunes : 0);
    
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
    if (_cobrarMultasConGastos && montoMultas > 0) {
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
            
            // Mostrar subtotales si hay multas o espacios comunes incluidos
            if ((_cobrarMultasConGastos && montoMultas > 0) || (_cobrarEspaciosConGastos && _montoEspaciosComunes > 0)) ...[              
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
              
              // Mostrar multas si están incluidas
              if (_cobrarMultasConGastos && montoMultas > 0) ...[
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
                const SizedBox(height: 8),
              ],
              
              // Mostrar espacios comunes si están incluidos
              if (_cobrarEspaciosConGastos && _montoEspaciosComunes > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Espacios Comunes:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${_formatearMonto(_montoEspaciosComunes)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              const SizedBox(height: 4),
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
              '\$${_formatearMonto(montoTotalConEspacios)}',
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
    print('💰 cobrarMultasConGastos: $_cobrarMultasConGastos');
    print('📋 Contenido completo de _gastosResidente: $_gastosResidente');

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
    if (_cobrarMultasConGastos && detalleMultas.isNotEmpty) {
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
        
        // Mostrar desglose de multas si están incluidas
        if (!_cobrarMultasConGastos) ...[
          const SizedBox(height: 16),
          if (detalleMultas.isNotEmpty) 
            _buildMultasCard(detalleMultas)
          else
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No hay multas registradas para esta vivienda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        
        // Mostrar desglose de espacios comunes si están incluidos
        if (_cobrarEspaciosConGastos) ...[
          const SizedBox(height: 16),
          if (_detalleEspaciosComunes.isNotEmpty) 
            _buildEspaciosComunesCard(_detalleEspaciosComunes)
          else
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.home_work, color: Colors.purple[600]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No hay costos de espacios comunes para esta vivienda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildEspaciosComunesCard(List<Map<String, dynamic>> espacios) {
    print('🔄 Construyendo tarjeta de espacios comunes con ${espacios.length} espacios');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.home_work, color: Colors.purple[600]),
        title: const Text(
          'Espacios Comunes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '\$${_formatearMonto(_montoEspaciosComunes)}',
          style: TextStyle(
            color: Colors.purple[600],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: espacios.map((espacio) => _buildEspacioComunItem(espacio)).toList(),
      ),
    );
  }

  Widget _buildEspacioComunItem(Map<String, dynamic> espacio) {
    final nombreEspacio = espacio['nombreEspacio'] as String? ?? 'Espacio sin nombre';
    final costoEspacio = espacio['costoEspacio'] as int? ?? 0;
    final costoRevisiones = espacio['costoRevisiones'] as int? ?? 0;
    final fecha = espacio['fecha'] as String? ?? '';
    final totalCosto = costoEspacio + costoRevisiones;
    
    // Formatear fecha
    String fechaFormateada = 'Fecha no disponible';
    if (fecha.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(fecha);
        fechaFormateada = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } catch (e) {
        fechaFormateada = fecha;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Nombre del espacio y costo total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.purple[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nombreEspacio,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.purple[800],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.purple[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  '\$${_formatearMonto(totalCosto)}',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          // Segunda fila: Desglose de costos
          if (costoEspacio > 0 || costoRevisiones > 0) ...[
            const SizedBox(height: 8),
            if (costoEspacio > 0)
              Text(
                'Costo del espacio: \$${_formatearMonto(costoEspacio)}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            if (costoRevisiones > 0)
              Text(
                'Costo de revisiones: \$${_formatearMonto(costoRevisiones)}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
          ],
          
          // Tercera fila: Fecha de reserva
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Fecha de reserva: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                fechaFormateada,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
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
    final fechaRegistro = multa['fechaRegistro'] as String?;
    
    // Formatear fecha de aplicación
    String fechaAplicacion = 'Fecha no disponible';
    if (fechaRegistro != null && fechaRegistro.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(fechaRegistro);
        fechaAplicacion = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      } catch (e) {
        print('⚠️ Error al formatear fecha de multa: $e');
        fechaAplicacion = fechaRegistro;
      }
    }
    
    print('🔄 Procesando multa: $tipoMulta');
    print('📊 Datos de la multa:');
    print('   - Valor original: $valorOriginal (${valorOriginal?.runtimeType})');
    print('   - Valor procesado: $valor');
    print('   - Contenido: $contenido');
    print('   - Fecha de aplicación: $fechaAplicacion');
    
    // Verificar datos inválidos
    if (valor < 0) {
      print('⚠️ Valor negativo en multa: $tipoMulta');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Tipo de multa y valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tipoMulta,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red[800],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  '\$${_formatearMonto(valor)}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          // Segunda fila: Descripción (si existe)
          if (contenido != null && contenido.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              contenido,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
          
          // Tercera fila: Fecha de aplicación
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Aplicada el: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                fechaAplicacion,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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