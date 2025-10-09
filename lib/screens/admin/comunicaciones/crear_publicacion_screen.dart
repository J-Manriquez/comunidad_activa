import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../models/user_model.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/publicacion_service.dart';
import '../../../utils/storage_service.dart';
import 'package:comunidad_activa/utils/image_display_widget.dart';
import 'package:comunidad_activa/utils/fragment_storage_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  final UserModel currentUser;
  final PublicacionModel? publicacionParaEditar;

  const CrearPublicacionScreen({
    Key? key, 
    required this.currentUser,
    this.publicacionParaEditar,
  }) : super(key: key);

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final PublicacionService _publicacionService = PublicacionService();
  final StorageService _storageService = StorageService();
  
  String _tipoPublicacion = 'residentes';
  bool _isLoading = false;
  bool get _esEdicion => widget.publicacionParaEditar != null;
  
  // Variables para imágenes (ahora soportan fragmentación)
  Map<String, dynamic>? _imagen1Data;
  Map<String, dynamic>? _imagen2Data;
  Map<String, dynamic>? _imagen3Data;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _cargarDatosParaEdicion();
    }
  }

  void _cargarDatosParaEdicion() {
    final publicacion = widget.publicacionParaEditar!;
    _tituloController.text = publicacion.titulo;
    _contenidoController.text = publicacion.contenido;
    _tipoPublicacion = publicacion.tipoPublicacion;
    
    // Cargar imágenes existentes si las hay
    if (publicacion.additionalData != null) {
      // Manejar tanto imágenes base64 como fragmentadas
      final imagen1 = publicacion.additionalData!['imagen1'];
      final imagen2 = publicacion.additionalData!['imagen2'];
      final imagen3 = publicacion.additionalData!['imagen3'];
      
      if (imagen1 != null) {
        if (imagen1 is String) {
          // Imagen Base64 tradicional
          _imagen1Data = {'type': 'normal', 'data': imagen1};
        } else if (imagen1 is Map<String, dynamic>) {
          // Imagen fragmentada
          _imagen1Data = imagen1;
        }
      }
      if (imagen2 != null) {
        if (imagen2 is String) {
          // Imagen Base64 tradicional
          _imagen2Data = {'type': 'normal', 'data': imagen2};
        } else if (imagen2 is Map<String, dynamic>) {
          // Imagen fragmentada
          _imagen2Data = imagen2;
        }
      }
      if (imagen3 != null) {
        if (imagen3 is String) {
          // Imagen Base64 tradicional
          _imagen3Data = {'type': 'normal', 'data': imagen3};
        } else if (imagen3 is Map<String, dynamic>) {
          // Imagen fragmentada
          _imagen3Data = imagen3;
        }
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  // Método para seleccionar imagen con fragmentación
  Future<void> _selectImage(int imageNumber) async {
    try {
      final ImagePicker picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
          _uploadProgress = 0.0;
        });

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
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // Método para eliminar imagen
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

  Future<void> _guardarPublicacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_esEdicion) {
        // Actualizar publicación existente
        final additionalDataActualizada = Map<String, dynamic>.from(
          widget.publicacionParaEditar!.additionalData ?? {},
        );
        
        // Actualizar imágenes
        if (_imagen1Data != null) {
          additionalDataActualizada['imagen1'] = _imagen1Data!;
        } else {
          additionalDataActualizada.remove('imagen1');
        }
        
        if (_imagen2Data != null) {
          additionalDataActualizada['imagen2'] = _imagen2Data!;
        } else {
          additionalDataActualizada.remove('imagen2');
        }
        
        if (_imagen3Data != null) {
          additionalDataActualizada['imagen3'] = _imagen3Data!;
        } else {
          additionalDataActualizada.remove('imagen3');
        }

        await _publicacionService.actualizarPublicacion(
           condominioId: widget.currentUser.condominioId!,
           publicacionId: widget.publicacionParaEditar!.id,
           tipoPublicacion: _tipoPublicacion,
           contenido: _contenidoController.text.trim(),
           titulo: _tituloController.text.trim(),
           additionalData: additionalDataActualizada,
         );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Crear nueva publicación
        final Map<String, dynamic> additionalData = {
          'creadoPor': widget.currentUser.uid,
          'nombreCreador': widget.currentUser.nombre,
        };
        
        // Agregar imágenes si existen (formato fragmentado)
        if (_imagen1Data != null) additionalData['imagen1Data'] = _imagen1Data!;
        if (_imagen2Data != null) additionalData['imagen2Data'] = _imagen2Data!;
        if (_imagen3Data != null) additionalData['imagen3Data'] = _imagen3Data!;
        
        await _publicacionService.crearPublicacion(
          condominioId: widget.currentUser.condominioId!,
          tipoPublicacion: _tipoPublicacion,
          contenido: _contenidoController.text.trim(),
          titulo: _tituloController.text.trim(),
          estado: 'activa',
          additionalData: additionalData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Publicación creada exitosamente para $_tipoPublicacion',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al ${_esEdicion ? 'actualizar' : 'crear'} la publicación: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Publicación' : 'Crear Publicación',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del usuario
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentUser.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Administrador',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tipo de publicación
              const Text(
                'Dirigido a:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonFormField<String>(
                    value: _tipoPublicacion,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'residentes',
                        child: Text('Residentes'),
                      ),
                      DropdownMenuItem(
                        value: 'trabajadores',
                        child: Text('Trabajadores'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoPublicacion = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Título de la publicación:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ingrese el título de la publicación',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El título es obligatorio';
                      }
                      if (value.trim().length < 5) {
                        return 'El título debe tener al menos 5 caracteres';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contenido
              const Text(
                'Contenido:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _contenidoController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escriba el contenido de la publicación...',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El contenido es obligatorio';
                      }
                      if (value.trim().length < 10) {
                        return 'El contenido debe tener al menos 10 caracteres';
                      }
                      return null;
                    },
                    maxLines: 8,
                    maxLength: 1000,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección de imágenes
              const Text(
                'Imágenes (opcional):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes agregar hasta 3 imágenes a tu publicación',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildImagenesSection(),
              const SizedBox(height: 30),

              // Botón de crear
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarPublicacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_esEdicion ? Icons.save : Icons.publish),
                            const SizedBox(width: 8),
                            Text(
                              _esEdicion ? 'Guardar Cambios' : 'Crear Publicación para $_tipoPublicacion',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Información importante:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• La publicación será enviada a todos los usuarios del tipo seleccionado\n'
                      '• Se generará una notificación automática\n'
                      '• Los usuarios podrán ver la publicación en su pantalla de publicaciones',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagenesSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildImagePicker(_imagen1Data, 1)),
            const SizedBox(width: 12),
            Expanded(child: _buildImagePicker(_imagen2Data, 2)),
            const SizedBox(width: 12),
            Expanded(child: _buildImagePicker(_imagen3Data, 3)),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker(Map<String, dynamic>? imageData, int imageNumber) {
    return GestureDetector(
      onTap: _isUploadingImage ? null : () => _selectImage(imageNumber),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: imageData != null ? Colors.green[300]! : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: imageData != null ? Colors.green[50] : Colors.grey[50],
        ),
        child: _isUploadingImage && _getImageNumberBeingUploaded() == imageNumber
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text('${(_uploadProgress * 100).toInt()}%'),
                ],
              )
            : imageData != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImageFromData(imageData),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(imageNumber),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(12),
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploadingImage)
                        const CircularProgressIndicator()
                      else ...[
                        Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Imagen $imageNumber',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                ],
              ),
      ),
    );
  }

  // Método auxiliar para construir imagen desde datos fragmentados
  Widget _buildImageFromData(Map<String, dynamic> imageData) {
    return ImageDisplayWidget(
      imageData: imageData,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  // Método auxiliar para determinar qué imagen se está subiendo
  int? _getImageNumberBeingUploaded() {
    // Este método debería ser actualizado para rastrear qué imagen específica se está subiendo
    // Por simplicidad, retornamos null por ahora
    return null;
  }
}