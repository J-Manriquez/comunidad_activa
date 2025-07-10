import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../../../models/user_model.dart';
import '../../../models/espacio_comun_model.dart';
import '../../../services/espacios_comunes_service.dart';

class CrearEditarEspacioScreen extends StatefulWidget {
  final UserModel currentUser;
  final EspacioComunModel? espacio; // null para crear, con valor para editar

  const CrearEditarEspacioScreen({
    Key? key,
    required this.currentUser,
    this.espacio,
  }) : super(key: key);

  @override
  State<CrearEditarEspacioScreen> createState() => _CrearEditarEspacioScreenState();
}

class _CrearEditarEspacioScreenState extends State<CrearEditarEspacioScreen> {
  final _formKey = GlobalKey<FormState>();
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nombreController;
  late TextEditingController _capacidadController;
  late TextEditingController _precioController;
  late TextEditingController _tiempoUsoController;
  late TextEditingController _descripcionController;
  late TextEditingController _horaAperturaController;
  late TextEditingController _horaCierreController;
  
  String _estadoSeleccionado = 'activo';
  List<String> _imagenesBase64 = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.espacio?.nombre ?? '');
    _capacidadController = TextEditingController(
      text: widget.espacio?.capacidad.toString() ?? '',
    );
    _precioController = TextEditingController(
      text: widget.espacio?.precio?.toString() ?? '',
    );
    _tiempoUsoController = TextEditingController(
      text: widget.espacio?.tiempoUso ?? '1',
    );
    _descripcionController = TextEditingController(
      text: widget.espacio?.descripcion ?? '',
    );
    _horaAperturaController = TextEditingController(
      text: widget.espacio?.horaApertura ?? '',
    );
    _horaCierreController = TextEditingController(
      text: widget.espacio?.horaCierre ?? '',
    );
    _estadoSeleccionado = widget.espacio?.estado ?? 'activo';
    
    // Cargar imágenes existentes si estamos editando
    if (widget.espacio?.additionalData != null) {
      final additionalData = widget.espacio!.additionalData!;
      for (int i = 1; i <= 3; i++) {
        final imagenKey = 'imagen${i}Base64';
        if (additionalData.containsKey(imagenKey) && 
            additionalData[imagenKey] != null && 
            additionalData[imagenKey].toString().isNotEmpty) {
          _imagenesBase64.add(additionalData[imagenKey]);
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _capacidadController.dispose();
    _precioController.dispose();
    _tiempoUsoController.dispose();
    _descripcionController.dispose();
    _horaAperturaController.dispose();
    _horaCierreController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    if (_imagenesBase64.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 imágenes permitidas')),
      );
      return;
    }

    try {
      setState(() {
        _isUploadingImage = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imagenesBase64.add(base64String);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesBase64.removeAt(index);
    });
  }

  Future<void> _guardarEspacio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar additionalData con las imágenes
      Map<String, dynamic>? additionalData;
      if (_imagenesBase64.isNotEmpty) {
        additionalData = {};
        for (int i = 0; i < _imagenesBase64.length && i < 3; i++) {
          additionalData['imagen${i + 1}Base64'] = _imagenesBase64[i];
        }
      }

      final espacio = EspacioComunModel(
        id: widget.espacio?.id ?? '',
        nombre: _nombreController.text.trim(),
        capacidad: int.parse(_capacidadController.text.trim()),
        precio: _precioController.text.trim().isEmpty 
            ? null 
            : int.parse(_precioController.text.trim()),
        estado: _estadoSeleccionado,
        tiempoUso: _tiempoUsoController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        horaApertura: _horaAperturaController.text.trim().isEmpty 
            ? null 
            : _horaAperturaController.text.trim(),
        horaCierre: _horaCierreController.text.trim().isEmpty 
            ? null 
            : _horaCierreController.text.trim(),
        additionalData: additionalData,
      );

      if (widget.espacio == null) {
        // Crear nuevo espacio
        await _espaciosComunesService.crearEspacioComun(
          condominioId: widget.currentUser.condominioId!,
          nombre: espacio.nombre,
          capacidad: espacio.capacidad,
          precio: espacio.precio,
          estado: espacio.estado,
          tiempoUso: espacio.tiempoUso,
          descripcion: espacio.descripcion,
          horaApertura: espacio.horaApertura,
          horaCierre: espacio.horaCierre,
          additionalData: espacio.additionalData,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio común creado exitosamente')),
          );
        }
      } else {
        // Actualizar espacio existente
        await _espaciosComunesService.actualizarEspacioComun(
          condominioId: widget.currentUser.condominioId!,
          espacioId: widget.espacio!.id,
          nombre: espacio.nombre,
          capacidad: espacio.capacidad,
          precio: espacio.precio,
          estado: espacio.estado,
          tiempoUso: espacio.tiempoUso,
          descripcion: espacio.descripcion,
          horaApertura: espacio.horaApertura,
          horaCierre: espacio.horaCierre,
          additionalData: espacio.additionalData,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio común actualizado exitosamente')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar espacio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.espacio != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Espacio Común' : 'Crear Espacio Común'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
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
            TextButton(
              onPressed: _guardarEspacio,
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
              // Nombre del espacio
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del espacio común',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el nombre del espacio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Capacidad
              TextFormField(
                controller: _capacidadController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (número de personas)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese la capacidad';
                  }
                  final capacidad = int.tryParse(value.trim());
                  if (capacidad == null || capacidad <= 0) {
                    return 'Por favor ingrese una capacidad válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Precio (opcional)
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Deje vacío si el espacio es gratuito',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final precio = int.tryParse(value.trim());
                    if (precio == null || precio < 0) {
                      return 'Por favor ingrese un precio válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Estado
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Tiempo de uso
              TextFormField(
                controller: _tiempoUsoController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de uso (horas)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  helperText: 'Duración máxima de uso en horas',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el tiempo de uso';
                  }
                  final tiempo = int.tryParse(value.trim());
                  if (tiempo == null || tiempo <= 0) {
                    return 'Por favor ingrese un tiempo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  helperText: 'Descripción del espacio común',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Hora de apertura
              InkWell(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (hora != null) {
                    setState(() {
                      _horaAperturaController.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _horaAperturaController,
                    decoration: const InputDecoration(
                      labelText: 'Hora de apertura (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                      helperText: 'Toque para seleccionar la hora',
                      suffixIcon: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Hora de cierre
              InkWell(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (hora != null) {
                    setState(() {
                      _horaCierreController.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _horaCierreController,
                    decoration: const InputDecoration(
                      labelText: 'Hora de cierre (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time_filled),
                      helperText: 'Toque para seleccionar la hora',
                      suffixIcon: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Sección de imágenes
              const Text(
                'Imágenes del espacio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puede agregar hasta 3 imágenes del espacio común',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón para agregar imagen
              if (_imagenesBase64.length < 3)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _seleccionarImagen,
                    icon: _isUploadingImage 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate),
                    label: Text(_isUploadingImage ? 'Subiendo...' : 'Agregar imagen'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              
              // Vista previa de imágenes
              if (_imagenesBase64.isNotEmpty) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _imagenesBase64.length,
                  itemBuilder: (context, index) {
                    return _buildImagePreview(index);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    final imageBytes = base64Decode(_imagenesBase64[index]);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _eliminarImagen(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}