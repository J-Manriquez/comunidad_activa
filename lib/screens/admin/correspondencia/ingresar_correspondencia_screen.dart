import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../services/correspondencia_service.dart';
import '../../../widgets/seleccion_vivienda_residente_modal.dart';
import 'package:intl/intl.dart';

class IngresarCorrespondenciaScreen extends StatefulWidget {
  final String condominioId;

  const IngresarCorrespondenciaScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<IngresarCorrespondenciaScreen> createState() =>
      _IngresarCorrespondenciaScreenState();
}

class _IngresarCorrespondenciaScreenState
    extends State<IngresarCorrespondenciaScreen> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _otroTipoController = TextEditingController();
  final TextEditingController _datosEntregaTerceroController = TextEditingController();
  final TextEditingController _mensajeAdicionalController = TextEditingController();
  
  CorrespondenciaConfigModel? _config;
  bool _isLoading = true;
  bool _isSaving = false;

  // Campos del formulario
  String _tipoCorrespondencia = 'paquete';
  String _tipoEntrega = 'A un residente';
  String _datosEntrega = '';
  String? _residenteIdEntrega;
  String? _residenteNombreEntrega;
  String? _viviendaRecepcion;
  String? _residenteIdRecepcion;
  String? _residenteNombreRecepcion;
  List<XFile> _imagenes = [];
  String? _firma;

  // Opciones
  final List<String> _tiposCorrespondencia = [
    'paquete',
    'carta',
    'boleta',
    'otro',
  ];

  final List<String> _tiposEntrega = [
    'A un residente',
    'Entre residentes',
    'Residente a un tercero',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _otroTipoController.dispose();
    _datosEntregaTerceroController.dispose();
    _mensajeAdicionalController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _correspondenciaService.getCorrespondenciaConfig(
        widget.condominioId,
      );
      
      if (mounted) {
        setState(() {
          _config = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error al cargar configuración: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    if (_imagenes.length >= 3) {
      _showErrorSnackBar('Máximo 3 imágenes permitidas');
      return;
    }

    // Mostrar opciones de cámara o galería
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imagenes.add(image);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagenes.removeAt(index);
    });
  }

  Future<String> _fileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  void _mostrarSeleccionVivienda({
    required String titulo,
    required bool esRecepcion,
  }) {
    showDialog(
      context: context,
      builder: (context) => SeleccionViviendaResidenteModal(
        condominioId: widget.condominioId,
        titulo: titulo,
        onSeleccion: (vivienda, residenteId, residenteNombre) {
          setState(() {
            if (esRecepcion) {
              _viviendaRecepcion = vivienda;
              _residenteIdRecepcion = residenteId;
              _residenteNombreRecepcion = residenteNombre;
            } else {
              _datosEntrega = vivienda;
              _residenteIdEntrega = residenteId;
              _residenteNombreEntrega = residenteNombre;
            }
          });
        },
      ),
    );
  }

  bool _validarFormulario() {
    if (_tipoCorrespondencia == 'otro' && _otroTipoController.text.trim().isEmpty) {
      _showErrorSnackBar('Debe especificar el tipo de correspondencia');
      return false;
    }

    if (_config?.fotoObligatoria == true && _imagenes.isEmpty) {
      _showErrorSnackBar('Debe agregar al menos una foto');
      return false;
    }

    switch (_tipoEntrega) {
      case 'A un residente':
        if (_datosEntrega.isEmpty || _residenteIdEntrega == null) {
          _showErrorSnackBar('Debe seleccionar la vivienda y residente de entrega');
          return false;
        }
        break;
      case 'Entre residentes':
        if (_viviendaRecepcion == null || _residenteIdRecepcion == null) {
          _showErrorSnackBar('Debe seleccionar la vivienda y residente de recepción');
          return false;
        }
        if (_datosEntrega.isEmpty || _residenteIdEntrega == null) {
          _showErrorSnackBar('Debe seleccionar la vivienda y residente de entrega');
          return false;
        }
        break;
      case 'Residente a un tercero':
        if (_viviendaRecepcion == null || _residenteIdRecepcion == null) {
          _showErrorSnackBar('Debe seleccionar la vivienda y residente de recepción');
          return false;
        }
        if (_datosEntregaTerceroController.text.trim().isEmpty) {
          _showErrorSnackBar('Debe ingresar los datos del tercero');
          return false;
        }
        break;
    }

    return true;
  }

  Future<void> _guardarCorrespondencia() async {
    if (!_validarFormulario()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Convertir imágenes a base64
      Map<String, dynamic> adjuntos = {};
      for (int i = 0; i < _imagenes.length; i++) {
        final base64Image = await _fileToBase64(_imagenes[i]);
        adjuntos['imagen_$i'] = base64Image;
      }

      // Crear el documento de correspondencia
      final now = DateTime.now();
      final fechaHora = DateFormat('dd-MM-yyyy HH:mm:ss').format(now);
      final documentId = DateFormat('dd-MM-yyyy-HH-mm-ss').format(now);

      // Preparar información adicional si hay mensaje
      List<Map<String, dynamic>>? infAdicional;
      if (_mensajeAdicionalController.text.trim().isNotEmpty) {
        infAdicional = [
          {
            'mensaje': _mensajeAdicionalController.text.trim(),
            'fechaHora': fechaHora,
            'usuarioId': 'admin', // TODO: Obtener el ID del usuario actual
          }
        ];
      }

      final correspondencia = CorrespondenciaModel(
        id: documentId,
        tipoEntrega: _tipoEntrega,
        tipoCorrespondencia: _tipoCorrespondencia == 'otro' 
            ? _otroTipoController.text.trim() 
            : _tipoCorrespondencia,
        fechaHoraRecepcion: fechaHora,
        viviendaRecepcion: _viviendaRecepcion,
        residenteIdRecepcion: _residenteIdRecepcion,
        datosEntrega: _tipoEntrega == 'Residente a un tercero' 
            ? _datosEntregaTerceroController.text.trim() 
            : _datosEntrega,
        residenteIdEntrega: _residenteIdEntrega,
        adjuntos: adjuntos,
        infAdicional: infAdicional,
      );

      await _correspondenciaService.createCorrespondencia(
        widget.condominioId,
        correspondencia,
      );

      if (mounted) {
        _showSuccessSnackBar('Correspondencia registrada exitosamente');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al guardar correspondencia: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTipoCorrespondenciaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Correspondencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoCorrespondencia,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _tiposCorrespondencia.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _tipoCorrespondencia = newValue;
                  });
                }
              },
            ),
            if (_tipoCorrespondencia == 'otro') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otroTipoController,
                decoration: InputDecoration(
                  labelText: 'Especificar tipo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipoEntregaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoEntrega,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _tiposEntrega.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _tipoEntrega = newValue;
                    // Limpiar campos cuando cambia el tipo
                    _datosEntrega = '';
                    _residenteIdEntrega = null;
                    _residenteNombreEntrega = null;
                    _viviendaRecepcion = null;
                    _residenteIdRecepcion = null;
                    _residenteNombreRecepcion = null;
                    _datosEntregaTerceroController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamposSegunTipoEntrega() {
    switch (_tipoEntrega) {
      case 'A un residente':
        return _buildDatosEntregaCard();
      case 'Entre residentes':
        return Column(
          children: [
            _buildViviendaRecepcionCard(),
            _buildDatosEntregaCard(),
          ],
        );
      case 'Residente a un tercero':
        return Column(
          children: [
            _buildViviendaRecepcionCard(),
            _buildDatosTerceroCard(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildViviendaRecepcionCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vivienda de Recepción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _mostrarSeleccionVivienda(
                titulo: 'Seleccionar Vivienda de Recepción',
                esRecepcion: true,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _viviendaRecepcion != null && _residenteNombreRecepcion != null
                      ? '$_viviendaRecepcion - $_residenteNombreRecepcion'
                      : 'Seleccionar vivienda y residente',
                  style: TextStyle(
                    color: _viviendaRecepcion != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosEntregaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de Entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _mostrarSeleccionVivienda(
                titulo: 'Seleccionar Vivienda de Entrega',
                esRecepcion: false,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _datosEntrega.isNotEmpty && _residenteNombreEntrega != null
                      ? '$_datosEntrega - $_residenteNombreEntrega'
                      : 'Seleccionar vivienda y residente',
                  style: TextStyle(
                    color: _datosEntrega.isNotEmpty
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosTerceroCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Tercero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _datosEntregaTerceroController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ingrese los datos del tercero (nombre, teléfono, etc.)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMensajeAdicionalCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mensaje Adicional (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mensajeAdicionalController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ingrese un mensaje adicional si es necesario...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjuntosCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Adjuntos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_config?.fotoObligatoria == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Obligatorio',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_imagenes.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagenes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _imagenes[index].readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_imagenes[index].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_imagenes.length < 3)
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _imagenes.isEmpty ? 'Agregar Foto' : 'Agregar Otra Foto',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            if (_imagenes.length >= 3)
              Text(
                'Máximo 3 imágenes',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ingresar Correspondencia',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? const Center(
                  child: Text('Error al cargar la configuración'),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildTipoCorrespondenciaCard(),
                      _buildTipoEntregaCard(),
                      _buildCamposSegunTipoEntrega(),
                      _buildMensajeAdicionalCard(),
                      _buildAdjuntosCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      bottomNavigationBar: !_isLoading && _config != null
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarCorrespondencia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
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
                        'Guardar Correspondencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )
          : null,
    );
  }
}