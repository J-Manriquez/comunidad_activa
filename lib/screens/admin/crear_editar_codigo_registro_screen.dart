import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/codigo_registro_model.dart';
import '../../services/codigo_registro_service.dart';
import '../../services/auth_service.dart';

class CrearEditarCodigoRegistroScreen extends StatefulWidget {
  final CodigoRegistroModel? codigo;
  final String condominioId;

  const CrearEditarCodigoRegistroScreen({Key? key, this.codigo, required this.condominioId}) : super(key: key);

  @override
  State<CrearEditarCodigoRegistroScreen> createState() => _CrearEditarCodigoRegistroScreenState();
}

class _CrearEditarCodigoRegistroScreenState extends State<CrearEditarCodigoRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _cantUsuariosController = TextEditingController();
  
  final CodigoRegistroService _codigoService = CodigoRegistroService();
  final AuthService _authService = AuthService();
  
  String _tipoUsuarioSeleccionado = 'residente';
  bool _isLoading = false;
  bool _isGeneratingCode = false;
  bool _isEditMode = false;

  final List<Map<String, String>> _tiposUsuario = [
    {'value': 'residente', 'label': 'Residente'},
    {'value': 'trabajador', 'label': 'Trabajador'},
    {'value': 'comite', 'label': 'Comité'},
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.codigo != null;
    _inicializarFormulario();
  }

  void _inicializarFormulario() {
    if (_isEditMode && widget.codigo != null) {
      _codigoController.text = widget.codigo!.codigo;
      _cantUsuariosController.text = widget.codigo!.cantUsuarios;
      _tipoUsuarioSeleccionado = widget.codigo!.tipoUsuario;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cantUsuariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Código' : 'Crear Código'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: _isGeneratingCode 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.casino),
              onPressed: _isGeneratingCode ? null : _generarCodigoAleatorio,
              tooltip: 'Generar código aleatorio',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode ? 'Editar Código de Registro' : 'Nuevo Código de Registro',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo de código
                      TextFormField(
                        controller: _codigoController,
                        decoration: InputDecoration(
                          labelText: 'Código de Registro',
                          hintText: 'Ingrese el código o genere uno aleatorio',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.code),
                          suffixIcon: !_isEditMode ? IconButton(
                            icon: _isGeneratingCode 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.casino),
                            onPressed: _isGeneratingCode ? null : _generarCodigoAleatorio,
                            tooltip: 'Generar código aleatorio',
                          ) : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese un código';
                          }
                          if (value.trim().length < 3) {
                            return 'El código debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Selector de tipo de usuario
                      DropdownButtonFormField<String>(
                        value: _tipoUsuarioSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Usuario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: _tiposUsuario.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo['value'],
                            child: Text(tipo['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipoUsuarioSeleccionado = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione un tipo de usuario';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Campo de cantidad de usuarios
                      TextFormField(
                        controller: _cantUsuariosController,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad de Usuarios',
                          hintText: 'Número máximo de usuarios que pueden usar este código',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese la cantidad de usuarios';
                          }
                          int? cantidad = int.tryParse(value.trim());
                          if (cantidad == null || cantidad <= 0) {
                            return 'Por favor ingrese un número válido mayor a 0';
                          }
                          if (cantidad > 1000) {
                            return 'La cantidad no puede ser mayor a 1000';
                          }
                          
                          // Validar en modo edición que no sea menor a usuarios ya registrados
                          if (_isEditMode && widget.codigo != null) {
                            int usuariosRegistrados = widget.codigo!.usuariosRegistrados.length;
                            if (cantidad < usuariosRegistrados) {
                              return 'No puede ser menor a $usuariosRegistrados (usuarios ya registrados)';
                            }
                          }
                          
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Información adicional
              if (!_isEditMode) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Información',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('• El código puede contener letras, números, espacios y símbolos'),
                        const Text('• Los códigos generados automáticamente tienen el formato: cod-registro-XXXXXX'),
                        const Text('• Cada código es único en todo el sistema'),
                        const Text('• Los usuarios podrán registrarse usando este código'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Información de edición
              if (_isEditMode && widget.codigo != null) ...[
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Información del Código',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('• Estado actual: ${widget.codigo!.isActivo ? "Activo" : "Inactivo"}'),
                        Text('• Usuarios registrados: ${widget.codigo!.usuariosRegistrados.length}'),
                        Text('• Creado: ${_formatearFecha(widget.codigo!.fechaIngreso)}'),
                        if (widget.codigo!.usuariosRegistrados.isNotEmpty)
                          const Text('• Nota: No puede reducir la cantidad por debajo de usuarios ya registrados'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCodigo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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
                          : Text(_isEditMode ? 'Actualizar' : 'Crear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarCodigoAleatorio() async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      String codigoGenerado = await _codigoService.generarCodigoAleatorio();
      setState(() {
        _codigoController.text = codigoGenerado;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código generado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar código: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingCode = false;
      });
    }
  }

  Future<void> _guardarCodigo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool exito;
      
      if (_isEditMode) {
        exito = await _codigoService.actualizarCodigoRegistro(
          condominioId: widget.condominioId,
          codigoId: widget.codigo!.id,
          codigo: _codigoController.text.trim(),
          tipoUsuario: _tipoUsuarioSeleccionado,
          cantUsuarios: _cantUsuariosController.text.trim(),
        );
      } else {
        exito = await _codigoService.crearCodigoRegistro(
          condominioId: widget.condominioId,
          codigo: _codigoController.text.trim(),
          tipoUsuario: _tipoUsuarioSeleccionado,
          cantUsuarios: _cantUsuariosController.text.trim(),
        );
      }

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Código actualizado exitosamente' 
                : 'Código creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Error al actualizar el código' 
                : 'Error al crear el código'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String fecha) {
    try {
      DateTime dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}