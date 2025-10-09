import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/reclamo_model.dart';
import '../../../services/reclamo_service.dart';
import 'crear_reclamo_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';
import '../../../widgets/image_carousel_widget.dart';

class ReclamosResidenteScreen extends StatefulWidget {
  final UserModel currentUser;
  final String? reclamoIdToOpen;

  const ReclamosResidenteScreen({
    Key? key,
    required this.currentUser,
    this.reclamoIdToOpen,
  }) : super(key: key);

  @override
  _ReclamosResidenteScreenState createState() => _ReclamosResidenteScreenState();
}

class _ReclamosResidenteScreenState extends State<ReclamosResidenteScreen> {
  final ReclamoService _reclamoService = ReclamoService();
  Map<String, List<ReclamoModel>> _reclamosAgrupados = {};
  Map<String, bool> _fechasExpandidas = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mis Reclamos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Card para crear nuevo reclamo
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CrearReclamoScreen(currentUser: widget.currentUser),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_comment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crear Nuevo Reclamo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Reporta cualquier inconveniente',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Historial de reclamos
          Expanded(
            child: // En el StreamBuilder, agregar más depuración
            StreamBuilder<List<ReclamoModel>>(
              stream: _reclamoService.obtenerReclamosResidente(
                widget.currentUser.condominioId.toString(),
                widget.currentUser.uid,
              ),
              builder: (context, snapshot) {
                print(
                  '🔄 StreamBuilder - Estado de conexión: ${snapshot.connectionState}',
                );
                print('📊 StreamBuilder - Tiene datos: ${snapshot.hasData}');
                print('❌ StreamBuilder - Tiene error: ${snapshot.hasError}');

                if (snapshot.hasError) {
                  print('❌ Error en StreamBuilder: ${snapshot.error}');
                  print('📍 StackTrace: ${snapshot.stackTrace}');
                }

                if (snapshot.hasData) {
                  print(
                    '📋 Datos recibidos: ${snapshot.data?.length} reclamos',
                  );
                  for (var reclamo in snapshot.data ?? []) {
                    print(
                      '   - ${reclamo.id}: ${reclamo.tipoReclamo} (${reclamo.isResuelto ? "Resuelto" : "Pendiente"})',
                    );
                  }
                }

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
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Forzar rebuild
                          },
                          child: const Text('Reintentar'),
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
                          'No tienes reclamos registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer reclamo usando el botón de arriba',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Agrupar reclamos por fecha
                _reclamosAgrupados = _agruparReclamosPorFecha(reclamos);
                final fechasOrdenadas = _reclamosAgrupados.keys.toList()
                  ..sort((a, b) => b.compareTo(a)); // Más reciente primero

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: fechasOrdenadas.length,
                  itemBuilder: (context, index) {
                    final fecha = fechasOrdenadas[index];
                    final reclamosDeFecha = _reclamosAgrupados[fecha]!;
                    final isExpanded = _fechasExpandidas[fecha] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              _formatearFecha(fecha),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${reclamosDeFecha.length} reclamo(s)',
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                _fechasExpandidas[fecha] = !isExpanded;
                              });
                            },
                          ),
                          if (isExpanded)
                            ...reclamosDeFecha.map(
                              (reclamo) => _buildReclamoItem(reclamo),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Si hay un reclamo específico para abrir, esperamos un momento y lo abrimos
    if (widget.reclamoIdToOpen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSpecificReclamo(widget.reclamoIdToOpen!);
      });
    }
  }

  // Método para abrir un reclamo específico
  Future<void> _openSpecificReclamo(String reclamoId) async {
    try {
      // Buscar el reclamo en el stream
      final reclamosStream = _reclamoService.obtenerReclamosResidente(
        widget.currentUser.condominioId.toString(),
        widget.currentUser.uid,
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

  // Agregar este método para mostrar el modal de detalles
  void _mostrarDetalleReclamo(ReclamoModel reclamo) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _ReclamoDetalleDialog(
        reclamo: reclamo,
        currentUser: widget.currentUser,
      ),
    );
  }

  Widget _buildReclamoItem(ReclamoModel reclamo) {
    return InkWell(
      onTap: () => _mostrarDetalleReclamo(reclamo),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: reclamo.isResuelto ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: reclamo.isResuelto
                ? Colors.green[300]!
                : Colors.orange[300]!,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel de imágenes a la izquierda
            if (_tieneImagenes(reclamo.additionalData))
              _buildImagenesReclamo(reclamo.additionalData!, context),
            // Contenido del reclamo a la derecha
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: _tieneImagenes(reclamo.additionalData) ? 12 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          reclamo.isResuelto ? Icons.check_circle : Icons.pending,
                          color: reclamo.isResuelto
                              ? Colors.green[700]
                              : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reclamo.tipoReclamo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: reclamo.isResuelto
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: reclamo.isResuelto
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reclamo.isResuelto ? 'RESUELTO' : 'PENDIENTE',
                            style: TextStyle(
                              color: reclamo.isResuelto
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reclamo.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${reclamo.fechaFormateada} - ${reclamo.horaFormateada}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
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
                        if (reclamo.isResuelto &&
                            reclamo.mensajeRespuesta != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.message, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Con respuesta',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<ReclamoModel>> _agruparReclamosPorFecha(
    List<ReclamoModel> reclamos,
  ) {
    Map<String, List<ReclamoModel>> agrupados = {};

    for (var reclamo in reclamos) {
      final fecha = reclamo.fechaFormateada;
      if (agrupados[fecha] == null) {
        agrupados[fecha] = [];
      }
      agrupados[fecha]!.add(reclamo);
    }

    return agrupados;
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateFormat('dd/MM/yyyy').parse(fecha);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (targetDate == today) {
        return 'Hoy';
      } else if (targetDate == yesterday) {
        return 'Ayer';
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return fecha;
    }
  }

  bool _tieneImagenes(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return false;
    
    // Usar la misma lógica que _buildImagenesEvidencia
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        if (imagenData is String && imagenData.isNotEmpty) {
          return true;
        } else if (imagenData is Map<String, dynamic>) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildImagenesReclamo(Map<String, dynamic> additionalData, BuildContext context) {
    print('🖼️ _buildImagenesReclamo - Iniciando construcción del carrusel');
    print('🖼️ _buildImagenesReclamo - additionalData: $additionalData');
    
    // Extraer las imágenes del additionalData usando la MISMA lógica que _buildImagenesEvidencia
    List<Map<String, dynamic>> imagenes = [];
    
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      
      print('🖼️ _buildImagenesReclamo - Procesando imagen $i con clave: $imagenKey');
      
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        print('🖼️ _buildImagenesReclamo - Imagen $i encontrada: ${imagenData.runtimeType}');
        print('🖼️ _buildImagenesReclamo - Contenido de imagenData: $imagenData');
        
        if (imagenData is String && imagenData.isNotEmpty) {
          // Imagen tradicional Base64 - usar estructura compatible con ImageDisplayWidget
          imagenes.add({
            'type': 'normal',
            'data': imagenData
          });
          print('✅ _buildImagenesReclamo - Imagen Base64 $i agregada al carrusel');
        } else if (imagenData is Map<String, dynamic>) {
          // Imagen fragmentada - usar la misma lógica que _buildImagenesEvidencia
          if (imagenData.containsKey('fragments') && imagenData['fragments'] is List) {
            final fragments = imagenData['fragments'] as List;
            print('🖼️ _buildImagenesReclamo - Fragmentos encontrados: ${fragments.length}');
            
            if (fragments.length <= 10) {
              // Fragmentada internamente
              imagenes.add({
                'type': 'internal_fragmented',
                'fragments': fragments,
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ _buildImagenesReclamo - Imagen fragmentada interna $i agregada');
            } else {
              // Fragmentada externamente
              imagenes.add({
                'type': 'external_fragmented',
                'fragment_id': imagenData['fragment_id'],
                'total_fragments': imagenData['total_fragments'],
                'original_type': imagenData['original_type'] ?? 'image/jpeg'
              });
              print('✅ _buildImagenesReclamo - Imagen fragmentada externa $i agregada');
            }
          } else if (imagenData.containsKey('fragment_id')) {
            // Fragmentada externamente sin lista de fragmentos
            imagenes.add({
              'type': 'external_fragmented',
              'fragment_id': imagenData['fragment_id'],
              'total_fragments': imagenData['total_fragments'] ?? 1,
              'original_type': imagenData['original_type'] ?? 'image/jpeg'
            });
            print('✅ _buildImagenesReclamo - Imagen fragmentada externa $i agregada (sin lista)');
          } else {
            // Estructura desconocida, intentar extraer datos directamente
            print('⚠️ _buildImagenesReclamo - Estructura desconocida para imagen $i: ${imagenData.keys}');
            
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
              print('✅ _buildImagenesReclamo - Imagen extraída como normal $i');
            } else {
              print('❌ _buildImagenesReclamo - No se pudo procesar imagen $i');
            }
          }
        }
      }
    }

    print('🖼️ _buildImagenesReclamo - Total de imágenes encontradas: ${imagenes.length}');

    if (imagenes.isEmpty) {
      print('❌ _buildImagenesReclamo - No hay imágenes para mostrar');
      return const SizedBox.shrink();
    }

    print('✅ _buildImagenesReclamo - Construyendo ImageCarouselWidget con ${imagenes.length} imágenes');

    return Container(
      width: 120,
      height: 100,
      child: ImageCarouselWidget(
        images: imagenes,
        width: 120,
        height: 100,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
        onImageTap: (imageData) {
          print('🖼️ _buildImagenesReclamo - Imagen tocada, mostrando completa');
          _mostrarImagenCompleta(context, imageData);
        },
      ),
    );
  }
  void _mostrarImagenCompleta(BuildContext context, Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Fondo semi-transparente
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Imagen en pantalla completa
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageDisplayWidget(
                      imageData: imageData,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 40,
                right: 40,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Dialog para mostrar el detalle del reclamo (versión residente)
class _ReclamoDetalleDialog extends StatelessWidget {
  final ReclamoModel reclamo;
  final UserModel currentUser;

  const _ReclamoDetalleDialog({
    required this.reclamo,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: reclamo.isResuelto ? Colors.green[50] : Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    reclamo.isResuelto ? Icons.check_circle : Icons.pending,
                    color: reclamo.isResuelto ? Colors.green[700] : Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalle del Reclamo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: reclamo.isResuelto ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: reclamo.isResuelto ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reclamo.isResuelto ? 'RESUELTO' : 'PENDIENTE',
                      style: TextStyle(
                        color: reclamo.isResuelto ? Colors.green[700] : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Tipo de Reclamo:',
                      reclamo.tipoReclamo,
                      Icons.category_outlined,
                      Colors.blue[700]!,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Fecha y Hora:',
                      '${reclamo.fechaFormateada} - ${reclamo.horaFormateada}',
                      Icons.access_time,
                      Colors.grey[700]!,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Estado:',
                      reclamo.isResuelto ? 'Resuelto' : 'Pendiente',
                      reclamo.isResuelto ? Icons.check_circle : Icons.pending,
                      reclamo.isResuelto ? Colors.green[700]! : Colors.orange[700]!,
                    ),
                    const SizedBox(height: 20),
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
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        reclamo.contenido,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    // Mostrar imágenes de evidencia si existen
                    _buildImagenesEvidencia(reclamo.additionalData),
                    // ✅ Mostrar respuesta del administrador si existe
                    if (reclamo.isResuelto && reclamo.mensajeRespuesta != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Respuesta del Administrador:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
                          reclamo.mensajeRespuesta!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (reclamo.fechaResolucion != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Resuelto el: ${_formatearFechaResolucion(reclamo.fechaResolucion!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
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

  String _formatearFechaResolucion(String fechaISO) {
    try {
      final dateTime = DateTime.parse(fechaISO);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} a las ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaISO;
    }
  }

  Widget _buildImagenesEvidencia(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return const SizedBox.shrink();

    // Extraer las imágenes del additionalData (ahora pueden ser fragmentadas)
    List<Map<String, dynamic>> imagenes = [];
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null) {
        final imagenData = additionalData[imagenKey];
        if (imagenData is String && imagenData.isNotEmpty) {
          // Imagen tradicional Base64
          imagenes.add({'type': 'base64', 'data': imagenData});
        } else if (imagenData is Map<String, dynamic>) {
          // Imagen fragmentada
          imagenes.add({'type': 'fragmented', 'data': imagenData});
        }
      }
    }

    if (imagenes.isEmpty) return const SizedBox.shrink();

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
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              final imagenInfo = imagenes[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _mostrarImagenCompleta(context, imagenInfo),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imagenInfo['type'] == 'base64'
                          ? Image.memory(
                              base64Decode(imagenInfo['data']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : ImageDisplayWidget(
                              imageData: imagenInfo['data'],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca una imagen para verla en pantalla completa',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _mostrarImagenCompleta(BuildContext context, Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildImageFromData(imageData),
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

  Widget _buildImageFromData(Map<String, dynamic> imageData) {
    // Si es una imagen Base64 simple
    if (imageData.containsKey('base64')) {
      final base64String = imageData['base64'] as String;
      // Limpiar el prefijo data:image si existe
      final cleanBase64 = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;
      
      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 50,
              ),
            ),
          );
        },
      );
    }
    
    // Si es una imagen fragmentada, usar ImageDisplayWidget
    return ImageDisplayWidget(
      imageData: imageData,
      fit: BoxFit.contain,
    );
  }
}
