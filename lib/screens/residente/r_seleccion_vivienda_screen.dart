import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../models/residente_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class ResidenteSeleccionViviendaScreen extends StatefulWidget {
  final String condominioId;
  final VoidCallback? onViviendaSeleccionada;

  const ResidenteSeleccionViviendaScreen({
    super.key,
    required this.condominioId,
    this.onViviendaSeleccionada,
  });

  @override
  State<ResidenteSeleccionViviendaScreen> createState() =>
      _ResidenteSeleccionViviendaScreenState();
}

class _ResidenteSeleccionViviendaScreenState
    extends State<ResidenteSeleccionViviendaScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  CondominioModel? _condominio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
  }

  Future<void> _loadCondominioData() async {
    try {
      final condominio = await _firestoreService.getCondominioData(
        widget.condominioId,
      );
      if (mounted) {
        setState(() {
          _condominio = condominio;
          _isLoading = false;
        });
        // DEBUG PRINT
        print(
          'Comunidad Activa DEBUG: _loadCondominioData - _condominio: ${_condominio?.toMap()}',
        );
        print(
          'Comunidad Activa DEBUG: _loadCondominioData - tipoCondominio: ${_condominio?.tipoCondominio}',
        );
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

  // Método para expandir rangos (copiado de ComunidadScreen)
  List<String> _expandirRangos(String input) {
    List<String> resultado = [];

    if (input.trim().isEmpty) return resultado;

    try {
      input = input.replaceAll(' ', '');
      List<String> partes = input.split(',');

      for (String parte in partes) {
        if (parte.contains('-')) {
          List<String> rango = parte.split('-');
          if (rango.length == 2) {
            String inicio = rango[0];
            String fin = rango[1];

            if (RegExp(r'^[0-9]+$').hasMatch(inicio) &&
                RegExp(r'^[0-9]+$').hasMatch(fin)) {
              int inicioNum = int.parse(inicio);
              int finNum = int.parse(fin);
              if (inicioNum <= finNum) {
                for (int i = inicioNum; i <= finNum; i++) {
                  resultado.add(i.toString());
                }
              }
            } else if (RegExp(r'^[A-Za-z]$').hasMatch(inicio) &&
                RegExp(r'^[A-Za-z]$').hasMatch(fin)) {
              int inicioCode = inicio.toUpperCase().codeUnitAt(0);
              int finCode = fin.toUpperCase().codeUnitAt(0);
              if (inicioCode <= finCode) {
                for (int i = inicioCode; i <= finCode; i++) {
                  resultado.add(String.fromCharCode(i));
                }
              }
            }
          }
        } else {
          if (parte.isNotEmpty) {
            resultado.add(parte);
          }
        }
      }
    } catch (e) {
      return [];
    }

    return resultado;
  }

  Future<void> _seleccionarVivienda(
    String vivienda,
    String tipo,
  ) async {
    print('🏠 Iniciando selección de vivienda: $vivienda, tipo: $tipo');
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('❌ Usuario no autenticado');
        return;
      }

      print('🔍 Obteniendo datos del residente y condominio');
      final residenteActual = await _firestoreService.getResidenteData(
        user.uid,
      );
      final condominio = await _firestoreService.getCondominioData(
        widget.condominioId,
      );

      if (residenteActual == null || condominio == null) {
        print('❌ No se encontraron datos del residente o condominio');
        return;
      }

      // Verificar si requiere confirmación del administrador
      if (condominio.requiereConfirmacionAdmin == true) {
        print(
          '⏳ Requiere confirmación del administrador - actualizando estado a pendiente',
        );

        // Actualizar estado a pendiente ANTES de crear la notificación
        await _firestoreService.actualizarEstadoViviendaResidente(
          condominio.id,
          user.uid,
          'pendiente',
        );
        print('✅ Estado actualizado a pendiente');

        // Crear notificación para el administrador
        String descripcionVivienda;
        if (tipo == 'Casa') {
          descripcionVivienda = 'Casa $vivienda';
        } else {
          final partes = vivienda.split('-');
          descripcionVivienda =
              'Departamento ${partes[1]} - Torre ${partes[0]}';
        }

        print('📨 Creando notificación para el administrador');
        // Procesar etiquetaEdificio según el tipo de vivienda
        String? etiquetaEdificio;
        String? numeroDepartamento;
        
        if (tipo == 'Departamento') {
          final partes = vivienda.split('-');
          if (partes.length >= 2) {
            etiquetaEdificio = partes[0];
            numeroDepartamento = partes[1];
          }
        }

        await _notificationService.createCondominioNotification(
          condominioId: widget.condominioId,
          tipoNotificacion: 'solicitud_vivienda',
          contenido:
              '${residenteActual.nombre} solicita seleccionar: $descripcionVivienda',
          additionalData: {
            'residenteId': user.uid,
            'residenteNombre': residenteActual.nombre,
            'residenteEmail': residenteActual.email,
            'vivienda': vivienda,
            'tipo': tipo,
            'etiquetaEdificio': etiquetaEdificio,
            'numeroDepartamento': numeroDepartamento,
            'descripcionVivienda': descripcionVivienda,
          },
        );
        print('✅ Notificación creada exitosamente');

        // En el método _seleccionarVivienda, después de crear la notificación:
        if (mounted) {
          // Mostrar diálogo de confirmación
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    const Text('Solicitud Enviada'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Su solicitud para seleccionar $descripcionVivienda ha sido enviada al administrador.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Recibirá una notificación cuando el administrador responda.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar diálogo
                      // Navigator.of(
                      //   context,
                      // ).pop(); // Cerrar pantalla de selección
                      // Navegar a la pantalla principal del residente
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                        arguments: {'condominioId': widget.condominioId},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ir a Inicio'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        print('✅ Selección directa - actualizando estado a seleccionada');
        // Selección directa (código existente)
        ResidenteModel residenteActualizado;
        // Procesar etiquetaEdificio según el tipo de vivienda
        String? etiquetaEdificio;
        String? numeroDepartamento;
        
        if (tipo == 'Departamento') {
          final partes = vivienda.split('-');
          if (partes.length >= 2) {
            etiquetaEdificio = partes[0];
            numeroDepartamento = partes[1];
          }
        }

        if (tipo == 'Casa') {
          residenteActualizado = residenteActual.copyWith(
            tipoVivienda: 'casa',
            numeroVivienda: vivienda,
            etiquetaEdificio: null,
            numeroDepartamento: null,
            viviendaSeleccionada: 'seleccionada',
          );
        } else {
          // final partes = vivienda.split('-');
          residenteActualizado = residenteActual.copyWith(
            tipoVivienda: 'departamento',
            numeroVivienda: null,
            etiquetaEdificio: etiquetaEdificio,
            numeroDepartamento: numeroDepartamento,
            viviendaSeleccionada: 'seleccionada',
          );
        }

        await _firestoreService.updateResidenteData(
          user.uid,
          residenteActualizado.toMap(),
        );
        print('✅ Datos del residente actualizados');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vivienda seleccionada: ${residenteActualizado.descripcionVivienda}',
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );

          widget.onViviendaSeleccionada?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar solicitud: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarMenuVivienda(
    BuildContext context,
    String vivienda,
    String tipo,
    Offset tapPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(tapPosition, tapPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$tipo: $vivienda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'seleccionar',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Seleccionar Vivienda'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'seleccionar') {
        _seleccionarVivienda(vivienda, tipo);
      }
    });
  }

  // Resto de métodos copiados de ComunidadScreen pero adaptados
  Widget _buildCasasCard() {
    if (_condominio?.numeroCasas == null || _condominio!.numeroCasas! <= 0) {
      return const SizedBox.shrink();
    }

    List<String> casas = [];

    if (_condominio!.rangoCasas != null &&
        _condominio!.rangoCasas!.isNotEmpty) {
      casas = _expandirRangos(_condominio!.rangoCasas!);
    } else {
      for (int i = 1; i <= _condominio!.numeroCasas!; i++) {
        casas.add(i.toString());
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Casas (${casas.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: casas
                  .map(
                    (casa) => GestureDetector(
                      onTapDown: (TapDownDetails details) {
                        _mostrarMenuVivienda(
                          context,
                          casa,
                          'Casa',
                          details.globalPosition,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Casa $casa',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Implementar métodos similares para edificios...
  // (Por brevedad, incluyo solo la estructura principal)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Vivienda'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _condominio == null
          ? const Center(
              child: Text('No se encontró información del condominio'),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // DEBUG PRINTS
                  Builder(
                    builder: (context) {
                      if (_condominio != null) {
                        print(
                          'Comunidad Activa DEBUG: build() - tipoCondominio: ${_condominio!.tipoCondominio}',
                        );
                        print(
                          'Comunidad Activa DEBUG: build() - showEdificios condition: ${_condominio!.tipoCondominio == TipoCondominio.edificio || _condominio!.tipoCondominio == TipoCondominio.mixto}',
                        );
                        print(
                          'Comunidad Activa DEBUG: build() - configuracionesEdificios: ${_condominio!.configuracionesEdificios}',
                        );
                        print(
                          'Comunidad Activa DEBUG: build() - configuracionesEdificios isNotEmpty: ${_condominio!.configuracionesEdificios?.isNotEmpty}',
                        );
                        print(
                          'Comunidad Activa DEBUG: build() - legacy numeroTorres: ${_condominio!.numeroTorres}',
                        );
                        print(
                          'Comunidad Activa DEBUG: build() - legacy apartamentosPorTorre: ${_condominio!.apartamentosPorTorre}',
                        );
                      }
                      return const SizedBox.shrink(); // This builder is just for prints, doesn't render anything visible
                    },
                  ),
                  // Instrucciones
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Seleccione su vivienda tocando sobre ella y eligiendo "Seleccionar Vivienda" en el menú.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mostrar casas si existen
                  if (_condominio!.tipoCondominio == TipoCondominio.casas ||
                      _condominio!.tipoCondominio == TipoCondominio.mixto)
                    _buildCasasCard(),

                  // Mostrar edificios si existen
                  if (_condominio!.tipoCondominio == TipoCondominio.edificio ||
                      _condominio!.tipoCondominio == TipoCondominio.mixto)
                    _buildEdificiosCard(),

                  // Mensaje si no hay configuración
                  if (_condominio!.tipoCondominio == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No hay viviendas configuradas en este condominio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEdificiosCard() {
    // DEBUG PRINT
    print('Comunidad Activa DEBUG: _buildEdificiosCard() called.');
    print(
      'Comunidad Activa DEBUG: _buildEdificiosCard - configuracionesEdificios: ${_condominio?.configuracionesEdificios}',
    );
    print(
      'Comunidad Activa DEBUG: _buildEdificiosCard - configuracionesEdificios isNotEmpty: ${_condominio?.configuracionesEdificios?.isNotEmpty}',
    );
    print(
      'Comunidad Activa DEBUG: _buildEdificiosCard - legacy numeroTorres: ${_condominio?.numeroTorres}',
    );
    print(
      'Comunidad Activa DEBUG: _buildEdificiosCard - legacy apartamentosPorTorre: ${_condominio?.apartamentosPorTorre}',
    );

    // Verificar si hay configuraciones de edificios nuevas
    if (_condominio?.configuracionesEdificios != null &&
        _condominio!.configuracionesEdificios!.isNotEmpty) {
      return Column(
        children: _condominio!.configuracionesEdificios!
            .map((config) => _buildEdificioCard(config))
            .toList(),
      );
    }

    // Compatibilidad hacia atrás - configuración única de edificio
    if (_condominio?.numeroTorres != null &&
        _condominio!.numeroTorres! > 0 &&
        _condominio?.apartamentosPorTorre != null &&
        _condominio!.apartamentosPorTorre! > 0) {
      List<String> etiquetas = [];
      if (_condominio!.etiquetasTorres != null &&
          _condominio!.etiquetasTorres!.isNotEmpty) {
        etiquetas = _expandirRangos(_condominio!.etiquetasTorres!);
      } else {
        for (int i = 1; i <= _condominio!.numeroTorres!; i++) {
          etiquetas.add('Torre $i');
        }
      }

      return Column(
        children: etiquetas
            .map(
              (etiqueta) => _buildEdificioCardLegacy(
                etiqueta,
                _condominio!.apartamentosPorTorre!,
                _condominio!.numeracion,
              ),
            )
            .toList(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEdificioCard(ConfiguracionEdificio config) {
    List<String> etiquetas = [];
    if (config.etiquetasTorres != null && config.etiquetasTorres!.isNotEmpty) {
      etiquetas = _expandirRangos(config.etiquetasTorres!);
    } else {
      for (int i = 1; i <= config.numeroTorres; i++) {
        etiquetas.add('Torre $i');
      }
    }

    return Column(
      children: etiquetas
          .map(
            (etiqueta) => Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.apartment,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$etiqueta - ${config.nombre}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDepartamentosWrap(
                      etiqueta,
                      config.apartamentosPorTorre,
                      config.numeracion,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEdificioCardLegacy(
    String etiqueta,
    int apartamentosPorTorre,
    String? numeracion,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDepartamentosWrap(etiqueta, apartamentosPorTorre, numeracion),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartamentosWrap(
    String etiqueta,
    int apartamentosPorTorre,
    String? numeracion,
  ) {
    List<String> departamentos = [];

    if (numeracion != null && numeracion.isNotEmpty) {
      departamentos = _expandirRangos(numeracion);
      // Tomar solo los departamentos necesarios para esta torre
      if (departamentos.length > apartamentosPorTorre) {
        departamentos = departamentos.take(apartamentosPorTorre).toList();
      }
    } else {
      // Generar numeración secuencial
      for (int i = 1; i <= apartamentosPorTorre; i++) {
        departamentos.add(i.toString());
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: departamentos
          .map(
            (depto) => GestureDetector(
              onTapDown: (TapDownDetails details) {
                _mostrarMenuVivienda(
                  context,
                  '$etiqueta-$depto',
                  'Departamento',
                  details.globalPosition,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$etiqueta-$depto',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
