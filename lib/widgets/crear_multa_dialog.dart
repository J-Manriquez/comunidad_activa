import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/multa_service.dart';
import '../models/multa_model.dart';
import '../utils/storage_service.dart';
import '../utils/image_display_widget.dart';

class CrearMultaScreen extends StatefulWidget {
  final String condominioId;
  final String tipoVivienda;
  final String numeroVivienda;
  final String? etiquetaEdificio;
  final String? numeroDepartamento;

  const CrearMultaScreen({
    Key? key,
    required this.condominioId,
    required this.tipoVivienda,
    required this.numeroVivienda,
    this.etiquetaEdificio,
    this.numeroDepartamento,
  }) : super(key: key);

  @override
  _CrearMultaScreenState createState() => _CrearMultaScreenState();
}

class _CrearMultaScreenState extends State<CrearMultaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contenidoController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final _valorPersonalizadoController = TextEditingController();
  final _unidadPersonalizadaController = TextEditingController();

  final MultaService _multaService = MultaService();
  late final StorageService _storageService;

  List<GestionMulta> _tiposMultas = [];
  String? _tipoSeleccionado;
  int? _valorSeleccionado;
  String? _unidadSeleccionada;
  bool _isLoading = false;
  bool _usarTipoPersonalizado = false;
  bool _usarValorPersonalizado = false;
  bool _usarUnidadPersonalizada = false;

  // Variables para manejo de imágenes fragmentadas
  Map<String, dynamic>? _imagen1Data;
  Map<String, dynamic>? _imagen2Data;
  Map<String, dynamic>? _imagen3Data;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Crear Nueva Multa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información de la vivienda
              _buildViviendaCard(),
              const SizedBox(height: 24),

              // Sección tipo de multa
              _buildTipoMultaCard(),
              const SizedBox(height: 24),
              
              // Sección valor y unidad
              _buildValorUnidadCard(),
              const SizedBox(height: 24),
              
              // Sección descripción
              _buildDescripcionCard(),
              const SizedBox(height: 24),
              
              // Sección imágenes
              _buildImagenesCard(),
              const SizedBox(height: 32),
              
              // Botón crear multa
              _buildCrearMultaButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViviendaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Información de la Vivienda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.apartment, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.tipoVivienda} ${widget.numeroVivienda}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (widget.etiquetaEdificio != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.business, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Edificio ${widget.etiquetaEdificio} - Depto ${widget.numeroDepartamento}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoMultaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Tipo de Multa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Seleccione el tipo de multa',
                prefixIcon: Icon(Icons.category, color: Colors.red[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: [
                ..._tiposMultas.map(
                  (tipo) => DropdownMenuItem(
                    value: tipo.tipoMulta,
                    child: Text(tipo.tipoMulta),
                  ),
                ),
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
                      orElse: () => GestionMulta(
                        id: '',
                        tipoMulta: '',
                        valor: 0,
                        unidadMedida: '',
                      ),
                    );
                    _valorSeleccionado = tipoEncontrado.valor;
                    _unidadSeleccionada = tipoEncontrado.unidadMedida;
                    _usarValorPersonalizado = false;
                    _usarUnidadPersonalizada = false;
                  } else if (value == 'otro') {
                    _valorSeleccionado = null;
                    _unidadSeleccionada = null;
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoPersonalizadoController,
                decoration: InputDecoration(
                  labelText: 'Tipo de multa personalizado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.edit, color: Colors.red[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (_usarTipoPersonalizado && (value == null || value.isEmpty)) {
                    return 'Por favor ingrese el tipo de multa';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValorUnidadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Valor y Unidad de Medida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_usarValorPersonalizado && _valorSeleccionado != null && !_usarTipoPersonalizado)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            _valorSeleccionado.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _valorPersonalizadoController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Ingrese el valor',
                            prefixIcon: Icon(Icons.monetization_on, color: Colors.red[600]),
                            filled: true,
                            fillColor: Colors.grey[50],
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
                          child: Text(
                            _usarValorPersonalizado
                                ? 'Usar valor predefinido'
                                : 'Usar valor personalizado',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unidad:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_usarUnidadPersonalizada && _unidadSeleccionada != null && !_usarTipoPersonalizado)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            _unidadSeleccionada!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _unidadPersonalizadaController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Ingrese la unidad',
                            prefixIcon: Icon(Icons.straighten, color: Colors.red[600]),
                            filled: true,
                            fillColor: Colors.grey[50],
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
                          child: Text(
                            _usarUnidadPersonalizada
                                ? 'Usar unidad predefinida'
                                : 'Usar unidad personalizada',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Descripción de la Multa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Describa detalladamente la causa de la multa...',
                prefixIcon: Icon(Icons.edit_note, color: Colors.red[600]),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la descripción de la multa';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Imágenes de Evidencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Puede agregar hasta 3 imágenes como evidencia de la multa',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildImagenesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrearMultaButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _crearMulta,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_task, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Crear Multa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectImage(int imageNumber) async {
    setState(() => _isUploadingImage = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
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

        // Preparar additionalData con imágenes fragmentadas
        Map<String, dynamic> additionalData = {};
        if (_imagen1Data != null) additionalData['imagen1'] = _imagen1Data!;
        if (_imagen2Data != null) additionalData['imagen2'] = _imagen2Data!;
        if (_imagen3Data != null) additionalData['imagen3'] = _imagen3Data!;

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
          imagenesBase64: additionalData,
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Multa creada exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear multa: $e')));
      } finally {
        setState(() => _isLoading = false);
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
          ? const Center(child: CircularProgressIndicator())
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
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
