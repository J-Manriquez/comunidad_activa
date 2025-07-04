import 'package:flutter/material.dart';
import '../services/multa_service.dart';
import '../models/multa_model.dart';

class CrearMultaDialog extends StatefulWidget {
  final String condominioId;
  final String tipoVivienda;
  final String numeroVivienda;
  final String? etiquetaEdificio;
  final String? numeroDepartamento;

  const CrearMultaDialog({
    Key? key,
    required this.condominioId,
    required this.tipoVivienda,
    required this.numeroVivienda,
    this.etiquetaEdificio,
    this.numeroDepartamento,
  }) : super(key: key);

  @override
  _CrearMultaDialogState createState() => _CrearMultaDialogState();
}

class _CrearMultaDialogState extends State<CrearMultaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contenidoController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final _valorPersonalizadoController = TextEditingController();
  final _unidadPersonalizadaController = TextEditingController();
  
  final MultaService _multaService = MultaService();
  
  List<GestionMulta> _tiposMultas = [];
  String? _tipoSeleccionado;
  int? _valorSeleccionado;
  String? _unidadSeleccionada;
  bool _isLoading = false;
  bool _usarTipoPersonalizado = false;
  bool _usarValorPersonalizado = false;
  bool _usarUnidadPersonalizada = false;

  @override
  void initState() {
    super.initState();
    _cargarTiposMultas();
  }

  Future<void> _cargarTiposMultas() async {
    try {
      final tipos = await _multaService.obtenerTiposMultas(widget.condominioId);
      setState(() => _tiposMultas = tipos);
    } catch (e) {
      print('Error al cargar tipos de multas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear Multa',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Información de la vivienda
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vivienda: ${widget.tipoVivienda} ${widget.numeroVivienda}'),
                    if (widget.etiquetaEdificio != null)
                      Text('Edificio: ${widget.etiquetaEdificio} - Depto: ${widget.numeroDepartamento}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tipo de multa
              const Text('Tipo de Multa:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Seleccione el tipo de multa',
                ),
                items: [
                  ..._tiposMultas.map((tipo) => DropdownMenuItem(
                    value: tipo.tipoMulta,
                    child: Text(tipo.tipoMulta),
                  )),
                  const DropdownMenuItem(
                    value: 'otro',
                    child: Text('Otro (personalizado)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value;
                    _usarTipoPersonalizado = value == 'otro';
                    
                    if (value != 'otro' && value != null) {
                      final tipoEncontrado = _tiposMultas.firstWhere(
                        (tipo) => tipo.tipoMulta == value,
                        orElse: () => GestionMulta(id: '', tipoMulta: '', valor: 0, unidadMedida: ''),
                      );
                      _valorSeleccionado = tipoEncontrado.valor;
                      _unidadSeleccionada = tipoEncontrado.unidadMedida;
                      // Resetear flags de personalización cuando se selecciona un tipo predefinido
                      _usarValorPersonalizado = false;
                      _usarUnidadPersonalizada = false;
                    } else if (value == 'otro') {
                      // Cuando se selecciona "otro", limpiar valores predefinidos
                      _valorSeleccionado = null;
                      _unidadSeleccionada = null;
                      // Forzar el uso de valores personalizados
                      _usarValorPersonalizado = true;
                      _usarUnidadPersonalizada = true;
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione un tipo de multa';
                  }
                  return null;
                },
              ),
              
              if (_usarTipoPersonalizado) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tipoPersonalizadoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de multa personalizado',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_usarTipoPersonalizado && (value == null || value.isEmpty)) {
                      return 'Por favor ingrese el tipo de multa';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Valor y unidad de medida
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Valor:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (!_usarValorPersonalizado && _valorSeleccionado != null && !_usarTipoPersonalizado)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_valorSeleccionado.toString()),
                          )
                        else
                          TextFormField(
                            controller: _valorPersonalizadoController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Valor',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el valor';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        if (!_usarTipoPersonalizado)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _usarValorPersonalizado = !_usarValorPersonalizado;
                              });
                            },
                            child: Text(_usarValorPersonalizado ? 'Usar valor predefinido' : 'Usar valor personalizado'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (!_usarUnidadPersonalizada && _unidadSeleccionada != null && !_usarTipoPersonalizado)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_unidadSeleccionada!),
                          )
                        else
                          TextFormField(
                            controller: _unidadPersonalizadaController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Unidad',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese la unidad';
                              }
                              return null;
                            },
                          ),
                        if (!_usarTipoPersonalizado)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _usarUnidadPersonalizada = !_usarUnidadPersonalizada;
                              });
                            },
                            child: Text(_usarUnidadPersonalizada ? 'Usar unidad predefinida' : 'Usar unidad personalizada'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Contenido de la multa
              const Text('Descripción de la multa:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Describa la causa de la multa...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción de la multa';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _crearMulta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear Multa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _crearMulta() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        String tipoMulta = _usarTipoPersonalizado 
            ? _tipoPersonalizadoController.text 
            : _tipoSeleccionado!;
            
        int valor;
        if (_usarValorPersonalizado || _usarTipoPersonalizado) {
          valor = int.parse(_valorPersonalizadoController.text);
        } else {
          valor = _valorSeleccionado ?? 0;
        }
            
        String unidadMedida;
        if (_usarUnidadPersonalizada || _usarTipoPersonalizado) {
          unidadMedida = _unidadPersonalizadaController.text;
        } else {
          unidadMedida = _unidadSeleccionada ?? '';
        }
        
        await _multaService.crearMulta(
          condominioId: widget.condominioId,
          tipoMulta: tipoMulta,
          contenido: _contenidoController.text,
          tipoVivienda: widget.tipoVivienda,
          numeroVivienda: widget.numeroVivienda,
          etiquetaEdificio: widget.etiquetaEdificio,
          numeroDepartamento: widget.numeroDepartamento,
          valor: valor,
          unidadMedida: unidadMedida,
        );
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Multa creada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear multa: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contenidoController.dispose();
    _tipoPersonalizadoController.dispose();
    _valorPersonalizadoController.dispose();
    _unidadPersonalizadaController.dispose();
    super.dispose();
  }
}