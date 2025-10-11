import 'dart:convert';
import 'package:comunidad_activa/utils/image_display_widget.dart';
import 'package:comunidad_activa/widgets/image_carousel_widget.dart';
import 'package:comunidad_activa/widgets/modal_entrega_correspondencia.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../models/user_model.dart';
import '../../../services/correspondencia_service.dart';
import '../../../utils/image_fullscreen_helper.dart';
import '../../../widgets/image_carousel_widget.dart';

// CorrespondenciaModel está definido en correspondencia_config_model.dart
// por lo que ya está importado

class CorrespondenciasActivasScreen extends StatefulWidget {
  final String condominioId;
  final UserModel currentUser;

  const CorrespondenciasActivasScreen({
    super.key,
    required this.condominioId,
    required this.currentUser,
  });

  @override
  State<CorrespondenciasActivasScreen> createState() =>
      _CorrespondenciasActivasScreenState();
}

class _CorrespondenciasActivasScreenState
    extends State<CorrespondenciasActivasScreen> {
  final CorrespondenciaService _correspondenciaService =
      CorrespondenciaService();
  CorrespondenciaConfigModel? _config;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await _correspondenciaService.getCorrespondenciaConfig(
        widget.condominioId,
      );
      if (mounted) {
        setState(() {
          _config = config;
        });
      }
    } catch (e) {
      print('Error al cargar configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondencias Activas'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CorrespondenciaModel>>(
        stream: _correspondenciaService.getCorrespondencias(
          widget.condominioId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar correspondencias',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final correspondencias = snapshot.data ?? [];

          // Filtrar solo correspondencias activas (sin fecha de entrega)
          final correspondenciasActivas = correspondencias
              .where(
                (c) =>
                    c.fechaHoraEntrega == null || c.fechaHoraEntrega!.isEmpty,
              )
              .toList();

          if (correspondenciasActivas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay correspondencias activas',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las correspondencias aparecerán aquí cuando se registren',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: correspondenciasActivas.length,
            itemBuilder: (context, index) {
              final correspondencia = correspondenciasActivas[index];
              return _buildCorrespondenciaCard(correspondencia);
            },
          );
        },
      ),
    );
  }

  Widget _buildCorrespondenciaCard(CorrespondenciaModel correspondencia) {
    final fechaRecepcion = DateTime.tryParse(
      correspondencia.fechaHoraRecepcion,
    );
    final fechaFormateada = fechaRecepcion != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRecepcion)
        : correspondencia.fechaHoraRecepcion;
    final hasImages = _tieneImagenes(correspondencia);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => _mostrarDetallesCorrespondencia(correspondencia),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carrusel de imágenes a la izquierda (si hay imágenes)
              if (hasImages) ...[
                _buildImagenesCorrespondencia(correspondencia)!,
                const SizedBox(width: 16),
              ],
              // Contenido de la card a la derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con tipo y fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTipoColor(
                              correspondencia.tipoCorrespondencia,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            correspondencia.tipoCorrespondencia.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          fechaFormateada,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tipo de entrega
                    Row(
                      children: [
                        Icon(
                          _getTipoEntregaIcon(correspondencia.tipoEntrega),
                          size: 20,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          correspondencia.tipoEntrega,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Datos de entrega
                    Text(
                      'Entrega: ${correspondencia.datosEntrega}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),

                    // Vivienda de recepción (si aplica)
                    if (correspondencia.viviendaRecepcion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Recepción: ${correspondencia.viviendaRecepcion}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Adjuntos
                    if (correspondencia.adjuntos != null &&
                        correspondencia.adjuntos!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${correspondencia.adjuntos!.length} archivo(s) adjunto(s)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  Widget? _buildImagenesCorrespondencia(CorrespondenciaModel correspondencia) {
    if (!_tieneImagenes(correspondencia)) return null;

    print(
      'DEBUG: Construyendo imágenes para correspondencia ${correspondencia.id}',
    );
    print(
      'DEBUG: Adjuntos disponibles: ${correspondencia.adjuntos.keys.toList()}',
    );

    List<Map<String, dynamic>> imagenesData = [];

    // Procesar adjuntos de correspondencia
    correspondencia.adjuntos.forEach((key, value) {
      print('DEBUG: Procesando adjunto $key');

      if (value is String) {
        // Imagen normal en Base64
        print('DEBUG: Imagen normal encontrada');
        imagenesData.add({'type': 'normal', 'data': value});
      } else if (value is Map<String, dynamic>) {
        print('DEBUG: Imagen fragmentada encontrada: ${value.keys.toList()}');

        // Verificar si es fragmentación interna
        if (value.containsKey('type') &&
            value['type'] == 'internal_fragmented') {
          print('DEBUG: Procesando imagen fragmentada interna');
          imagenesData.add(value);
        }
        // Verificar si es fragmentación externa
        else if (value.containsKey('type') &&
            value['type'] == 'external_fragmented') {
          print('DEBUG: Procesando imagen fragmentada externa');
          imagenesData.add(value);
        }
        // Fallback para estructuras de mapa desconocidas
        else {
          print(
            'DEBUG: Estructura de mapa desconocida, intentando extraer base64',
          );
          final possibleBase64 = value.values.firstWhere(
            (v) => v is String && v.length > 100,
            orElse: () => null,
          );
          if (possibleBase64 != null) {
            imagenesData.add({'type': 'normal', 'data': possibleBase64});
            print('DEBUG: Base64 extraído de estructura desconocida');
          }
        }
      }
    });

    print('DEBUG: Total de imágenes procesadas: ${imagenesData.length}');

    if (imagenesData.isEmpty) return null;

    return Container(
      height: 100,
      width: 120,
      child: ImageCarouselWidget(
        images: imagenesData,
        height: 100,
        width: 120,
        onImageTap: (imageData) {
          ImageFullscreenHelper.showFullscreenImage(context, imageData);
        },
      ),
    );
  }

  bool _tieneImagenes(CorrespondenciaModel correspondencia) {
    return correspondencia.adjuntos.isNotEmpty;
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'paquete':
        return Colors.blue.shade600;
      case 'carta':
        return Colors.green.shade600;
      case 'boleta':
        return Colors.orange.shade600;
      default:
        return Colors.purple.shade600;
    }
  }

  IconData _getTipoEntregaIcon(String tipoEntrega) {
    switch (tipoEntrega) {
      case 'A un residente':
        return Icons.person;
      case 'Entre residentes':
        return Icons.people;
      case 'Residente a un tercero':
        return Icons.person_outline;
      default:
        return Icons.mail;
    }
  }

  void _mostrarDetallesCorrespondencia(CorrespondenciaModel correspondencia) {
    showDialog(
      context: context,
      builder: (context) => _DetalleCorrespondenciaModal(
        condominioId: widget.condominioId,
        correspondencia: correspondencia,
        config: _config,
        currentUser: widget.currentUser,
        onCorrespondenciaActualizada: () {
          // Trigger rebuild to refresh the list
          setState(() {});
        },
      ),
    );
  }

  Future<void> _abrirModalEntrega(CorrespondenciaModel correspondencia) async {
    if (_config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando configuración...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEntregaCorrespondencia(
        condominioId: widget.condominioId,
        correspondencia: correspondencia,
        config: _config!,
      ),
    );

    if (resultado == true && mounted) {
      // La entrega fue exitosa, actualizar la lista para reflejar los cambios
      setState(() {
        // Esto forzará la reconstrucción del widget y actualizará la lista
        // de correspondencias, removiendo el estilo de notificación de entrega
      });
    }
  }
}

class _DetalleCorrespondenciaModal extends StatefulWidget {
  final String condominioId;
  final CorrespondenciaModel correspondencia;
  final CorrespondenciaConfigModel? config;
  final UserModel currentUser;
  final VoidCallback onCorrespondenciaActualizada;

  const _DetalleCorrespondenciaModal({
    required this.condominioId,
    required this.correspondencia,
    required this.config,
    required this.currentUser,
    required this.onCorrespondenciaActualizada,
  });

  @override
  State<_DetalleCorrespondenciaModal> createState() =>
      _DetalleCorrespondenciaModalState();
}

class _DetalleCorrespondenciaModalState
    extends State<_DetalleCorrespondenciaModal> {
  final TextEditingController _nuevoMensajeController = TextEditingController();
  final CorrespondenciaService _correspondenciaService =
      CorrespondenciaService();
  bool _guardandoMensaje = false;
  bool _enviarNotificacion = false;

  @override
  void dispose() {
    _nuevoMensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles de Correspondencia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetalleRow(
                      'Tipo:',
                      widget.correspondencia.tipoCorrespondencia,
                    ),
                    _buildDetalleRow(
                      'Tipo de entrega:',
                      widget.correspondencia.tipoEntrega,
                    ),
                    _buildDetalleRow(
                      'Datos de entrega:',
                      widget.correspondencia.datosEntrega,
                    ),
                    if (widget.correspondencia.viviendaRecepcion != null)
                      _buildDetalleRow(
                        'Vivienda de recepción:',
                        widget.correspondencia.viviendaRecepcion!,
                      ),
                    _buildDetalleRow(
                      'Fecha de recepción:',
                      _formatearFecha(
                        widget.correspondencia.fechaHoraRecepcion,
                      ),
                    ),
                    if (widget.correspondencia.fechaHoraEntrega != null)
                      _buildDetalleRow(
                        'Fecha de entrega:',
                        _formatearFecha(
                          widget.correspondencia.fechaHoraEntrega!,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Adjuntos
                    if (widget.correspondencia.adjuntos.isNotEmpty) ...[
                      Text(
                        'Adjuntos:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildAdjuntos(),
                      const SizedBox(height: 16),
                    ],

                    // Mensajes adicionales existentes
                    if (widget.correspondencia.infAdicional != null &&
                        widget.correspondencia.infAdicional!.isNotEmpty) ...[
                      Text(
                        'Mensajes adicionales:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildMensajesExistentes(),
                      const SizedBox(height: 16),
                    ],

                    // Campo para nuevo mensaje
                    Text(
                      'Añadir nuevo mensaje:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNuevoMensaje(),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.currentUser.tipoUsuario == UserType.administrador &&
                    widget.correspondencia.fechaHoraEntrega == null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _abrirModalEntrega();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Marcar como Entregada'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAdjuntos() {
    // Convertir adjuntos a formato compatible con ImageCarouselWidget
    List<Map<String, dynamic>> images = [];
    
    for (var entry in widget.correspondencia.adjuntos.entries) {
      final value = entry.value;
      
      if (value is String) {
        // Imagen en formato Base64 directo
        if (value.startsWith('data:image/')) {
          // Extraer solo la parte base64, sin el prefijo data:image/...;base64,
          final base64Index = value.indexOf(',');
          if (base64Index != -1 && base64Index < value.length - 1) {
            final base64Data = value.substring(base64Index + 1);
            images.add({
              'type': 'normal',
              'data': base64Data,
              'name': entry.key,
            });
          }
        } else if (value.isNotEmpty) {
          // Asumir que es base64 puro
          images.add({
            'type': 'normal',
            'data': value,
            'name': entry.key,
          });
        }
      } else if (value is Map<String, dynamic>) {
        // Imagen fragmentada o con estructura compleja
        final type = value['type'] as String?;
        if (type == 'normal') {
          final data = value['data'] as String?;
          if (data != null) {
            String base64Data = data;
            if (data.startsWith('data:image/')) {
              final base64Index = data.indexOf(',');
              if (base64Index != -1 && base64Index < data.length - 1) {
                base64Data = data.substring(base64Index + 1);
              }
            }
            images.add({
              'type': 'normal',
              'data': base64Data,
              'name': entry.key,
            });
          }
        } else if (type == 'internal_fragmented' || type == 'external_fragmented' || type == 'fragmented') {
          // Agregar imagen fragmentada directamente
          final imageData = Map<String, dynamic>.from(value);
          imageData['name'] = entry.key;
          images.add(imageData);
        }
      }
    }

    if (images.isEmpty) {
      return const Text('No hay imágenes adjuntas');
    }

    return ImageCarouselWidget(
      images: images,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      onImageTap: (imageData) {
        ImageFullscreenHelper.showFullscreenImage(context, imageData);
      },
    );
  }

  Widget _buildMensajesExistentes() {
    final mensajes = widget.correspondencia.infAdicional!;

    return Column(
      children: mensajes.map((mensaje) {
        final texto = mensaje['mensaje'] ?? '';
        final fechaHora = mensaje['fechaHora'] ?? '';
        final usuarioId = mensaje['usuarioId'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(texto, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                'Por: $usuarioId - ${_formatearFecha(fechaHora)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNuevoMensaje() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nuevoMensajeController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribir nuevo mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _guardandoMensaje ? null : _guardarNuevoMensaje,
              icon: _guardandoMensaje
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
            const Text('Enviar notificación al residente'),
          ],
        ),
      ],
    );
  }

  String _formatearFecha(String fechaHora) {
    try {
      final fecha = DateTime.parse(fechaHora);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return fechaHora;
    }
  }

  Future<void> _guardarNuevoMensaje() async {
    final mensaje = _nuevoMensajeController.text.trim();
    if (mensaje.isEmpty) return;

    setState(() {
      _guardandoMensaje = true;
    });

    try {
      final now = DateTime.now();
      final fechaHora = now.toIso8601String();

      final nuevoMensaje = {
        'mensaje': mensaje,
        'fechaHora': fechaHora,
        'usuarioId': widget.currentUser.tipoUsuario == UserType.administrador
            ? 'admin'
            : widget.currentUser.uid,
      };

      // Obtener la lista actual de mensajes o crear una nueva
      final mensajesActuales = widget.correspondencia.infAdicional ?? [];
      final nuevaListaMensajes = [...mensajesActuales, nuevoMensaje];

      await _correspondenciaService.updateCorrespondencia(
        widget.condominioId,
        widget.correspondencia.id,
        {'infAdicional': nuevaListaMensajes},
      );

      // Enviar notificación si está marcado el checkbox
      if (_enviarNotificacion &&
          widget.correspondencia.residenteIdEntrega != null) {
        await _correspondenciaService.enviarNotificacionMensajeAdicional(
          widget.condominioId,
          widget.correspondencia.residenteIdEntrega!,
          widget.correspondencia.id,
          mensaje,
          widget.correspondencia,
        );
      }

      _nuevoMensajeController.clear();
      setState(() {
        _enviarNotificacion = false;
      });
      widget.onCorrespondenciaActualizada();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _enviarNotificacion
                  ? 'Mensaje guardado y notificación enviada exitosamente'
                  : 'Mensaje guardado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardandoMensaje = false;
        });
      }
    }
  }

  Future<void> _abrirModalEntrega() async {
    if (widget.config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando configuración...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEntregaCorrespondencia(
        condominioId: widget.condominioId,
        correspondencia: widget.correspondencia,
        config: widget.config!,
      ),
    );

    if (resultado == true && mounted) {
      widget.onCorrespondenciaActualizada();
      Navigator.of(context).pop();
    }
  }
}
