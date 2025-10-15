import 'package:flutter/material.dart';

class CampoAdicionalModal extends StatefulWidget {
  final String? nombreCampo;
  final Map<String, dynamic>? configuracionCampo;
  final Function(String nombre, Map<String, dynamic> configuracion) onSave;

  const CampoAdicionalModal({
    Key? key,
    this.nombreCampo,
    this.configuracionCampo,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CampoAdicionalModal> createState() => _CampoAdicionalModalState();
}

class _CampoAdicionalModalState extends State<CampoAdicionalModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _etiquetaController = TextEditingController();
  final _placeholderController = TextEditingController();
  
  String _tipoCampo = 'texto';
  bool _esRequerido = false;
  bool _estaActivo = true;
  List<String> _opciones = [];
  final _opcionController = TextEditingController();

  final List<String> _tiposCampo = [
    'texto',
    'numero',
    'email',
    'telefono',
    'fecha',
    'hora',
    'seleccion',
    'multiple',
    'booleano',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.nombreCampo != null && widget.configuracionCampo != null) {
      _nombreController.text = widget.nombreCampo!;
      _etiquetaController.text = widget.configuracionCampo!['etiqueta'] ?? '';
      _placeholderController.text = widget.configuracionCampo!['placeholder'] ?? '';
      _tipoCampo = widget.configuracionCampo!['tipo'] ?? 'texto';
      _esRequerido = widget.configuracionCampo!['requerido'] ?? false;
      _estaActivo = widget.configuracionCampo!['activo'] ?? true;
      _opciones = List<String>.from(widget.configuracionCampo!['opciones'] ?? []);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _etiquetaController.dispose();
    _placeholderController.dispose();
    _opcionController.dispose();
    super.dispose();
  }

  void _agregarOpcion() {
    if (_opcionController.text.trim().isNotEmpty) {
      setState(() {
        _opciones.add(_opcionController.text.trim());
        _opcionController.clear();
      });
    }
  }

  void _eliminarOpcion(int index) {
    setState(() {
      _opciones.removeAt(index);
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> configuracion = {
        'tipo': _tipoCampo,
        'etiqueta': _etiquetaController.text.trim(),
        'placeholder': _placeholderController.text.trim(),
        'requerido': _esRequerido,
        'activo': _estaActivo,
      };

      if (_tipoCampo == 'seleccion' || _tipoCampo == 'multiple') {
        configuracion['opciones'] = _opciones;
      }

      widget.onSave(_nombreController.text.trim(), configuracion);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.nombreCampo != null ? 'Editar Campo' : 'Nuevo Campo',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del campo
                      TextFormField(
                        controller: _nombreController,
                        enabled: widget.nombreCampo == null, // Solo editable si es nuevo
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Campo *',
                          hintText: 'ej: telefono_contacto',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre del campo es requerido';
                          }
                          if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value.trim())) {
                            return 'Solo letras, números y guiones bajos. Debe empezar con letra';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Etiqueta
                      TextFormField(
                        controller: _etiquetaController,
                        decoration: const InputDecoration(
                          labelText: 'Etiqueta *',
                          hintText: 'ej: Teléfono de Contacto',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La etiqueta es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tipo de campo
                      DropdownButtonFormField<String>(
                        value: _tipoCampo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Campo',
                          border: OutlineInputBorder(),
                        ),
                        items: _tiposCampo.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(_getTipoDisplayName(tipo)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipoCampo = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Placeholder
                      TextFormField(
                        controller: _placeholderController,
                        decoration: const InputDecoration(
                          labelText: 'Texto de Ayuda',
                          hintText: 'ej: Ingrese su número de teléfono',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Opciones para campos de selección
                      if (_tipoCampo == 'seleccion' || _tipoCampo == 'multiple') ...[
                        const Text(
                          'Opciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _opcionController,
                                decoration: const InputDecoration(
                                  hintText: 'Nueva opción',
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (_) => _agregarOpcion(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _agregarOpcion,
                              child: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_opciones.isNotEmpty)
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: _opciones.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  dense: true,
                                  title: Text(_opciones[index]),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarOpcion(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Switches
                      SwitchListTile(
                        title: const Text('Campo Requerido'),
                        subtitle: const Text('El usuario debe completar este campo'),
                        value: _esRequerido,
                        onChanged: (value) {
                          setState(() {
                            _esRequerido = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Campo Activo'),
                        subtitle: const Text('Mostrar este campo en el formulario'),
                        value: _estaActivo,
                        onChanged: (value) {
                          setState(() {
                            _estaActivo = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Botones
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _guardar,
                    child: Text(widget.nombreCampo != null ? 'Actualizar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'texto':
        return 'Texto';
      case 'numero':
        return 'Número';
      case 'email':
        return 'Email';
      case 'telefono':
        return 'Teléfono';
      case 'fecha':
        return 'Fecha';
      case 'hora':
        return 'Hora';
      case 'seleccion':
        return 'Selección Única';
      case 'multiple':
        return 'Selección Múltiple';
      case 'booleano':
        return 'Sí/No';
      default:
        return tipo;
    }
  }
}