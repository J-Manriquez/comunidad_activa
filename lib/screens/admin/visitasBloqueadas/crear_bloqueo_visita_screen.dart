import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/visita_bloqueada_model.dart';
import '../../../services/bloqueo_visitas_service.dart';
import '../../../services/notification_service.dart'; // Importar el servicio de notificaciones
import '../../../services/firestore_service.dart'; // Importar el servicio de Firestore
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';
import '../../../widgets/seleccion_vivienda_bloqueo_modal.dart';

// Formateador personalizado para RUT chileno
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Obtener solo los dígitos y K/k
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '');
    
    // Limitar a máximo 9 caracteres (8 dígitos + 1 verificador)
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    
    // Si está vacío, retornar vacío
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    
    String formatted = '';
    
    // Si tiene más de 1 carácter, formatear
    if (digits.length > 1) {
      // Separar número y dígito verificador
      String numero = digits.substring(0, digits.length - 1);
      String verificador = digits.substring(digits.length - 1).toUpperCase();
      
      // Formatear el número con puntos
      String numeroFormateado = '';
      for (int i = 0; i < numero.length; i++) {
        if (i > 0 && (numero.length - i) % 3 == 0) {
          numeroFormateado += '.';
        }
        numeroFormateado += numero[i];
      }
      
      formatted = '$numeroFormateado-$verificador';
    } else {
      formatted = digits;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CrearBloqueoVisitaScreen extends StatefulWidget {
  final UserModel currentUser;

  const CrearBloqueoVisitaScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CrearBloqueoVisitaScreen> createState() => _CrearBloqueoVisitaScreenState();
}

class _CrearBloqueoVisitaScreenState extends State<CrearBloqueoVisitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloqueoService = BloqueoVisitasService();
  final _notificationService = NotificationService(); // Instancia del servicio de notificaciones
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;

  // Controladores de texto
  final _nombreVisitanteController = TextEditingController();
  final _rutVisitanteController = TextEditingController();
  final _viviendaController = TextEditingController();
  final _motivoBloqueoController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  bool _enviarNotificacion = false; // Nueva variable para el toggle de notificación

  // Variables para imágenes
  Map<String, dynamic>? _imagen1Data;
  Map<String, dynamic>? _imagen2Data;
  Map<String, dynamic>? _imagen3Data;

  @override
  void dispose() {
    _nombreVisitanteController.dispose();
    _rutVisitanteController.dispose();
    _viviendaController.dispose();
    _motivoBloqueoController.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // Validación de nombre completo (mínimo 2 palabras)
  bool _validarNombreCompleto(String nombre) {
    final nombreTrimmed = nombre.trim();
    if (nombreTrimmed.isEmpty) return false;
    
    final palabras = nombreTrimmed.split(RegExp(r'\s+'));
    return palabras.length >= 2 && palabras.every((palabra) => palabra.isNotEmpty);
  }

  // Validación de RUT chileno con dígito verificador
  bool _validarRutChileno(String rut) {
    // Limpiar el RUT de puntos y guiones
    String rutLimpio = rut.replaceAll(RegExp(r'[.-]'), '').toUpperCase();
    
    if (rutLimpio.length < 2) return false;
    
    // Separar número y dígito verificador
    String numero = rutLimpio.substring(0, rutLimpio.length - 1);
    String digitoVerificador = rutLimpio.substring(rutLimpio.length - 1);
    
    // Verificar que el número sea numérico
    if (!RegExp(r'^\d+$').hasMatch(numero)) return false;
    
    // Validar que el número no sea todo ceros o muy corto
    int numeroInt = int.parse(numero);
    if (numeroInt < 1000000 || numeroInt > 99999999) return false; // RUT debe estar entre 1.000.000 y 99.999.999
    
    // Rechazar patrones inválidos comunes
    if (numero == '00000000' || numero == '11111111' || numero == '22222222' || 
        numero == '33333333' || numero == '44444444' || numero == '55555555' ||
        numero == '66666666' || numero == '77777777' || numero == '88888888' || 
        numero == '99999999') {
      return false;
    }
    
    // Calcular dígito verificador
    int suma = 0;
    int multiplicador = 2;
    
    for (int i = numero.length - 1; i >= 0; i--) {
      suma += int.parse(numero[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    
    int resto = suma % 11;
    String digitoCalculado = resto == 0 ? '0' : resto == 1 ? 'K' : (11 - resto).toString();
    
    return digitoVerificador == digitoCalculado;
  }

  // Validación de motivo con mínimo de caracteres no espacios
  bool _validarMotivoBloqueo(String motivo, {int minimoCaracteres = 10}) {
    final motivoSinEspacios = motivo.replaceAll(RegExp(r'\s'), '');
    return motivoSinEspacios.length >= minimoCaracteres;
  }

  // Validación de que al menos una imagen esté presente
  bool _validarImagenes() {
    return _imagen1Data != null || _imagen2Data != null || _imagen3Data != null;
  }

  bool _validarFormulario() {
    // Validar nombre completo
    if (!_validarNombreCompleto(_nombreVisitanteController.text)) {
      _mostrarError('El nombre debe contener al menos nombre y apellido');
      return false;
    }

    // Validar RUT chileno
    if (!_validarRutChileno(_rutVisitanteController.text)) {
      _mostrarError('El RUT ingresado no es válido. Formato: 12.345.678-9');
      return false;
    }

    // Validar vivienda
    if (_viviendaController.text.trim().isEmpty) {
      _mostrarError('La vivienda es obligatoria');
      return false;
    }

    // Validar motivo del bloqueo
    if (!_validarMotivoBloqueo(_motivoBloqueoController.text)) {
      _mostrarError('El motivo debe tener al menos 10 caracteres válidos (sin contar espacios)');
      return false;
    }

    // Validar que al menos una imagen esté presente
    if (!_validarImagenes()) {
      _mostrarError('Debe agregar al menos una imagen como evidencia');
      return false;
    }

    return true;
  }

  Future<void> _mostrarSeleccionVivienda() async {
    final viviendaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => SeleccionViviendaBloqueoModal(
        condominioId: widget.currentUser.condominioId ?? '',
        onSeleccion: (vivienda) {
          Navigator.of(context).pop(vivienda);
        },
      ),
    );

    if (viviendaSeleccionada != null) {
      setState(() {
        _viviendaController.text = viviendaSeleccionada;
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    // Verificar cuántas imágenes ya tenemos
    int imagenesActuales = 0;
    if (_imagen1Data != null) imagenesActuales++;
    if (_imagen2Data != null) imagenesActuales++;
    if (_imagen3Data != null) imagenesActuales++;
    
    if (imagenesActuales >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 imágenes permitidas')),
      );
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

        // Procesar la imagen
        final imageData = await _storageService.procesarImagenFragmentada(
          xFile: image,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (imageData != null) {
          // Si es fragmentación externa, guardar fragmentos en Firestore
          if (imageData['type'] == 'external_fragmented') {
            await _guardarFragmentosExternos(imageData);
            // Remover los fragmentos del objeto principal para evitar duplicación
            final cleanImageData = Map<String, dynamic>.from(imageData);
            cleanImageData.remove('fragments');
            
            setState(() {
              // Asignar a la primera posición disponible
              if (_imagen1Data == null) {
                _imagen1Data = cleanImageData;
              } else if (_imagen2Data == null) {
                _imagen2Data = cleanImageData;
              } else if (_imagen3Data == null) {
                _imagen3Data = cleanImageData;
              }
              _isUploadingImage = false;
            });
          } else {
            setState(() {
              // Asignar a la primera posición disponible
              if (_imagen1Data == null) {
                _imagen1Data = imageData;
              } else if (_imagen2Data == null) {
                _imagen2Data = imageData;
              } else if (_imagen3Data == null) {
                _imagen3Data = imageData;
              }
              _isUploadingImage = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen agregada exitosamente')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      switch (index) {
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

  Widget _buildImagePreview(Map<String, dynamic>? imageData, int index) {
    if (imageData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: ImageDisplayWidget(
              imageData: imageData,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _eliminarImagen(index),
              child: Container(
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

  Future<void> _crearBloqueoVisita() async {
    if (!_validarFormulario()) return;

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
      if (_imagen3Data != null) {
        additionalData['imagen3'] = _imagen3Data;
      }

      // Crear la visita bloqueada usando el servicio
      final visitaBloqueada = VisitaBloqueadaModel(
        id: _firestore.collection('temp').doc().id, // Generar ID único
        nombreVisitante: _nombreVisitanteController.text.trim(),
        rutVisitante: _rutVisitanteController.text.trim(),
        viviendaBloqueo: _viviendaController.text.trim(),
        motivoBloqueo: _motivoBloqueoController.text.trim(),
        fechaBloqueo: Timestamp.now(),
        bloqueadoPor: widget.currentUser.uid,
        estado: 'activo',
        additionalData: additionalData.isNotEmpty ? additionalData : null,
      );

      final success = await _bloqueoService.crearVisitaBloqueada(
        widget.currentUser.condominioId!,
        visitaBloqueada,
      );

      if (success) {
        // Si se creó exitosamente y se debe enviar notificación
        if (_enviarNotificacion) {
          await _enviarNotificacionBloqueoVisita(visitaBloqueada);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bloqueo de visita creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      } else {
        _mostrarError('Error al crear el bloqueo de visita');
      }
    } catch (e) {
      _mostrarError('Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para enviar notificación de bloqueo de visita
  Future<void> _enviarNotificacionBloqueoVisita(VisitaBloqueadaModel visitaBloqueada) async {
    try {
      print('🔔 Enviando notificaciones de bloqueo de visita...');
      
      // Obtener residentes de la vivienda afectada
      final firestoreService = FirestoreService();
      final residentes = await firestoreService.getResidentesByViviendaDescripcion(
        widget.currentUser.condominioId!,
        visitaBloqueada.viviendaBloqueo,
      );
      
      if (residentes.isEmpty) {
        print('⚠️ No se encontraron residentes para la vivienda: ${visitaBloqueada.viviendaBloqueo}');
        return;
      }
      
      final contenido = 'Se ha bloqueado el acceso del visitante ${visitaBloqueada.nombreVisitante} (${visitaBloqueada.rutVisitante}) a su vivienda. Motivo: ${visitaBloqueada.motivoBloqueo}';
      
      final additionalData = {
        'visitaBloqueadaId': visitaBloqueada.id,
        'nombreVisitante': visitaBloqueada.nombreVisitante,
        'rutVisitante': visitaBloqueada.rutVisitante,
        'viviendaBloqueo': visitaBloqueada.viviendaBloqueo,
        'motivoBloqueo': visitaBloqueada.motivoBloqueo,
        'fechaBloqueo': visitaBloqueada.fechaBloqueo.toDate().toIso8601String(),
        'bloqueadoPor': widget.currentUser.uid,
      };

      // Enviar notificación individual a cada residente de la vivienda
      for (final residente in residentes) {
        try {
          await _notificationService.createUserNotification(
            condominioId: widget.currentUser.condominioId!,
            userId: residente.uid,
            userType: 'residentes',
            tipoNotificacion: 'bloqueo_visita',
            contenido: contenido,
            additionalData: additionalData,
          );
          print('✅ Notificación enviada a: ${residente.nombre}');
        } catch (e) {
          print('❌ Error al enviar notificación a ${residente.nombre}: $e');
        }
      }

      print('🎯 Notificaciones de bloqueo de visita enviadas a ${residentes.length} residentes');
    } catch (e) {
      print('❌ Error al enviar notificaciones de bloqueo de visita: $e');
      // No mostrar error al usuario ya que el bloqueo se creó exitosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Bloqueo de Visita'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del visitante
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Visitante',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreVisitanteController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rutVisitanteController,
                        decoration: const InputDecoration(
                          labelText: 'RUT *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                          hintText: '12.345.678-9',
                        ),
                        inputFormatters: [
                          RutInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El RUT es obligatorio';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información del bloqueo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Bloqueo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _mostrarSeleccionVivienda,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _viviendaController,
                            decoration: const InputDecoration(
                              labelText: 'Vivienda *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                              hintText: 'Seleccionar vivienda',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La vivienda es obligatoria';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _motivoBloqueoController,
                        decoration: const InputDecoration(
                          labelText: 'Motivo del Bloqueo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El motivo es obligatorio';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Evidencias fotográficas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidencias Fotográficas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puedes agregar hasta 3 imágenes como evidencia',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mostrar imágenes seleccionadas
                      if (_imagen1Data != null || _imagen2Data != null || _imagen3Data != null)
                        Column(
                          children: [
                            Row(
                              children: [
                                _buildImagePreview(_imagen1Data, 1),
                                _buildImagePreview(_imagen2Data, 2),
                                _buildImagePreview(_imagen3Data, 3),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Botón para agregar imagen
                      if ((_imagen1Data == null || _imagen2Data == null || _imagen3Data == null) && !_isUploadingImage)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarImagen,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Agregar Imagen'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                      // Indicador de carga de imagen
                      if (_isUploadingImage)
                        Column(
                          children: [
                            const Text('Procesando imagen...'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _uploadProgress),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle para enviar notificación
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _enviarNotificacion,
                            onChanged: (value) {
                              setState(() {
                                _enviarNotificacion = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Enviar notificación a los residentes de la vivienda sobre el bloqueo de visita',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón de crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearBloqueoVisita,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
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
                            SizedBox(width: 8),
                            Text('Creando Bloqueo...'),
                          ],
                        )
                      : const Text(
                          'Crear Bloqueo de Visita',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para guardar fragmentos externos en Firestore
  Future<void> _guardarFragmentosExternos(Map<String, dynamic> imageData) async {
    if (imageData['type'] != 'external_fragmented' || imageData['fragments'] == null) {
      return;
    }

    final fragments = imageData['fragments'] as List<Map<String, dynamic>>;
    final fragmentId = imageData['fragmentId'] as String;

    for (final fragment in fragments) {
      try {
        await FirebaseFirestore.instance
            .collection('image_fragments')
            .doc('${fragmentId}_${fragment['index']}')
            .set({
          'fragmentId': fragmentId,
          'index': fragment['index'],
          'data': fragment['data'],
          'totalFragments': fragments.length,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error al guardar fragmento ${fragment['index']}: $e');
        throw Exception('Error al guardar fragmento de imagen: $e');
      }
    }
  }
}