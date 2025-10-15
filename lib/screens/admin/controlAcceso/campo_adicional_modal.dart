import 'package:flutter/material.dart';

class CampoAdicionalModal extends StatefulWidget {
  final Map<String, dynamic>? campoExistente;
  final String? claveExistente;

  const CampoAdicionalModal({
    Key? key,
    this.campoExistente,
    this.claveExistente,
  }) : super(key: key);

  @override
  State<CampoAdicionalModal> createState() => _CampoAdicionalModalState();
}

class _CampoAdicionalModalState extends State<CampoAdicionalModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  
  bool _esObligatorio = false;
  bool _estaActivo = true;

  @override
  void initState() {
    super.initState();
    if (widget.campoExistente != null) {
      _cargarDatosCampoExistente();
    }
  }

  void _cargarDatosCampoExistente() {
    final campo = widget.campoExistente!;
    _nombreController.text = widget.claveExistente ?? '';
    _esObligatorio = campo['obligatorio'] ?? false;
    _estaActivo = campo['activo'] ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_box_outlined,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.campoExistente != null 
                          ? 'Editar Campo'
                          : 'Nuevo Campo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Nombre del campo
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Campo',
                  hintText: 'Ej: Teléfono de Contacto',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del campo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Configuración del campo
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Campo Obligatorio'),
                        subtitle: const Text('El usuario debe completar este campo'),
                        value: _esObligatorio,
                        onChanged: (value) {
                          setState(() {
                            _esObligatorio = value;
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _esObligatorio ? Colors.red[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.star,
                            color: _esObligatorio ? Colors.red[700] : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Campo Activo'),
                        subtitle: const Text('Mostrar este campo en el formulario'),
                        value: _estaActivo,
                        onChanged: (value) {
                          setState(() {
                            _estaActivo = value;
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _estaActivo ? Colors.green[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.visibility,
                            color: _estaActivo ? Colors.green[700] : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarCampo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.campoExistente != null ? 'Actualizar' : 'Crear Campo',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _guardarCampo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombre = _nombreController.text.trim();
    
    final campo = {
      'tipo': 'texto', // Tipo por defecto simplificado
      'etiqueta': nombre,
      'obligatorio': _esObligatorio,
      'activo': _estaActivo,
    };

    Navigator.of(context).pop({
      'nombre': nombre.toLowerCase().replaceAll(' ', '_'),
      'campo': campo,
      'claveAnterior': widget.claveExistente,
    });
  }
}