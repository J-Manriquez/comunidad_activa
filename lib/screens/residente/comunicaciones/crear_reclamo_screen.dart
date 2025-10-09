import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../models/user_model.dart';
import '../../../services/reclamo_service.dart';
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';
import '../../../utils/fragment_storage_service.dart';

class CrearReclamoScreen extends StatefulWidget {
  final UserModel currentUser;

  const CrearReclamoScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _CrearReclamoScreenState createState() => _CrearReclamoScreenState();
}

class _CrearReclamoScreenState extends State<CrearReclamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contenidoController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final ReclamoService _reclamoService = ReclamoService();
  final StorageService _storageService = StorageService();
  
  String? _tipoSeleccionado;
  bool _usarTipoPersonalizado = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  
  // Variables para las imágenes (ahora soportan fragmentación)
  Map<String, dynamic>? _imagen1Data;
  Map<String, dynamic>? _imagen2Data;
  Map<String, dynamic>? _imagen3Data;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Crear Reclamo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del usuario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.person,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviado por:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.currentUser.nombre ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Tipo de reclamo
              const Text(
                'Tipo de Reclamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Seleccione el tipo de reclamo',
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  ..._reclamoService.getTiposReclamoDisponibles().map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value;
                    _usarTipoPersonalizado = value == 'Otro';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione un tipo de reclamo';
                  }
                  return null;
                },
              ),
              
              // Campo personalizado si selecciona "Otro"
              if (_usarTipoPersonalizado) ...[
                const SizedBox(height: 16),
                const Text(
                  'Especifique el tipo de reclamo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tipoPersonalizadoController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Ingrese el tipo de reclamo',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (_usarTipoPersonalizado && (value == null || value.isEmpty)) {
                      return 'Por favor especifique el tipo de reclamo';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Descripción del reclamo
              const Text(
                'Descripción del Reclamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contenidoController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Describa detalladamente su reclamo...',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción del reclamo';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Sección de imágenes
              const Text(
                'Imágenes de Evidencia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puede agregar hasta 3 imágenes como evidencia de su reclamo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildImagenesSection(),
              
              const SizedBox(height: 30),
              
              // Botón para enviar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearReclamo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enviar Reclamo',
                          style: TextStyle(
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

  Future<void> _crearReclamo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        String tipoReclamo = _usarTipoPersonalizado 
            ? _tipoPersonalizadoController.text 
            : _tipoSeleccionado!;
            
        // Preparar additionalData con imágenes fragmentadas
        Map<String, dynamic> additionalData = {};
        if (_imagen1Data != null) additionalData['imagen1Base64'] = _imagen1Data!;
        if (_imagen2Data != null) additionalData['imagen2Base64'] = _imagen2Data!;
        if (_imagen3Data != null) additionalData['imagen3Base64'] = _imagen3Data!;
        
        await _reclamoService.crearReclamo(
          condominioId: widget.currentUser.condominioId.toString(),
          residenteId: widget.currentUser.uid,
          tipoReclamo: tipoReclamo,
          contenido: _contenidoController.text,
          imagenesBase64: additionalData,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reclamo enviado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar reclamo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildImagenesSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildImagePicker(1, _imagen1Data)),
            const SizedBox(width: 8),
            Expanded(child: _buildImagePicker(2, _imagen2Data)),
            const SizedBox(width: 8),
            Expanded(child: _buildImagePicker(3, _imagen3Data)),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker(int imageNumber, Map<String, dynamic>? imageData) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageData != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImageDisplayWidget(
                    imageData: imageData,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(imageNumber),
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
            )
          : _isUploadingImage
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('${(_uploadProgress * 100).toInt()}%'),
              ],
            )
          : InkWell(
              onTap: () => _selectImage(imageNumber),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Imagen $imageNumber',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _selectImage(int imageNumber) async {
    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Usar el nuevo sistema de fragmentación
        final imageData = await _storageService.procesarImagenFragmentada(
          xFile: image,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        setState(() {
          switch (imageNumber) {
            case 1:
              _imagen1Data = imageData;
              break;
            case 2:
              _imagen2Data = imageData;
              break;
            case 3:
              _imagen3Data = imageData;
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage(int imageNumber) {
    setState(() {
      switch (imageNumber) {
        case 1:
          _imagen1Data = null;
          break;
        case 2:
          _imagen2Data = null;
          break;
        case 3:
          _imagen3Data = null;
          break;
      }
    });
  }

  @override
  void dispose() {
    _contenidoController.dispose();
    _tipoPersonalizadoController.dispose();
    super.dispose();
  }
}