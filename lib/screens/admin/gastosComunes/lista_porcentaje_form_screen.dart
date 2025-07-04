import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_model.dart';
import '../../../models/lista_porcentajes_model.dart';
import '../../../services/gastos_comunes_service.dart';

class ListaPorcentajeFormScreen extends StatefulWidget {
  final UserModel currentUser;
  final ListaPorcentajesModel? lista; // null para crear, con valor para editar

  const ListaPorcentajeFormScreen({
    Key? key,
    required this.currentUser,
    this.lista,
  }) : super(key: key);

  @override
  _ListaPorcentajeFormScreenState createState() => _ListaPorcentajeFormScreenState();
}

class _ListaPorcentajeFormScreenState extends State<ListaPorcentajeFormScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  final TextEditingController _nombreController = TextEditingController();
  final Map<String, TextEditingController> _porcentajeControllers = {};
  
  Map<String, ViviendaPorcentajeModel> _viviendas = {};
  bool _isLoading = true;
  bool _isSaving = false;
  int _totalPorcentaje = 0;

  bool get _esEdicion => widget.lista != null;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    for (final controller in _porcentajeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar viviendas con residentes
      final viviendas = await _gastosService.obtenerViviendasConResidentes(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      // Si es edición, cargar datos existentes
      if (_esEdicion) {
        _nombreController.text = widget.lista!.nombre;
        
        // Combinar viviendas existentes con las de la lista
        for (final entry in widget.lista!.viviendas.entries) {
          if (viviendas.containsKey(entry.key)) {
            viviendas[entry.key] = entry.value;
          }
        }
      }

      // Crear controladores para cada vivienda
      for (final entry in viviendas.entries) {
        final controller = TextEditingController(
          text: entry.value.porcentaje.toString(),
        );
        controller.addListener(() => _calcularTotalPorcentaje());
        _porcentajeControllers[entry.key] = controller;
      }

      setState(() {
        _viviendas = viviendas;
        _isLoading = false;
      });
      
      _calcularTotalPorcentaje();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calcularTotalPorcentaje() {
    int total = 0;
    for (final controller in _porcentajeControllers.values) {
      final valor = int.tryParse(controller.text) ?? 0;
      total += valor;
    }
    
    setState(() {
      _totalPorcentaje = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Lista' : 'Nueva Lista'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _guardarLista,
              child: Text(
                'GUARDAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de estado
                _buildBarraEstado(),
                
                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo nombre
                        _buildCampoNombre(),
                        const SizedBox(height: 24),
                        
                        // Botones de acción
                        _buildBotonesAccion(),
                        const SizedBox(height: 24),
                        
                        // Lista de viviendas
                        _buildListaViviendas(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBarraEstado() {
    Color backgroundColor;
    String texto;
    IconData icono;
    
    if (_totalPorcentaje == 100) {
      backgroundColor = Colors.green;
      texto = '100% repartido correctamente';
      icono = Icons.check_circle;
    } else if (_totalPorcentaje < 100) {
      backgroundColor = Colors.orange;
      texto = 'Falta repartir ${100 - _totalPorcentaje}%';
      icono = Icons.warning;
    } else {
      backgroundColor = Colors.red;
      texto = '${_totalPorcentaje - 100}% repartido en exceso';
      icono = Icons.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoNombre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre de la Lista',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            hintText: 'Ej: Lista Principal, Gastos Especiales, etc.',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _restaurarPorcentajes,
            icon: const Icon(Icons.refresh),
            label: const Text('Restaurar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _totalPorcentaje < 100 ? _completarPorcentajes : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaViviendas() {
    if (_viviendas.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay viviendas con residentes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viviendas (${_viviendas.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_viviendas.entries.map((entry) => _buildViviendaItem(entry.value)).toList()),
      ],
    );
  }

  Widget _buildViviendaItem(ViviendaPorcentajeModel vivienda) {
    final controller = _porcentajeControllers[vivienda.vivienda]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Información de la vivienda
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vivienda.descripcionVivienda,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vivienda.listaIdsResidentes.length} ${vivienda.listaIdsResidentes.length == 1 ? 'residente' : 'residentes'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Campo de porcentaje
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  final intValue = int.tryParse(value) ?? 0;
                  if (intValue > 100) {
                    controller.text = '100';
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restaurarPorcentajes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Porcentajes'),
        content: const Text(
          '¿Estás seguro de que deseas restaurar todos los porcentajes a 0%?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final controller in _porcentajeControllers.values) {
                controller.text = '0';
              }
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _completarPorcentajes() {
    if (_totalPorcentaje >= 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede completar'),
          content: const Text(
            'No hay porcentaje faltante por repartir. El total actual es igual o mayor a 100%.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Porcentajes'),
        content: Text(
          'Falta repartir ${100 - _totalPorcentaje}%. ¿Cómo deseas distribuirlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _repartirEntreCeros();
            },
            child: const Text('Entre campos en 0%'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarModalSeleccionViviendas();
            },
            child: const Text('Seleccionar viviendas'),
          ),
        ],
      ),
    );
  }

  void _repartirEntreCeros() {
    final porcentajeFaltante = 100 - _totalPorcentaje;
    final controllersCero = _porcentajeControllers.entries
        .where((entry) => (int.tryParse(entry.value.text) ?? 0) == 0)
        .toList();

    if (controllersCero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay campos con 0% para repartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final porcentajePorVivienda = porcentajeFaltante ~/ controllersCero.length;
    final resto = porcentajeFaltante % controllersCero.length;

    for (int i = 0; i < controllersCero.length; i++) {
      final porcentaje = porcentajePorVivienda + (i < resto ? 1 : 0);
      controllersCero[i].value.text = porcentaje.toString();
    }
  }

  void _mostrarModalSeleccionViviendas() {
    final viviendasSeleccionadas = <String>{};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Seleccionar Viviendas'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: _viviendas.entries.map((entry) {
                final vivienda = entry.value;
                final isSelected = viviendasSeleccionadas.contains(entry.key);
                
                return CheckboxListTile(
                  title: Text(vivienda.descripcionVivienda),
                  subtitle: Text('Actual: ${_porcentajeControllers[entry.key]!.text}%'),
                  value: isSelected,
                  onChanged: (value) {
                    setStateDialog(() {
                      if (value == true) {
                        viviendasSeleccionadas.add(entry.key);
                      } else {
                        viviendasSeleccionadas.remove(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: viviendasSeleccionadas.length < 2
                  ? null
                  : () {
                      Navigator.pop(context);
                      _repartirEntreSeleccionadas(viviendasSeleccionadas);
                    },
              child: const Text('Repartir'),
            ),
          ],
        ),
      ),
    );
  }

  void _repartirEntreSeleccionadas(Set<String> viviendasSeleccionadas) {
    final porcentajeFaltante = 100 - _totalPorcentaje;
    final porcentajePorVivienda = porcentajeFaltante ~/ viviendasSeleccionadas.length;
    final resto = porcentajeFaltante % viviendasSeleccionadas.length;

    int index = 0;
    for (final viviendaKey in viviendasSeleccionadas) {
      final controller = _porcentajeControllers[viviendaKey]!;
      final porcentajeActual = int.tryParse(controller.text) ?? 0;
      final porcentajeAdicional = porcentajePorVivienda + (index < resto ? 1 : 0);
      
      controller.text = (porcentajeActual + porcentajeAdicional).toString();
      index++;
    }
  }

  void _guardarLista() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la lista es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalPorcentaje != 100) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error de Validación'),
          content: Text(
            _totalPorcentaje < 100
                ? 'La suma de porcentajes debe ser 100%. Actualmente falta ${100 - _totalPorcentaje}%.'
                : 'La suma de porcentajes debe ser 100%. Actualmente hay ${_totalPorcentaje - 100}% en exceso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Actualizar porcentajes en el mapa de viviendas
      final viviendasActualizadas = <String, ViviendaPorcentajeModel>{};
      for (final entry in _viviendas.entries) {
        final porcentaje = int.tryParse(_porcentajeControllers[entry.key]!.text) ?? 0;
        viviendasActualizadas[entry.key] = entry.value.copyWith(porcentaje: porcentaje);
      }

      final lista = ListaPorcentajesModel(
        id: _esEdicion ? widget.lista!.id : '',
        nombre: _nombreController.text.trim(),
        condominioId: widget.currentUser.condominioId.toString(),
        viviendas: viviendasActualizadas,
        fechaCreacion: _esEdicion ? widget.lista!.fechaCreacion : DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      if (_esEdicion) {
        await _gastosService.actualizarListaPorcentajes(
          condominioId: widget.currentUser.condominioId.toString(),
          lista: lista,
        );
      } else {
        await _gastosService.crearListaPorcentajes(
          condominioId: widget.currentUser.condominioId.toString(),
          lista: lista,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion ? 'Lista actualizada correctamente' : 'Lista creada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar lista: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}