import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../models/correspondencia_config_model.dart';
import '../services/correspondencia_service.dart';
import '../services/notification_service.dart';
import '../utils/image_fullscreen_helper.dart';

class ModalEntregaCorrespondencia extends StatefulWidget {
  final String condominioId;
  final CorrespondenciaModel correspondencia;
  final CorrespondenciaConfigModel config;

  const ModalEntregaCorrespondencia({
    super.key,
    required this.condominioId,
    required this.correspondencia,
    required this.config,
  });

  @override
  State<ModalEntregaCorrespondencia> createState() => _ModalEntregaCorrespondenciaState();
}

class _ModalEntregaCorrespondenciaState extends State<ModalEntregaCorrespondencia> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  final NotificationService _notificationService = NotificationService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  
  XFile? _fotoFirma;
  String? _firmaBase64;
  bool _esperandoConfirmacion = false;
  bool _confirmacionRecibida = false;
  bool _entregaRechazada = false;
  bool _isLoading = false;
  bool _escuchaActiva = false;
  Timer? _signatureUpdateTimer;
  StreamSubscription? _notificacionesSubscription;
  
  @override
  void initState() {
    super.initState();
    print('=== DEBUG: Inicializando ModalEntregaCorrespondencia ===');
    print('aceptacionResidente: ${widget.config.aceptacionResidente}');
    print('eleccionResidente: ${widget.config.eleccionResidente}');
    print('solicitarAceptacion: ${widget.correspondencia.solicitarAceptacion}');
    print('tipoFirma: ${widget.config.tipoFirma}');
    print('_confirmacionRecibida inicial: $_confirmacionRecibida');
    print('_esperandoConfirmacion inicial: $_esperandoConfirmacion');
    print('_isLoading inicial: $_isLoading');
    
    // Configurar listener para firma digital si es requerida
    if (widget.config.tipoFirma == 'firmar en la app') {
      _signatureController.addListener(_onSignatureChanged);
    }
    
    // Verificar las condiciones para requerir confirmación del residente
    bool requiereConfirmacion = false;
    
    if (widget.config.aceptacionResidente) {
      // Condición original: aceptacionResidente está activo
      requiereConfirmacion = true;
    } else if (widget.config.eleccionResidente && widget.correspondencia.solicitarAceptacion) {
      // Nueva condición: eleccionResidente está activo Y solicitarAceptacion es true para esta correspondencia
      requiereConfirmacion = true;
    }
    
    if (!requiereConfirmacion) {
      _confirmacionRecibida = true;
      print('No requiere confirmación - _confirmacionRecibida establecido a true');
    } else {
      // Verificar el estado actual de las notificaciones de entrega
      _verificarEstadoNotificacionesEntrega();
      // Iniciar escucha inmediatamente para capturar cambios en tiempo real
      _escucharRespuestaResidente();
    }
  }

  @override
  void dispose() {
    if (widget.config.tipoFirma == 'firmar en la app') {
      _signatureController.removeListener(_onSignatureChanged);
    }
    _signatureUpdateTimer?.cancel();
    _notificacionesSubscription?.cancel();
    _signatureController.dispose();
    super.dispose();
  }
  
  /// Callback para detectar cambios significativos en la firma digital
  /// Usa debounce para evitar interrumpir el proceso de dibujo
  void _onSignatureChanged() {
    // Cancelar el timer anterior si existe
    _signatureUpdateTimer?.cancel();
    
    // Crear un nuevo timer con delay para evitar interrumpir el dibujo
    _signatureUpdateTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Verificar si la firma está vacía o tiene contenido significativo
        bool hasSignificantSignature = false;
        
        if (_signatureController.isNotEmpty) {
          final points = _signatureController.points;
          hasSignificantSignature = points.isNotEmpty && points.length > 5;
        }
        
        // Usar post-frame callback para evitar interrumpir el dibujo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // El estado se actualiza automáticamente al llamar setState
              // Esto hará que _canSave() se reevalúe y el botón se habilite/deshabilite
              // tanto cuando se agrega como cuando se limpia la firma
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('\n=== BUILD WIDGET ===');
    print('Timestamp: ${DateTime.now()}');
    print('_isLoading: $_isLoading');
    final canSave = _canSave();
    print('_canSave(): $canSave');
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Entrega de Correspondencia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card de notificación cuando no se puede guardar o está cargando
                    if (!canSave || _isLoading) ...[
                      _buildValidationCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildCorrespondenciaInfo(),
                    const SizedBox(height: 16),
                    _buildAdjuntosSection(),
                    const SizedBox(height: 16),
                    _buildFirmaSection(),
                    const SizedBox(height: 16),
                    _buildConfirmacionSection(),
                  ],
                ),
              ),
            ),
            
            // Footer con botón de guardar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSave && !_isLoading ? () {
                    print('\n=== BOTÓN GUARDAR PRESIONADO ===');
                    print('_canSave(): $canSave');
                    print('Llamando _guardarEntrega()');
                    _guardarEntrega();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                          'Guardar Entrega',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationCard() {
    if (_isLoading) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Guardando entrega...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor espere mientras se procesa la entrega de correspondencia.',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      );
    }
    
    List<String> errores = [];
    
    // Verificar firma
    if (widget.config.tipoFirma != 'no solicitar firma') {
      if (widget.config.tipoFirma == 'foto' && _fotoFirma == null) {
        errores.add('Se requiere tomar una foto de la firma');
      } else if (widget.config.tipoFirma == 'firmar en la app' && _signatureController.isEmpty) {
        errores.add('Se requiere firma digital en la aplicación');
      }
    }
    
    // Verificar confirmación del residente
    if (widget.config.aceptacionResidente) {
      if (_esperandoConfirmacion) {
        errores.add('Esperando confirmación del residente');
      } else if (!_confirmacionRecibida) {
        if (_puedeReenviarNotificacion()) {
          errores.add('Se requiere enviar notificación y obtener confirmación del residente');
        } else {
          errores.add('Se requiere enviar notificación y obtener confirmación del residente');
        }
      }
    }

    // Verificar confirmación del residente
    if (widget.correspondencia.solicitarAceptacion) {
      if (_esperandoConfirmacion) {
        errores.add('Esperando confirmación del residente');
      } else if (!_confirmacionRecibida) {
        if (_puedeReenviarNotificacion()) {
          errores.add('Se requiere enviar notificación y obtener confirmación del residente');
        } else {
          errores.add('Se requiere enviar notificación y obtener confirmación del residente');
        }
      }
    }
    
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Datos requeridos faltantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...errores.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrespondenciaInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Correspondencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Tipo:', widget.correspondencia.tipoCorrespondencia),
            _buildInfoRow('Entrega:', widget.correspondencia.tipoEntrega),
            _buildInfoRow('Destinatario:', widget.correspondencia.datosEntrega),
            if (widget.correspondencia.viviendaRecepcion != null)
              _buildInfoRow('Recepción:', widget.correspondencia.viviendaRecepcion!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuntosSection() {
    if (widget.correspondencia.adjuntos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
            Text(
              'Imágenes Adjuntas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.correspondencia.adjuntos.length,
                itemBuilder: (context, index) {
                  final key = widget.correspondencia.adjuntos.keys.elementAt(index);
                  final adjunto = widget.correspondencia.adjuntos[key];
                  
                  // Extraer datos Base64 según el tipo de adjunto
                  String base64Data = '';
                  
                  if (adjunto is String) {
                    // Imagen directa en Base64
                    if (adjunto.startsWith('data:image/')) {
                      // Extraer solo la parte Base64 después de la coma
                      final commaIndex = adjunto.indexOf(',');
                      base64Data = commaIndex != -1 ? adjunto.substring(commaIndex + 1) : adjunto;
                    } else {
                      base64Data = adjunto;
                    }
                  } else if (adjunto is Map<String, dynamic>) {
                    // Imagen fragmentada
                    if (adjunto['type'] == 'normal' && adjunto['data'] != null) {
                      String imageData = adjunto['data'];
                      if (imageData.startsWith('data:image/')) {
                        final commaIndex = imageData.indexOf(',');
                        base64Data = commaIndex != -1 ? imageData.substring(commaIndex + 1) : imageData;
                      } else {
                        base64Data = imageData;
                      }
                    } else if (adjunto['type'] == 'internal_fragmented' && adjunto['fragments'] != null) {
                      // Combinar fragmentos
                      List<dynamic> fragments = adjunto['fragments'];
                      base64Data = fragments.join('');
                    }
                  }
                  
                  // Si no se pudo extraer datos válidos, mostrar placeholder
                  if (base64Data.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(Icons.image_not_supported),
                    );
                  }
                  
                  return GestureDetector(
                    onTap: () => ImageFullscreenHelper.showFullscreenImage(context, {'type': 'normal', 'data': base64Data}),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(base64Data),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmaSection() {
    if (widget.config.tipoFirma == 'no solicitar firma') {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firma de Entrega',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.config.tipoFirma == 'foto') ..._buildFotoFirmaSection()
            else if (widget.config.tipoFirma == 'firmar en la app') ..._buildFirmaDigitalSection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFotoFirmaSection() {
    return [
      if (_fotoFirma == null) ...[
        ElevatedButton.icon(
          onPressed: _tomarFotoFirma,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Tomar Foto de Firma'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ] else ...[
        GestureDetector(
          onTap: () async {
            final bytes = await _fotoFirma!.readAsBytes();
            final imageData = base64Encode(bytes);
            _mostrarImagenCompleta(imageData);
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: _fotoFirma!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : Image.file(
                      File(_fotoFirma!.path),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _tomarFotoFirma,
                icon: const Icon(Icons.refresh),
                label: const Text('Cambiar Foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  print('=== setState: Eliminando foto de firma ===');
                  setState(() => _fotoFirma = null);
                  print('_fotoFirma establecido a null');
                },
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildFirmaDigitalSection() {
    return [
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Signature(
          controller: _signatureController,
          backgroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _signatureController.clear();
                // Forzar actualización del estado cuando se limpia la firma
                _signatureUpdateTimer?.cancel();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildConfirmacionSection() {
    print('\n=== _buildConfirmacionSection ===');
    print('aceptacionResidente: ${widget.config.aceptacionResidente}');
    print('eleccionResidente: ${widget.config.eleccionResidente}');
    print('solicitarAceptacion: ${widget.correspondencia.solicitarAceptacion}');
    print('_esperandoConfirmacion: $_esperandoConfirmacion');
    print('_confirmacionRecibida: $_confirmacionRecibida');
    
    // Verificar las condiciones para mostrar la card de confirmación
    bool mostrarConfirmacion = false;
    
    if (widget.config.aceptacionResidente) {
      // Condición original: aceptacionResidente está activo
      mostrarConfirmacion = true;
    } else if (widget.config.eleccionResidente && widget.correspondencia.solicitarAceptacion) {
      // Nueva condición: eleccionResidente está activo Y solicitarAceptacion es true para esta correspondencia
      mostrarConfirmacion = true;
    }
    
    if (!mostrarConfirmacion) {
      print('No requiere confirmación - retornando SizedBox.shrink()');
      return const SizedBox.shrink();
    }

    // Determinar qué estado mostrar
    String estadoUI = '';
    if (!_esperandoConfirmacion && !_confirmacionRecibida && !_entregaRechazada) {
      estadoUI = 'Botón enviar notificación';
    } else if (_esperandoConfirmacion && !_confirmacionRecibida && !_entregaRechazada) {
      estadoUI = 'Esperando confirmación';
    } else if (_confirmacionRecibida) {
      estadoUI = 'Confirmación recibida';
    } else if (_entregaRechazada) {
      estadoUI = 'Entrega rechazada';
    } else {
      estadoUI = 'Estado desconocido';
    }
    print('Estado UI a mostrar: $estadoUI');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmación del Residente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            if (!_esperandoConfirmacion && !_confirmacionRecibida && !_entregaRechazada) ...[
              ElevatedButton.icon(
                onPressed: () {
                  print('=== BOTÓN PRESIONADO: Enviar Notificación ===');
                  _enviarNotificacionResidente();
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Enviar Notificación al Residente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else if (_esperandoConfirmacion && !_confirmacionRecibida && !_entregaRechazada) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Esperando confirmación del residente...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_confirmacionRecibida) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Entrega confirmada por el residente',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    // Mostrar botón de reenvío si la notificación ha expirado
                    if (_puedeReenviarNotificacion()) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'La notificación anterior ha expirado (más de 5 minutos).',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  print('=== BOTÓN PRESIONADO: Reenviar Notificación (Expirada) ===');
                                  _reenviarNotificacionResidente();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Enviar Nueva Notificación'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (_entregaRechazada) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Entrega rechazada por el residente',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'El residente ha rechazado la entrega. Puede intentar entregar nuevamente enviando otra notificación.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print('=== BOTÓN PRESIONADO: Reenviar Notificación ===');
                          _reenviarNotificacionResidente();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reenviar Notificación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarImagenCompleta(String imageData) {
    // Extraer Base64 puro si tiene prefijo
    String base64Data = imageData;
    if (imageData.startsWith('data:image/')) {
      final commaIndex = imageData.indexOf(',');
      base64Data = commaIndex != -1 ? imageData.substring(commaIndex + 1) : imageData;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    base64Decode(base64Data),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade800,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar la imagen',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tomarFotoFirma() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('=== setState: Estableciendo nueva foto de firma ===');
        setState(() {
          _fotoFirma = image;
        });
        print('_fotoFirma establecido con nueva imagen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _enviarNotificacionResidente() async {
    print('\n=== INICIO: _enviarNotificacionResidente ===');
    print('Timestamp: ${DateTime.now()}');
    print('Correspondencia ID: ${widget.correspondencia.id}');
    print('Tipo de entrega: ${widget.correspondencia.tipoEntrega}');
    print('Residente ID Entrega: ${widget.correspondencia.residenteIdEntrega}');
    print('Residente ID Recepción: ${widget.correspondencia.residenteIdRecepcion}');
    print('Condominio ID: ${widget.condominioId}');
    print('Tipo correspondencia: ${widget.correspondencia.tipoCorrespondencia}');
    
    // Determinar el ID del residente al que enviar la notificación
    String? residenteIdNotificacion;
    if (widget.correspondencia.tipoEntrega == 'Residente a un tercero') {
      // Para correspondencias a terceros, notificar al residente que envía (residenteIdRecepcion)
      residenteIdNotificacion = widget.correspondencia.residenteIdRecepcion;
      print('Correspondencia a tercero - usando residenteIdRecepcion: $residenteIdNotificacion');
      if (residenteIdNotificacion == null || residenteIdNotificacion.isEmpty) {
        print('ERROR: residenteIdRecepcion es null o vacío para correspondencia a tercero');
        print('Datos de la correspondencia:');
        print('- ID: ${widget.correspondencia.id}');
        print('- tipoEntrega: ${widget.correspondencia.tipoEntrega}');
        print('- viviendaRecepcion: ${widget.correspondencia.viviendaRecepcion}');
        print('- residenteIdRecepcion: ${widget.correspondencia.residenteIdRecepcion}');
        print('- residenteIdEntrega: ${widget.correspondencia.residenteIdEntrega}');
      }
    } else {
      // Para otros tipos, usar el residente de entrega normal
      residenteIdNotificacion = widget.correspondencia.residenteIdEntrega;
      print('Correspondencia normal - usando residenteIdEntrega: $residenteIdNotificacion');
    }
    
    if (residenteIdNotificacion == null) {
      print('ERROR: No se pudo determinar el residente para la notificación');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede enviar notificación: residente no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('=== setState: Estableciendo _esperandoConfirmacion = true ===');
    setState(() {
      _esperandoConfirmacion = true;
    });
    print('Estado actualizado - _esperandoConfirmacion: $_esperandoConfirmacion');

    try {
      // Generar timestamp para la notificación
      final now = DateTime.now();
      final timestampEnvio = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      
      print('Registrando notificación de entrega con timestamp: $timestampEnvio');
      await _correspondenciaService.registrarNotificacionEntrega(
        widget.condominioId,
        widget.correspondencia.id,
        timestampEnvio,
      );
      
      print('Llamando a _notificationService.enviarNotificacionConfirmacionEntrega...');
      print('Enviando notificación al residente: $residenteIdNotificacion');
      await _notificationService.enviarNotificacionConfirmacionEntrega(
        widget.condominioId,
        residenteIdNotificacion,
        widget.correspondencia.id,
        widget.correspondencia.tipoCorrespondencia,
      );
      print('Notificación enviada exitosamente');
      
      // Escuchar las notificaciones del residente para detectar la respuesta
      print('Iniciando escucha de respuesta del residente: $residenteIdNotificacion');
      _escucharRespuestaResidente();
      print('Escucha iniciada');
      
    } catch (e) {
      print('ERROR al enviar notificación: $e');
      print('Stack trace: ${StackTrace.current}');
      
      print('=== setState: Error - Estableciendo _esperandoConfirmacion = false ===');
      setState(() {
        _esperandoConfirmacion = false;
      });
      print('Estado actualizado después del error - _esperandoConfirmacion: $_esperandoConfirmacion');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar notificación: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
    print('=== FIN: _enviarNotificacionResidente ===\n');
  }

  Future<void> _reenviarNotificacionResidente() async {
    print('\n=== INICIO: _reenviarNotificacionResidente ===');
    print('Timestamp: ${DateTime.now()}');
    print('Correspondencia ID: ${widget.correspondencia.id}');
    print('Tipo de entrega: ${widget.correspondencia.tipoEntrega}');
    print('Residente ID Entrega: ${widget.correspondencia.residenteIdEntrega}');
    print('Residente ID Recepción: ${widget.correspondencia.residenteIdRecepcion}');
    
    // Determinar el ID del residente al que reenviar la notificación
    String? residenteIdNotificacion;
    if (widget.correspondencia.tipoEntrega == 'Residente a un tercero') {
      // Para correspondencias a terceros, notificar al residente que envía (residenteIdRecepcion)
      residenteIdNotificacion = widget.correspondencia.residenteIdRecepcion;
      print('Correspondencia a tercero - usando residenteIdRecepcion: $residenteIdNotificacion');
      if (residenteIdNotificacion == null || residenteIdNotificacion.isEmpty) {
        print('ERROR: residenteIdRecepcion es null o vacío para correspondencia a tercero');
        print('Datos de la correspondencia:');
        print('- ID: ${widget.correspondencia.id}');
        print('- tipoEntrega: ${widget.correspondencia.tipoEntrega}');
        print('- viviendaRecepcion: ${widget.correspondencia.viviendaRecepcion}');
        print('- residenteIdRecepcion: ${widget.correspondencia.residenteIdRecepcion}');
        print('- residenteIdEntrega: ${widget.correspondencia.residenteIdEntrega}');
      }
    } else {
      // Para otros tipos, usar el residente de entrega normal
      residenteIdNotificacion = widget.correspondencia.residenteIdEntrega;
      print('Correspondencia normal - usando residenteIdEntrega: $residenteIdNotificacion');
    }
    
    if (residenteIdNotificacion == null) {
      print('ERROR: No se pudo determinar el residente para la notificación');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede reenviar notificación: residente no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('=== setState: Reiniciando estados para reenvío ===');
    setState(() {
      _esperandoConfirmacion = true;
      _confirmacionRecibida = false;
      _entregaRechazada = false;
    });
    print('Estados reiniciados - _esperandoConfirmacion: $_esperandoConfirmacion');

    try {
      // Generar timestamp para la nueva notificación
      final now = DateTime.now();
      final timestampEnvio = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      
      print('Registrando nueva notificación de entrega con timestamp: $timestampEnvio');
      await _correspondenciaService.registrarNotificacionEntrega(
        widget.condominioId,
        widget.correspondencia.id,
        timestampEnvio,
      );
      
      print('Reenviando notificación de confirmación de entrega...');
      print('Reenviando notificación al residente: $residenteIdNotificacion');
      await _notificationService.enviarNotificacionConfirmacionEntrega(
        widget.condominioId,
        residenteIdNotificacion,
        widget.correspondencia.id,
        widget.correspondencia.tipoCorrespondencia,
      );
      print('Notificación reenviada exitosamente');
      
      // Escuchar las notificaciones del residente para detectar la respuesta
      print('Iniciando escucha de respuesta del residente: $residenteIdNotificacion');
      _escucharRespuestaResidente();
      print('Escucha iniciada');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificación reenviada al residente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('ERROR al reenviar notificación: $e');
      
      print('=== setState: Error - Restaurando estado de rechazo ===');
      setState(() {
        _esperandoConfirmacion = false;
        _confirmacionRecibida = false;
        _entregaRechazada = true;
      });
      print('Estado restaurado después del error');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar notificación: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
    print('=== FIN: _reenviarNotificacionResidente ===\n');
  }
  
  Future<void> _verificarEstadoNotificacionesEntrega() async {
    print('=== DEBUG: Verificando estado actual de notificaciones de entrega (nueva lógica) ===');
    try {
      // Obtener la notificación más reciente
      final notificacionReciente = _obtenerNotificacionMasReciente();
      
      if (notificacionReciente != null) {
        final timestamp = notificacionReciente['timestamp'] as String;
        final notifData = notificacionReciente['data'] as Map<String, dynamic>;
        final respuesta = notifData['respuesta'];
        
        print('Notificación más reciente: $timestamp');
        print('Respuesta: $respuesta');
        
        // Verificar si la notificación más reciente ha expirado
        bool notificacionExpirada = _esNotificacionExpirada(timestamp);
        print('Notificación expirada: $notificacionExpirada');
        
        if (mounted) {
          if (respuesta == 'pendiente') {
            if (notificacionExpirada) {
              // Notificación pendiente pero expirada
              setState(() {
                _esperandoConfirmacion = false;
                _confirmacionRecibida = false;
                _entregaRechazada = false;
              });
              print('Estado actualizado - notificación pendiente expirada');
            } else {
              // Notificación pendiente y activa
              setState(() {
                _esperandoConfirmacion = true;
                _confirmacionRecibida = false;
                _entregaRechazada = false;
              });
              print('Estado actualizado - esperando confirmación');
            }
          } else if (respuesta == 'aceptada' || respuesta == 'rechazada') {
            if (notificacionExpirada) {
              // Respuesta recibida pero expirada - permitir reenvío
              setState(() {
                _esperandoConfirmacion = false;
                _confirmacionRecibida = false;
                _entregaRechazada = false;
              });
              print('Estado actualizado - respuesta expirada, permitir reenvío');
            } else {
              // Respuesta recibida y activa
              setState(() {
                _confirmacionRecibida = respuesta == 'aceptada';
                _entregaRechazada = respuesta == 'rechazada';
                _esperandoConfirmacion = false;
              });
              print('Estado actualizado - respuesta activa: $respuesta');
            }
          }
        }
      } else {
        print('No hay notificaciones de entrega registradas');
        if (mounted) {
          setState(() {
            _esperandoConfirmacion = false;
            _confirmacionRecibida = false;
            _entregaRechazada = false;
          });
        }
      }
    } catch (e) {
      print('Error al verificar notificaciones de entrega: $e');
    }
  }

  void _escucharRespuestaResidente() {
    if (_escuchaActiva) {
      print('=== DEBUG: Escucha ya está activa, omitiendo ===');
      return;
    }
    
    _escuchaActiva = true;
    print('=== DEBUG: Iniciando escucha de notificaciones de entrega ===');
    print('Correspondencia ID: ${widget.correspondencia.id}');
    
    // Escuchar cambios en el campo notificacionEntrega de la correspondencia
    _notificacionesSubscription = _correspondenciaService.escucharNotificacionesEntrega(
      widget.condominioId,
      widget.correspondencia.id,
    ).listen((notificaciones) {
      print('=== DEBUG: Notificaciones de entrega recibidas ===');
      print('Total notificaciones: ${notificaciones.length}');
      
      if (notificaciones.isNotEmpty) {
        // Actualizar el widget.correspondencia con las nuevas notificaciones
        widget.correspondencia.notificacionEntrega.clear();
        widget.correspondencia.notificacionEntrega.addAll(notificaciones);
        
        // Obtener la notificación más reciente usando la nueva función
        final notificacionReciente = _obtenerNotificacionMasReciente();
        
        if (notificacionReciente != null) {
          final timestamp = notificacionReciente['timestamp'] as String;
          final notifData = notificacionReciente['data'] as Map<String, dynamic>;
          final respuesta = notifData['respuesta'];
          final fechaRespuesta = notifData['fechaRespuesta'];
          
          print('=== DEBUG: Notificación más reciente detectada ===');
          print('Timestamp: $timestamp');
          print('Respuesta: $respuesta');
          print('Fecha respuesta: $fechaRespuesta');
          
          // Verificar si la notificación más reciente ha expirado
          bool notificacionExpirada = _esNotificacionExpirada(timestamp);
          print('Notificación expirada: $notificacionExpirada');
          
          if (mounted) {
            if (respuesta == 'pendiente') {
              if (notificacionExpirada) {
                // Notificación pendiente pero expirada
                setState(() {
                  _esperandoConfirmacion = false;
                  _confirmacionRecibida = false;
                  _entregaRechazada = false;
                });
                print('Estado actualizado - notificación pendiente expirada');
              } else {
                // Notificación pendiente y activa
                setState(() {
                  _esperandoConfirmacion = true;
                  _confirmacionRecibida = false;
                  _entregaRechazada = false;
                });
                print('Estado actualizado - esperando confirmación');
              }
            } else if (respuesta == 'aceptada' || respuesta == 'rechazada') {
              if (notificacionExpirada) {
                // Respuesta recibida pero expirada - permitir reenvío
                setState(() {
                  _esperandoConfirmacion = false;
                  _confirmacionRecibida = false;
                  _entregaRechazada = false;
                });
                print('Estado actualizado - respuesta expirada, permitir reenvío');
              } else {
                // Respuesta recibida y activa
                setState(() {
                  _confirmacionRecibida = respuesta == 'aceptada';
                  _entregaRechazada = respuesta == 'rechazada';
                  _esperandoConfirmacion = false;
                });
                print('Estado actualizado - respuesta activa: $respuesta');
                
                // Mostrar mensaje de confirmación solo si es una respuesta nueva y activa
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      respuesta == 'aceptada' 
                        ? 'Entrega aceptada por el residente. Ya puedes guardar la entrega.' 
                        : 'Entrega rechazada por el residente.',
                    ),
                    backgroundColor: respuesta == 'aceptada' ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        } else {
          print('No se pudo obtener la notificación más reciente');
        }
      } else {
        print('No hay notificaciones de entrega');
      }
    }, onError: (error) {
      print('Error en la escucha de notificaciones: $error');
    });
  }

  /// Obtiene la notificación de entrega más reciente
  Map<String, dynamic>? _obtenerNotificacionMasReciente() {
    final notificaciones = widget.correspondencia.notificacionEntrega;
    if (notificaciones.isEmpty) return null;
    
    // Ordenar por timestamp para obtener la más reciente
    final sortedEntries = notificaciones.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    final entryMasReciente = sortedEntries.first;
    return {
      'timestamp': entryMasReciente.key,
      'data': entryMasReciente.value,
    };
  }
  
  /// Verifica si la notificación más reciente ha expirado (más de 5 minutos)
  bool _esNotificacionMasRecienteExpirada() {
    final notificacionReciente = _obtenerNotificacionMasReciente();
    if (notificacionReciente == null) return false;
    
    final timestamp = notificacionReciente['timestamp'] as String;
    return _esNotificacionExpirada(timestamp);
  }
  
  /// Verifica si una notificación ha expirado (más de 5 minutos)
  bool _esNotificacionExpirada(String timestamp) {
    try {
      final notificaciones = widget.correspondencia.notificacionEntrega;
      final notifData = notificaciones[timestamp];
      
      if (notifData == null) return false;
      
      // Si tiene fechaRespuesta, verificar expiración desde esa fecha
      String? fechaParaVerificar;
      if (notifData['fechaRespuesta'] != null) {
        fechaParaVerificar = notifData['fechaRespuesta'];
      } else {
        // Si no tiene respuesta, verificar desde fechaEnvio
        fechaParaVerificar = notifData['fechaEnvio'];
      }
      
      if (fechaParaVerificar == null) return false;
      
      // Parsear el timestamp en formato: DD-MM-YYYY-HH-MM-SS
      final parts = fechaParaVerificar.split('-');
      if (parts.length != 6) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final hour = int.parse(parts[3]);
      final minute = int.parse(parts[4]);
      final second = int.parse(parts[5]);
      
      final fechaReferencia = DateTime(year, month, day, hour, minute, second);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaReferencia);
      
      // Considerar expirada si han pasado más de 5 minutos
      bool expirada = diferencia.inMinutes > 5;
      print('Verificando expiración para $timestamp:');
      print('  - Fecha referencia: $fechaParaVerificar');
      print('  - Diferencia en minutos: ${diferencia.inMinutes}');
      print('  - Expirada: $expirada');
      
      return expirada;
    } catch (e) {
      print('Error al parsear timestamp $timestamp: $e');
      return false;
    }
  }
  
  /// Verifica si se puede reenviar una notificación basándose en la más reciente
  bool _puedeReenviarNotificacion() {
    // Verificar si se requiere confirmación del residente
    bool requiereConfirmacion = false;
    
    if (widget.config.aceptacionResidente) {
      // Condición original: aceptacionResidente está activo
      requiereConfirmacion = true;
    } else if (widget.config.eleccionResidente && widget.correspondencia.solicitarAceptacion) {
      // Nueva condición: eleccionResidente está activo Y solicitarAceptacion es true para esta correspondencia
      requiereConfirmacion = true;
    }
    
    if (!requiereConfirmacion) return false;
    
    final notificaciones = widget.correspondencia.notificacionEntrega;
    if (notificaciones.isEmpty) return true; // No hay notificaciones, se puede enviar
    
    // Obtener la notificación más reciente
    final notificacionReciente = _obtenerNotificacionMasReciente();
    if (notificacionReciente == null) return true;
    
    final timestamp = notificacionReciente['timestamp'] as String;
    final notifData = notificacionReciente['data'] as Map<String, dynamic>;
    final respuesta = notifData['respuesta'];
    
    // Si la notificación más reciente ha expirado, se puede reenviar
    bool notificacionExpirada = _esNotificacionMasRecienteExpirada();
    
    // Se puede reenviar si:
    // 1. La notificación más reciente ha expirado (más de 5 minutos)
    // 2. Independientemente de si fue aceptada, rechazada o está pendiente
    bool puedeReenviar = notificacionExpirada;
    
    print('_puedeReenviarNotificacion (nueva lógica):');
    print('  - Timestamp más reciente: $timestamp');
    print('  - Respuesta: $respuesta');
    print('  - Expirada: $notificacionExpirada');
    print('  - Puede reenviar: $puedeReenviar');
    
    return puedeReenviar;
  }

  bool _canSave() {
    // Debug: Imprimir estado actual
    print('=== DEBUG _canSave ===');
    print('tipoFirma: ${widget.config.tipoFirma}');
    print('_fotoFirma: ${_fotoFirma != null}');
    print('_signatureController.isEmpty: ${_signatureController.isEmpty}');
    print('aceptacionResidente: ${widget.config.aceptacionResidente}');
    print('eleccionResidente: ${widget.config.eleccionResidente}');
    print('solicitarAceptacion: ${widget.correspondencia.solicitarAceptacion}');
    print('_confirmacionRecibida: $_confirmacionRecibida');
    print('_esperandoConfirmacion: $_esperandoConfirmacion');
    print('_isLoading: $_isLoading');
    
    // No permitir guardar si está cargando
    if (_isLoading) {
      print('Bloqueado por: está cargando');
      return false;
    }
    
    // Verificar si se requiere firma y está presente
    bool firmaRequerida = widget.config.tipoFirma != 'no solicitar firma';
    bool firmaCompleta = false;
    
    if (firmaRequerida) {
      if (widget.config.tipoFirma == 'foto') {
        firmaCompleta = _fotoFirma != null;
        if (!firmaCompleta) {
          print('Bloqueado por: falta foto de firma');
          return false;
        }
      } else if (widget.config.tipoFirma == 'firmar en la app') {
        firmaCompleta = !_signatureController.isEmpty;
        if (!firmaCompleta) {
          print('Bloqueado por: falta firma digital');
          return false;
        }
      }
    }
    
    // Verificar si se requiere confirmación del residente y está presente
    bool requiereConfirmacion = false;
    
    if (widget.config.aceptacionResidente) {
      // Condición original: aceptacionResidente está activo
      requiereConfirmacion = true;
    } else if (widget.config.eleccionResidente && widget.correspondencia.solicitarAceptacion) {
      // Nueva condición: eleccionResidente está activo Y solicitarAceptacion es true para esta correspondencia
      requiereConfirmacion = true;
    }
    
    if (requiereConfirmacion) {
      if (_esperandoConfirmacion) {
        print('Bloqueado por: esperando confirmación del residente');
        return false;
      }
      if (!_confirmacionRecibida) {
        print('Bloqueado por: falta confirmación del residente');
        return false;
      }
      // Si la entrega fue rechazada, no permitir guardar
      if (_entregaRechazada) {
        print('Bloqueado por: entrega rechazada por el residente');
        return false;
      }
    }
    
    print('Validación exitosa - Puede guardar: true');
    print('  - Firma requerida: $firmaRequerida, completa: ${firmaRequerida ? firmaCompleta : 'N/A'}');
    print('  - Confirmación requerida: $requiereConfirmacion, recibida: ${requiereConfirmacion ? _confirmacionRecibida : 'N/A'}');
    return true;
  }

  Future<void> _guardarEntrega() async {
    print('\n=== INICIO: _guardarEntrega ===');
    print('Timestamp: ${DateTime.now()}');
    print('Correspondencia ID: ${widget.correspondencia.id}');
    print('Condominio ID: ${widget.condominioId}');
    print('Tipo firma: ${widget.config.tipoFirma}');
    print('Aceptación residente requerida: ${widget.config.aceptacionResidente}');
    print('Elección residente activa: ${widget.config.eleccionResidente}');
    print('Solicitar aceptación (correspondencia): ${widget.correspondencia.solicitarAceptacion}');
    print('Estado actual:');
    print('  - _confirmacionRecibida: $_confirmacionRecibida');
    print('  - _esperandoConfirmacion: $_esperandoConfirmacion');
    print('  - _isLoading: $_isLoading');
    print('  - _fotoFirma != null: ${_fotoFirma != null}');
    print('  - _signatureController.isEmpty: ${_signatureController.isEmpty}');
    
    // Verificar condiciones antes de proceder
    if (!_canSave()) {
      print('ERROR: No se puede guardar según _canSave()');
      _mostrarError('No se puede guardar la entrega. Verifique que todos los campos requeridos estén completos.');
      return;
    }
    
    // Validaciones adicionales de seguridad
    if (widget.correspondencia.id.isEmpty) {
      print('ERROR: ID de correspondencia vacío');
      _mostrarError('Error: ID de correspondencia no válido');
      return;
    }
    
    if (widget.condominioId.isEmpty) {
      print('ERROR: ID de condominio vacío');
      _mostrarError('Error: ID de condominio no válido');
      return;
    }
    
    print('=== setState: Estableciendo _isLoading = true ===');
    setState(() {
      _isLoading = true;
    });
    print('Estado actualizado - _isLoading: $_isLoading');

    try {
      String? firmaData;
      print('Procesando firma...');
      
      // Procesar firma según el tipo configurado
      if (widget.config.tipoFirma == 'foto' && _fotoFirma != null) {
        print('Procesando foto de firma...');
        try {
          final bytes = await _fotoFirma!.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('La foto de firma está vacía');
          }
          firmaData = base64Encode(bytes);
          print('Foto de firma procesada - tamaño: ${firmaData.length} caracteres');
          
          // Validar que la codificación sea correcta
          if (firmaData.length < 100) {
            throw Exception('La foto de firma parece estar corrupta');
          }
        } catch (e) {
          print('ERROR al procesar foto de firma: $e');
          throw Exception('Error al procesar la foto de firma: $e');
        }
      } else if (widget.config.tipoFirma == 'firmar en la app' && !_signatureController.isEmpty) {
        print('Procesando firma digital...');
        try {
          final signature = await _signatureController.toPngBytes();
          if (signature == null || signature.isEmpty) {
            throw Exception('No se pudo obtener la firma digital');
          }
          firmaData = base64Encode(signature);
          print('Firma digital procesada - tamaño: ${firmaData.length} caracteres');
          
          // Validar que la codificación sea correcta
          if (firmaData.length < 100) {
            throw Exception('La firma digital parece estar corrupta');
          }
        } catch (e) {
          print('ERROR al procesar firma digital: $e');
          throw Exception('Error al procesar la firma digital: $e');
        }
      } else if (widget.config.tipoFirma != 'no solicitar firma') {
        print('ERROR: Se requiere firma pero no está disponible');
        throw Exception('Se requiere firma pero no está disponible');
      } else {
        print('No se requiere firma');
      }
      
      // Validar confirmación del residente si es requerida
      bool requiereConfirmacion = false;
      
      if (widget.config.aceptacionResidente) {
        // Condición original: aceptacionResidente está activo
        requiereConfirmacion = true;
      } else if (widget.config.eleccionResidente && widget.correspondencia.solicitarAceptacion) {
        // Nueva condición: eleccionResidente está activo Y solicitarAceptacion es true para esta correspondencia
        requiereConfirmacion = true;
      }
      
      if (requiereConfirmacion && !_confirmacionRecibida) {
        print('ERROR: Se requiere confirmación del residente pero no se ha recibido');
        throw Exception('Se requiere confirmación del residente');
      }
      
      // Marcar como entregada
      final fechaHoraEntrega = DateTime.now().toIso8601String();
      print('Marcando como entregada...');
      print('Fecha/hora entrega: $fechaHoraEntrega');
      print('Firma data disponible: ${firmaData != null}');
      print('Tamaño firma: ${firmaData?.length ?? 0} caracteres');
      
      // Intentar marcar como entregada (actualizar documento existente)
       try {
         await _correspondenciaService.marcarComoEntregada(
           widget.condominioId,
           widget.correspondencia.id,
           fechaHoraEntrega,
           firmaData,
         );
         print('Correspondencia actualizada exitosamente');
       } catch (updateError) {
         print('Error al actualizar correspondencia: $updateError');
         
         // Si el error es porque el documento no existe, mostrar error específico
         if (updateError.toString().contains('not-found') || updateError.toString().contains('No document to update')) {
           _mostrarErrorDetallado(
             'Error de Sincronización',
             'El documento de correspondencia no existe en la base de datos. Esto puede ocurrir si la correspondencia fue eliminada o hay un problema de sincronización.',
             solucion: 'Cierre este modal, actualice la lista de correspondencias y vuelva a intentar. Si el problema persiste, contacte al administrador del sistema.',
           );
           return; // Salir sin lanzar excepción para evitar el catch general
         } else {
           // Re-lanzar otros errores para que sean manejados por el catch general
           throw updateError;
         }
       }
      print('Correspondencia marcada como entregada exitosamente');
      
      // Verificar que se guardó correctamente
      await _verificarGuardado();
      
      if (mounted) {
        print('Cerrando modal y mostrando mensaje de éxito');
        
        // Resetear estado de notificación antes de cerrar
        setState(() {
          _esperandoConfirmacion = false;
          _confirmacionRecibida = false;
          _entregaRechazada = false;
        });
        
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correspondencia entregada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('ERROR al guardar entrega: $e');
      print('Stack trace: ${StackTrace.current}');
      _mostrarError('Error al guardar entrega: ${e.toString()}');
    } finally {
      if (mounted) {
        print('=== setState: Estableciendo _isLoading = false (finally) ===');
        setState(() {
          _isLoading = false;
        });
        print('Estado final - _isLoading: $_isLoading');
      }
    }
    print('=== FIN: _guardarEntrega ===\n');
  }
  
  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
  
  void _mostrarErrorDetallado(String titulo, String mensaje, {String? solucion}) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(titulo),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              if (solucion != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Solución sugerida:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(solucion),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            if (solucion != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Cerrar el modal también
                },
                child: const Text('Entendido'),
              ),
          ],
        ),
      );
    }
  }
  
  Future<void> _verificarGuardado() async {
    try {
      print('Verificando que la correspondencia se guardó correctamente...');
      final correspondenciaActualizada = await _correspondenciaService.getCorrespondenciaById(
        widget.condominioId,
        widget.correspondencia.id,
      );
      
      if (correspondenciaActualizada == null) {
        throw Exception('No se pudo verificar el guardado: correspondencia no encontrada');
      }
      
      if (correspondenciaActualizada.fechaHoraEntrega == null) {
        throw Exception('Error: la fecha de entrega no se guardó correctamente');
      }
      
      // Verificar firma si era requerida
      if (widget.config.tipoFirma != 'no solicitar firma') {
        if (correspondenciaActualizada.firma == null || correspondenciaActualizada.firma!.isEmpty) {
          throw Exception('Error: la firma no se guardó correctamente');
        }
        print('Firma verificada - tamaño: ${correspondenciaActualizada.firma!.length} caracteres');
      }
      
      print('Verificación exitosa: correspondencia guardada correctamente');
    } catch (e) {
      print('ERROR en verificación: $e');
      throw Exception('Error al verificar el guardado: $e');
    }
  }
}