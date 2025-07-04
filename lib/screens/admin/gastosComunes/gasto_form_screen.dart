import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_model.dart';
import '../../../models/gasto_comun_model.dart';
import '../../../models/lista_porcentajes_model.dart';
import '../../../services/gastos_comunes_service.dart';

class GastoFormScreen extends StatefulWidget {
  final UserModel currentUser;
  final TipoGasto tipoGasto;
  final GastoComunModel? gasto; // null para crear, con valor para editar

  const GastoFormScreen({
    Key? key,
    required this.currentUser,
    required this.tipoGasto,
    this.gasto,
  }) : super(key: key);

  @override
  _GastoFormScreenState createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final GastosComunesService _gastosService = GastosComunesService();
  
  late TextEditingController _descripcionController;
  late TextEditingController _montoController;
  late TextEditingController _periodoController;
  
  String _tipoCobro = 'igual para todos';
  String? _periodicidad;
  List<ListaPorcentajesModel> _listasPorcentajes = [];
  ListaPorcentajesModel? _listaSeleccionada;
  bool _isLoading = false;
  bool _isLoadingListas = false;
  bool get _isEditing => widget.gasto != null;
  
  final List<String> _opcionesPeriodicidad = [
    'mensual',
    'bimestral', 
    'trimestral',
    'semestral',
    'anual'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarListasPorcentajes();
  }

  void _inicializarControladores() {
    _descripcionController = TextEditingController(
      text: widget.gasto?.descripcion ?? '',
    );
    _montoController = TextEditingController(
      text: widget.gasto?.monto.toString() ?? '',
    );
    _periodoController = TextEditingController(
      text: widget.gasto?.periodo ?? '',
    );
    
    if (widget.gasto != null) {
      _tipoCobro = widget.gasto!.tipoCobro;
      _periodicidad = widget.gasto!.periodicidad;
      
      // Si tiene una lista de porcentajes guardada, la buscaremos después de cargar las listas
      if (widget.gasto!.pctjePorRes != null && widget.gasto!.pctjePorRes!.isNotEmpty) {
        // Se manejará en _cargarListasPorcentajes()
      }
    }
  }

  Future<void> _cargarListasPorcentajes() async {
    setState(() {
      _isLoadingListas = true;
    });

    try {
      final listas = await _gastosService.obtenerListasPorcentajes(
        condominioId: widget.currentUser.condominioId.toString(),
      );
      
      setState(() {
        _listasPorcentajes = listas;
        _isLoadingListas = false;
      });
      
      // Si estamos editando y hay una lista guardada, buscarla
      if (widget.gasto != null && 
          widget.gasto!.pctjePorRes != null && 
          widget.gasto!.pctjePorRes!.containsKey('nombre')) {
        final nombreLista = widget.gasto!.pctjePorRes!['nombre'];
        _listaSeleccionada = listas.firstWhere(
          (lista) => lista.nombre == nombreLista,
          orElse: () => listas.isNotEmpty ? listas.first : ListaPorcentajesModel(
            id: '',
            nombre: '',
            condominioId: '',
            viviendas: {},
            fechaCreacion: DateTime.now(),
            fechaModificacion: DateTime.now(),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _isLoadingListas = false;
      });
      print('Error al cargar listas de porcentajes: $e');
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    _periodoController.dispose();
    super.dispose();
  }

  Future<void> _guardarGasto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar que se haya seleccionado una lista si el tipo de cobro es por porcentaje
    if (_tipoCobro == 'porcentaje por residente' && _listaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una lista de porcentajes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar datos de la lista de porcentajes si es necesario
      Map<String, dynamic>? pctjePorResData;
      if (_tipoCobro == 'porcentaje por residente' && _listaSeleccionada != null) {
        pctjePorResData = {
          'nombre': _listaSeleccionada!.nombre,
          'listaId': _listaSeleccionada!.id,
          'viviendas': _listaSeleccionada!.viviendas.map(
            (key, value) => MapEntry(key, {
              'porcentaje': value.porcentaje,
              'descripcionVivienda': value.descripcionVivienda,
              'listaIdsResidentes': value.listaIdsResidentes,
            }),
          ),
        };
      }
      
      final gasto = GastoComunModel(
        id: widget.gasto?.id ?? '',
        monto: int.parse(_montoController.text.replaceAll('.', '').replaceAll(',', '')),
        descripcion: _descripcionController.text.trim(),
        tipoCobro: _tipoCobro,
        tipo: widget.tipoGasto,
        periodo: widget.tipoGasto == TipoGasto.adicional && _periodoController.text.isNotEmpty
            ? _periodoController.text.trim()
            : null,
        periodicidad: (widget.tipoGasto == TipoGasto.fijo || widget.tipoGasto == TipoGasto.variable) 
            ? _periodicidad 
            : null,
        pctjePorRes: pctjePorResData,
        additionalData: widget.gasto?.additionalData,
      );

      if (_isEditing) {
        await _gastosService.actualizarGasto(
          condominioId: widget.currentUser.condominioId.toString(),
          gasto: gasto,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _gastosService.crearGasto(
          condominioId: widget.currentUser.condominioId.toString(),
          gasto: gasto,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar gasto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  String _formatNumber(String value) {
    if (value.isEmpty) return value;
    
    // Remover caracteres no numéricos
    String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.isEmpty) return '';
    
    // Formatear con puntos como separadores de miles
    return numbers.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForTipo();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing 
              ? 'Editar Gasto ${widget.tipoGasto.nombre}'
              : 'Nuevo Gasto ${widget.tipoGasto.nombre}',
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarGasto,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descripción
              _buildSectionTitle('Descripción'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Mantenimiento ascensor, Limpieza común, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  if (value.trim().length < 3) {
                    return 'La descripción debe tener al menos 3 caracteres';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              
              // Monto
              _buildSectionTitle('Monto'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final formatted = _formatNumber(newValue.text);
                    return TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El monto es obligatorio';
                  }
                  final numericValue = value.replaceAll('.', '').replaceAll(',', '');
                  final monto = int.tryParse(numericValue);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Periodicidad (solo para gastos fijos y variables)
              if (widget.tipoGasto == TipoGasto.fijo || widget.tipoGasto == TipoGasto.variable) ...[
                _buildSectionTitle('Periodicidad'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _periodicidad,
                  decoration: InputDecoration(
                    hintText: 'Seleccione la periodicidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  items: _opcionesPeriodicidad.map((String periodicidad) {
                    return DropdownMenuItem<String>(
                      value: periodicidad,
                      child: Text(periodicidad.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _periodicidad = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La periodicidad es obligatoria para gastos ${widget.tipoGasto.nombre.toLowerCase()}s';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],
              
              // Tipo de cobro
              _buildSectionTitle('Tipo de Cobro'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Igual para todos'),
                      subtitle: const Text('Monto dividido equitativamente'),
                      value: 'igual para todos',
                      groupValue: _tipoCobro,
                      onChanged: (value) {
                        setState(() {
                          _tipoCobro = value!;
                        });
                      },
                      activeColor: color,
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('Porcentaje por residente'),
                      subtitle: const Text('Monto según porcentaje asignado'),
                      value: 'porcentaje por residente',
                      groupValue: _tipoCobro,
                      onChanged: (value) {
                        setState(() {
                          _tipoCobro = value!;
                        });
                      },
                      activeColor: color,
                    ),
                  ],
                ),
              ),
              
              // Selección de lista de porcentajes (solo cuando se selecciona porcentaje por residente)
              if (_tipoCobro == 'porcentaje por residente') ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Lista de Porcentajes'),
                const SizedBox(height: 8),
                if (_isLoadingListas)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_listasPorcentajes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay listas de porcentajes disponibles',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Debe crear al menos una lista de porcentajes antes de usar este tipo de cobro',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<ListaPorcentajesModel>(
                    value: _listaSeleccionada,
                    decoration: InputDecoration(
                      hintText: 'Seleccione una lista de porcentajes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.list),
                    ),
                    items: _listasPorcentajes.map((ListaPorcentajesModel lista) {
                      return DropdownMenuItem<ListaPorcentajesModel>(
                        value: lista,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lista.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${lista.viviendas.length} viviendas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (ListaPorcentajesModel? newValue) {
                      setState(() {
                        _listaSeleccionada = newValue;
                      });
                    },
                    validator: (value) {
                      if (_tipoCobro == 'porcentaje por residente' && value == null) {
                        return 'Debe seleccionar una lista de porcentajes';
                      }
                      return null;
                    },
                  ),
              ],
              
              // Período (solo para gastos adicionales)
              if (widget.tipoGasto == TipoGasto.adicional) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Período (Opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _periodoController,
                  decoration: InputDecoration(
                    hintText: 'Ej: 01-01-2024 hasta 31-12-2024',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                    helperText: 'Formato: dd-mm-aaaa hasta dd-mm-aaaa',
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      // Validación básica del formato de período
                      final regex = RegExp(r'^\d{2}-\d{2}-\d{4}\s+hasta\s+\d{2}-\d{2}-\d{4}\$');
                      if (!regex.hasMatch(value.trim())) {
                        return 'Formato inválido. Use: dd-mm-aaaa hasta dd-mm-aaaa';
                      }
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarGasto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Actualizar Gasto' : 'Crear Gasto',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}