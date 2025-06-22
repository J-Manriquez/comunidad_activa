import 'package:comunidad_activa/widgets/crear_multa_dialog.dart';
import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../models/multa_model.dart';
import '../../services/firestore_service.dart';
import '../../services/multa_service.dart';

class ComunidadScreen extends StatefulWidget {
  final String condominioId;

  const ComunidadScreen({super.key, required this.condominioId});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final FirestoreService _firestoreService = FirestoreService();
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

  // Método para expandir rangos
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

  // Nuevo método para mostrar el diálogo de crear multa
  void _mostrarDialogoCrearMulta(
    BuildContext context,
    String vivienda,
    String tipo,
  ) {
    // navegar a CrearMultaDialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearMultaDialog(
          condominioId: widget.condominioId,
          tipoVivienda: tipo,
          numeroVivienda: vivienda,
        ),
      ),
    );
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
        PopupMenuItem<String>(
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
        PopupMenuItem<String>(
          value: 'residentes',
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Visualizar residentes'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'crear_multa',
          child: Row(
            children: [
              Icon(Icons.gavel, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Crear Multa'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'residentes') {
        // TODO: Implementar visualización de residentes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visualizar residentes de $tipo $vivienda - Por implementar',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (value == 'crear_multa') {
        _mostrarDialogoCrearMulta(context, vivienda, tipo);
      }
    });
  }

  Widget _buildCasasCard() {
    if (_condominio?.numeroCasas == null || _condominio!.numeroCasas! <= 0) {
      return const SizedBox.shrink();
    }

    List<String> casas = [];

    // Si hay rango de casas configurado, expandirlo
    if (_condominio!.rangoCasas != null &&
        _condominio!.rangoCasas!.isNotEmpty) {
      casas = _expandirRangos(_condominio!.rangoCasas!);
    } else {
      // Si no hay rango, generar números secuenciales
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

  Widget _buildEdificiosCard() {
    // Verificar si hay configuraciones de edificios
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
    String torre,
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
                  '$torre-$depto',
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
                  '$torre-$depto',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        backgroundColor: Colors.orange.shade600,
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
                        'No hay viviendas configuradas.\nVaya a Configuración > Viviendas para configurar las viviendas del condominio.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
