import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/registro_diario_service.dart';
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';

class CrearRegistroScreen extends StatefulWidget {
  final String condominioId;

  const CrearRegistroScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<CrearRegistroScreen> createState() => _CrearRegistroScreenState();
}

class _CrearRegistroScreenState extends State<CrearRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _registroDiarioService = RegistroDiarioService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  // Variables de estado
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  UserModel? _currentUser;
  
  // Variables para imágenes (máximo 2)
  Map<String, dynamic>? _imagen1Data;
  Map<String, dynamic>? _imagen2Data;

  // Variables para campos automáticos
  String _horaActual = '';
  String _nombreUsuario = '';
  String _uidUsuario = '';
  String _tipoUsuario = '';

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _inicializarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener datos del usuario actual
      final userData = await _authService.getCurrentUserData();
      if (userData != null) {
        setState(() {
          _currentUser = userData;
          _nombreUsuario = userData.nombre;
          _uidUsuario = userData.uid;
          _tipoUsuario = userData.tipoUsuario.toString().split('.').last;
          _horaActual = DateFormat('HH:mm').format(DateTime.now());
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  Future<void> _seleccionarImagen() async {
    // Verificar si ya se han seleccionado 2 imágenes
    if (_imagen1Data != null && _imagen2Data != null) {
      _mostrarError('Solo puedes agregar hasta 2 imágenes por registro');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
          _uploadProgress = 0.0;
        });

        // Procesar la imagen usando el servicio de storage
        final imageData = await _storageService.procesarImagenFragmentada(
          xFile: image,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        setState(() {
          if (_imagen1Data == null) {
            _imagen1Data = imageData;
          } else if (_imagen2Data == null) {
            _imagen2Data = imageData;
          }
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });

        _mostrarExito('Imagen agregada correctamente');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  void _eliminarImagen(int indice) {
    setState(() {
      if (indice == 1) {
        _imagen1Data = null;
        // Si eliminamos la primera imagen y hay una segunda, mover la segunda a la primera posición
        if (_imagen2Data != null) {
          _imagen1Data = _imagen2Data;
          _imagen2Data = null;
        }
      } else if (indice == 2) {
        _imagen2Data = null;
      }
    });
  }

  Widget _buildImagePreview(Map<String, dynamic>? imageData, int indice) {
    if (imageData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageDisplayWidget(
                imageData: imageData,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _eliminarImagen(indice),
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
      ),
    );
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_comentarioController.text.trim().isEmpty) {
      _mostrarError('El comentario es obligatorio');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar datos adicionales con imágenes
      Map<String, dynamic> additionalData = {};

      if (_imagen1Data != null) {
        additionalData['imagen1'] = _imagen1Data;
      }
      if (_imagen2Data != null) {
        additionalData['imagen2'] = _imagen2Data;
      }

      // Crear el registro usando el servicio
      await _registroDiarioService.crearRegistro(
        condominioId: widget.condominioId,
        nombre: _nombreUsuario,
        uidUsuario: _uidUsuario,
        tipoUsuario: _tipoUsuario,
        comentario: _comentarioController.text.trim(),
        additionalData: additionalData.isNotEmpty ? additionalData : null,
      );

      _mostrarExito('Registro creado exitosamente');
      
      // Navegar de vuelta a la pantalla anterior después de un breve delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop(true); // Retornar true para indicar éxito
        }
      });
      
      // Limpiar el formulario
      _comentarioController.clear();
      setState(() {
        _imagen1Data = null;
        _imagen2Data = null;
        _horaActual = DateFormat('HH:mm').format(DateTime.now());
      });

    } catch (e) {
      _mostrarError('Error al crear registro: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crear Nuevo Registro'),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Registro'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información automática del usuario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del Registro',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Hora:', _horaActual),
                            _buildInfoRow('Usuario:', _nombreUsuario),
                            _buildInfoRow('Tipo:', _tipoUsuario),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Área de comentarios (textarea redimensionable)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comentario del Registro *',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.25,
                                maxHeight: MediaQuery.of(context).size.height * 0.5,
                              ),
                              child: TextFormField(
                                controller: _comentarioController,
                                decoration: const InputDecoration(
                                  hintText: 'Describe los detalles del registro diario...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(16.0),
                                ),
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El comentario es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sección de imágenes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imágenes del Registro',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puedes agregar hasta 2 imágenes',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mostrar progreso de subida si está cargando
                            if (_isUploadingImage) ...[
                              LinearProgressIndicator(value: _uploadProgress),
                              const SizedBox(height: 8),
                              Text('Procesando imagen... ${(_uploadProgress * 100).toInt()}%'),
                              const SizedBox(height: 16),
                            ],

                            // Previsualización de imágenes
                            Row(
                              children: [
                                _buildImagePreview(_imagen1Data, 1),
                                _buildImagePreview(_imagen2Data, 2),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botón para agregar imagen
                            if ((_imagen1Data == null || _imagen2Data == null) && !_isUploadingImage)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _seleccionarImagen,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: Text(
                                    _imagen1Data == null 
                                        ? 'Agregar Primera Imagen' 
                                        : 'Agregar Segunda Imagen',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón de guardar (fijo en la parte inferior)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Guardando...'),
                        ],
                      )
                    : const Text(
                        'Guardar Registro',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}