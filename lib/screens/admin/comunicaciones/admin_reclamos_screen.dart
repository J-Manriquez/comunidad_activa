import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/reclamo_model.dart';
import '../../../services/reclamo_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';
import '../../../widgets/image_carousel_widget.dart';
import '../../../utils/image_fullscreen_helper.dart';
import 'gestion_tipos_reclamos_screen.dart';

class AdminReclamosScreen extends StatefulWidget {
  final UserModel currentUser;
  final String? reclamoIdToOpen; // Agregar este parámetro

  const AdminReclamosScreen({
    Key? key, 
    required this.currentUser,
    this.reclamoIdToOpen, // Agregar este parámetro opcional
  }) : super(key: key);

  @override
  _AdminReclamosScreenState createState() => _AdminReclamosScreenState();
}

class _AdminReclamosScreenState extends State<AdminReclamosScreen> {
  final ReclamoService _reclamoService = ReclamoService();

  @override
  void initState() {
    super.initState();
    // Si se especifica un reclamoIdToOpen, abrir el modal después de que se construya la pantalla
    if (widget.reclamoIdToOpen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirReclamoEspecifico(widget.reclamoIdToOpen!);
      });
    }
  }

  // Método para abrir un reclamo específico
  Future<void> _abrirReclamoEspecifico(String reclamoId) async {
    try {
      // Obtener el stream de reclamos
      final reclamosStream = _reclamoService.obtenerReclamosCondominio(
        widget.currentUser.condominioId.toString(),
      );
      
      // Escuchar el primer evento del stream
      final reclamos = await reclamosStream.first;
      final reclamo = reclamos.firstWhere(
        (r) => r.id == reclamoId,
        orElse: () => throw Exception('Reclamo no encontrado'),
      );

      if (mounted) {
        _mostrarDetalleReclamo(reclamo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el reclamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestión de Reclamos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar tipos de reclamos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GestionTiposReclamosScreen(
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ReclamoModel>>(
        stream: _reclamoService.obtenerReclamosCondominio(
          widget.currentUser.condominioId.toString(),
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
                    'Error al cargar reclamos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final reclamos = snapshot.data ?? [];

          if (reclamos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reclamos registrados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reclamos.length,
            itemBuilder: (context, index) {
              final reclamo = reclamos[index];
              return _buildReclamoCard(reclamo);
            },
          );
        },
      ),
    );
  }

  Widget _buildReclamoCard(ReclamoModel reclamo) {
    final isResuelto = reclamo.isResuelto;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleReclamo(reclamo),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isResuelto ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isResuelto ? Icons.check_circle : Icons.pending,
                      color: isResuelto ? Colors.green[700] : Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reclamo.tipoReclamo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Residente: ${reclamo.additionalData?['nombreResidente'] ?? 'Desconocido'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isResuelto ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isResuelto ? 'RESUELTO' : 'PENDIENTE',
                      style: TextStyle(
                        color: isResuelto ? Colors.green[700] : Colors.orange[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mostrar contenido y carrusel de imágenes si existen
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrusel de imágenes a la izquierda si existen
                  if (_tieneImagenes(reclamo.additionalData)) ...[
                    _buildImagenesReclamo(reclamo.additionalData),
                    const SizedBox(width: 12),
                  ],
                  // Contenido del reclamo
                  Expanded(
                    child: Text(
                      reclamo.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reclamo.fechaFormateada} - ${reclamo.horaFormateada}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      // Mostrar indicador de imágenes si existen
                      if (_tieneImagenes(reclamo.additionalData)) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.image, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Con imágenes',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Toca para gestionar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleReclamo(ReclamoModel reclamo) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _ReclamoDetalleDialog(
        reclamo: reclamo,
        currentUser: widget.currentUser,
        reclamoService: _reclamoService,
      ),
    );
  }

  bool _tieneImagenes(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return false;
    
    // Verificar imágenes usando las mismas claves que se guardan en crear reclamo
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        // Puede ser String (Base64 tradicional) o Map (fragmentada)
        if (imagenData is String && imagenData.isNotEmpty) {
          return true;
        } else if (imagenData is Map<String, dynamic>) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildImagenesReclamo(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return const SizedBox.shrink();

    print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Iniciando construcción del carrusel');
    print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - additionalData: $additionalData');
    
    // Extraer las imágenes del additionalData usando la MISMA lógica que r_reclamos_screen.dart
    List<Map<String, dynamic>> imagenes = [];
    
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      
      print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Procesando imagen $i con clave: $imagenKey');
      
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Imagen $i encontrada: ${imagenData.runtimeType}');
        print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Contenido de imagenData: $imagenData');
        
        if (imagenData is String && imagenData.isNotEmpty) {
          // Imagen tradicional Base64 - usar estructura compatible con ImageDisplayWidget
          imagenes.add({
            'type': 'normal',
            'data': imagenData
          });
          print('✅ AdminReclamosScreen - _buildImagenesReclamo - Imagen Base64 $i agregada al carrusel');
        } else if (imagenData is Map<String, dynamic>) {
          // Imagen fragmentada - usar la misma lógica que r_reclamos_screen.dart
          if (imagenData.containsKey('fragments') && imagenData['fragments'] is List) {
            final fragments = imagenData['fragments'] as List;
            print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Fragmentos encontrados: ${fragments.length}');
            
            if (fragments.length <= 10) {
              // Fragmentada internamente
              imagenes.add({
                'type': 'internal_fragmented',
                'fragments': fragments,
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ AdminReclamosScreen - _buildImagenesReclamo - Imagen fragmentada interna $i agregada');
            } else {
              // Fragmentada externamente
              imagenes.add({
                'type': 'external_fragmented',
                'fragment_id': imagenData['fragment_id'],
                'total_fragments': imagenData['total_fragments'],
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ AdminReclamosScreen - _buildImagenesReclamo - Imagen fragmentada externa $i agregada');
            }
          } else if (imagenData.containsKey('fragment_id')) {
            // Fragmentada externamente sin lista de fragmentos
            imagenes.add({
              'type': 'external_fragmented',
              'fragment_id': imagenData['fragment_id'],
              'total_fragments': imagenData['total_fragments'] ?? 1,
              'original_type': imagenData['original_type'] ?? 'image/jpeg'
            });
            print('✅ AdminReclamosScreen - _buildImagenesReclamo - Imagen fragmentada externa $i agregada (sin lista)');
          } else {
            // Estructura desconocida, intentar extraer datos directamente
            print('⚠️ AdminReclamosScreen - _buildImagenesReclamo - Estructura desconocida para imagen $i: ${imagenData.keys}');
            
            // Buscar si hay datos base64 directos en la estructura
            String? base64Data;
            if (imagenData.containsKey('data') && imagenData['data'] is String) {
              base64Data = imagenData['data'];
            } else if (imagenData.containsKey('base64') && imagenData['base64'] is String) {
              base64Data = imagenData['base64'];
            }
            
            if (base64Data != null && base64Data.isNotEmpty) {
              imagenes.add({
                'type': 'normal',
                'data': base64Data
              });
              print('✅ AdminReclamosScreen - _buildImagenesReclamo - Imagen extraída como normal $i');
            } else {
              print('❌ AdminReclamosScreen - _buildImagenesReclamo - No se pudo procesar imagen $i');
            }
          }
        }
      }
    }

    print('🖼️ AdminReclamosScreen - _buildImagenesReclamo - Total de imágenes encontradas: ${imagenes.length}');

    if (imagenes.isEmpty) {
      print('⚠️ AdminReclamosScreen - _buildImagenesReclamo - No se encontraron imágenes válidas');
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      width: 120,
      child: ImageCarouselWidget(
        images: imagenes,
        height: 100,
        width: 120,
        onImageTap: (imageData) {
          // Mostrar imagen en pantalla completa
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ImageDisplayWidget(imageData: imageData),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dialog para mostrar el detalle del reclamo
class _ReclamoDetalleDialog extends StatefulWidget {
  final ReclamoModel reclamo;
  final UserModel currentUser;
  final ReclamoService reclamoService;

  const _ReclamoDetalleDialog({
    Key? key,
    required this.reclamo,
    required this.currentUser,
    required this.reclamoService,
  }) : super(key: key);

  @override
  _ReclamoDetalleDialogState createState() => _ReclamoDetalleDialogState();
}

class _ReclamoDetalleDialogState extends State<_ReclamoDetalleDialog> {
  final _respuestaController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isResuelto = widget.reclamo.isResuelto;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isResuelto ? Colors.green[700] : Colors.orange[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isResuelto ? Icons.check_circle : Icons.pending,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalle del Reclamo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildDetailRow(
                      'Tipo de Reclamo:',
                      widget.reclamo.tipoReclamo,
                      Icons.category,
                      Colors.blue[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(
                      'Residente:',
                      widget.reclamo.additionalData?['nombreResidente'] ?? 'Desconocido',
                      Icons.person,
                      Colors.green[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(
                      'Fecha:',
                      '${widget.reclamo.fechaFormateada} - ${widget.reclamo.horaFormateada}',
                      Icons.access_time,
                      Colors.grey[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Estado
                    _buildDetailRow(
                      'Estado:',
                      isResuelto ? 'Resuelto' : 'Pendiente',
                      isResuelto ? Icons.check_circle : Icons.pending,
                      isResuelto ? Colors.green[700]! : Colors.orange[700]!,
                    ),
                    const SizedBox(height: 20),
                    
                    // Descripción
                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.reclamo.contenido,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    // Mostrar imágenes de evidencia si existen
                    _buildImagenesEvidencia(widget.reclamo.additionalData),
                    
                    // Mostrar respuesta si existe
                    if (isResuelto && widget.reclamo.estado?['mensajeRespuesta'] != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Respuesta del Administrador:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          widget.reclamo.estado!['mensajeRespuesta'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    
                    // Campo para respuesta si no está resuelto
                    if (!isResuelto) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Respuesta (opcional):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _respuestaController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Escriba una respuesta al residente (opcional)...',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Botones
            if (!isResuelto)
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resolverReclamo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            : const Text('Marcar como Resuelto'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resolverReclamo() async {
    setState(() => _isLoading = true);
    
    try {
      await widget.reclamoService.resolverReclamo(
        widget.currentUser.condominioId.toString(),
        widget.reclamo.id,
        widget.currentUser.uid,
        widget.currentUser.nombre ?? 'Administrador',
        _respuestaController.text.isNotEmpty ? _respuestaController.text : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reclamo marcado como resuelto'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resolver reclamo: $e'),
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

  Widget _buildImagenesEvidencia(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return const SizedBox.shrink();

    print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Iniciando construcción del carrusel');
    print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - additionalData: $additionalData');
    
    // Extraer las imágenes del additionalData usando la MISMA lógica que r_reclamos_screen.dart
    List<Map<String, dynamic>> imagenes = [];
    
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      
      print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Procesando imagen $i con clave: $imagenKey');
      
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Imagen $i encontrada: ${imagenData.runtimeType}');
        print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Contenido de imagenData: $imagenData');
        
        if (imagenData is String && imagenData.isNotEmpty) {
          // Imagen tradicional Base64 - usar estructura compatible con ImageDisplayWidget
          imagenes.add({
            'type': 'normal',
            'data': imagenData
          });
          print('✅ AdminReclamosScreen - _buildImagenesEvidencia - Imagen Base64 $i agregada al carrusel');
        } else if (imagenData is Map<String, dynamic>) {
          // Imagen fragmentada - usar la misma lógica que r_reclamos_screen.dart
          if (imagenData.containsKey('fragments') && imagenData['fragments'] is List) {
            final fragments = imagenData['fragments'] as List;
            print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Fragmentos encontrados: ${fragments.length}');
            
            if (fragments.length <= 10) {
              // Fragmentada internamente
              imagenes.add({
                'type': 'internal_fragmented',
                'fragments': fragments,
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ AdminReclamosScreen - _buildImagenesEvidencia - Imagen fragmentada interna $i agregada');
            } else {
              // Fragmentada externamente
              imagenes.add({
                'type': 'external_fragmented',
                'fragment_id': imagenData['fragment_id'],
                'total_fragments': imagenData['total_fragments'],
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ AdminReclamosScreen - _buildImagenesEvidencia - Imagen fragmentada externa $i agregada');
            }
          } else if (imagenData.containsKey('fragment_id')) {
            // Fragmentada externamente sin lista de fragmentos
            imagenes.add({
              'type': 'external_fragmented',
              'fragment_id': imagenData['fragment_id'],
              'total_fragments': imagenData['total_fragments'] ?? 1,
              'original_type': imagenData['original_type'] ?? 'image/jpeg'
            });
            print('✅ AdminReclamosScreen - _buildImagenesEvidencia - Imagen fragmentada externa $i agregada (sin lista)');
          } else {
            // Estructura desconocida, intentar extraer datos directamente
            print('⚠️ AdminReclamosScreen - _buildImagenesEvidencia - Estructura desconocida para imagen $i: ${imagenData.keys}');
            
            // Buscar si hay datos base64 directos en la estructura
            String? base64Data;
            if (imagenData.containsKey('data') && imagenData['data'] is String) {
              base64Data = imagenData['data'];
            } else if (imagenData.containsKey('base64') && imagenData['base64'] is String) {
              base64Data = imagenData['base64'];
            }
            
            if (base64Data != null && base64Data.isNotEmpty) {
              imagenes.add({
                'type': 'normal',
                'data': base64Data
              });
              print('✅ AdminReclamosScreen - _buildImagenesEvidencia - Imagen extraída como normal $i');
            } else {
              print('❌ AdminReclamosScreen - _buildImagenesEvidencia - No se pudo procesar imagen $i');
            }
          }
        }
      }
    }

    print('🖼️ AdminReclamosScreen - _buildImagenesEvidencia - Total de imágenes encontradas: ${imagenes.length}');

    if (imagenes.isEmpty) {
      print('⚠️ AdminReclamosScreen - _buildImagenesEvidencia - No se encontraron imágenes válidas');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Imágenes de Evidencia:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          child: ImageCarouselWidget(
            images: imagenes,
            height: 200,
            width: double.infinity,
            onImageTap: (imageData) {
              // Mostrar imagen en pantalla completa
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                          ),
                          child: ImageDisplayWidget(imageData: imageData),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Desliza para ver más imágenes. Toca una imagen para verla en pantalla completa',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }
}