import 'package:comunidad_activa/models/reserva_model.dart';
import 'package:comunidad_activa/models/revision_uso_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';

class CrearRevisionScreen extends StatefulWidget {
  final UserModel currentUser;
  final ReservaModel reserva;

  const CrearRevisionScreen({
    Key? key,
    required this.currentUser,
    required this.reserva,
  }) : super(key: key);

  @override
  State<CrearRevisionScreen> createState() => _CrearRevisionScreenState();
}

class _CrearRevisionScreenState extends State<CrearRevisionScreen> {
  final _formKey = GlobalKey<FormState>();
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _descripcionController;
  late TextEditingController _costoController;
  
  String _estadoSeleccionado = 'aprobado';
  String _tipoRevision = 'post_uso'; // 'pre_uso' o 'post_uso'
  List<String> _imagenesBase64 = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
    _costoController = TextEditingController();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _costoController.dispose();
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

  Future<void> _guardarRevision() async {
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

      final revision = RevisionUsoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fecha: DateTime.now().toIso8601String(),
        descripcion: _descripcionController.text.trim(),
        estado: _estadoSeleccionado,
        costo: _costoController.text.trim().isEmpty 
            ? null 
            : int.parse(_costoController.text.trim()),
        tipoRevision: _tipoRevision,
        additionalData: additionalData,
      );

      await _espaciosComunesService.agregarRevisionPostUso(
        condominioId: widget.currentUser.condominioId!,
        reservaId: widget.reserva.id,
        descripcion: revision.descripcion,
        estado: revision.estado,
        tipoRevision: revision.tipoRevision,
        costo: revision.costo,
        additionalData: revision.additionalData,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revisión post uso creada exitosamente')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar revisión: $e')),
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
    final fechaReserva = DateTime.parse(widget.reserva.fechaHoraReserva);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_tipoRevision == 'pre_uso' ? 'Crear Revisión Pre Uso' : 'Crear Revisión Post Uso'),
        backgroundColor: Colors.green.shade600,
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
              onPressed: _guardarRevision,
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
              // Información de la reserva
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la Reserva',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.business, 'Espacio:', widget.reserva.nombreEspacioComun),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.home, 'Vivienda:', widget.reserva.vivienda),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today, 
                        'Fecha y hora:', 
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.people, 
                        'Participantes:', 
                        '${widget.reserva.participantes.length} personas',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Toggle para tipo de revisión
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Revisión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Pre Uso'),
                              subtitle: const Text('Antes del uso del espacio'),
                              value: 'pre_uso',
                              groupValue: _tipoRevision,
                              onChanged: (value) {
                                setState(() {
                                  _tipoRevision = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Post Uso'),
                              subtitle: const Text('Después del uso del espacio'),
                              value: 'post_uso',
                              groupValue: _tipoRevision,
                              onChanged: (value) {
                                setState(() {
                                  _tipoRevision = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Formulario de revisión
              Text(
                _tipoRevision == 'pre_uso' ? 'Revisión Pre Uso' : 'Revisión Post Uso',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción de la revisión',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  helperText: 'Describa el estado del espacio después del uso',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Estado de la revisión
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado de la revisión',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: const [
                  DropdownMenuItem(value: 'aprobado', child: Text('Aprobado - Sin problemas')),
                  DropdownMenuItem(value: 'rechazado', child: Text('Rechazado - Con problemas')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Costo adicional (opcional)
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(
                  labelText: 'Costo adicional (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Solo si hay daños o costos adicionales',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final costo = int.tryParse(value.trim());
                    if (costo == null || costo < 0) {
                      return 'Por favor ingrese un costo válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Sección de imágenes
              const Text(
                'Evidencia fotográfica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puede agregar hasta 3 imágenes como evidencia del estado del espacio',
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
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