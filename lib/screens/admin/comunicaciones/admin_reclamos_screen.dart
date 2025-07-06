import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/reclamo_model.dart';
import '../../../services/reclamo_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

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
              Text(
                reclamo.contenido,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
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
    
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null && 
          additionalData[imagenKey].toString().isNotEmpty) {
        return true;
      }
    }
    return false;
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

    // Extraer las imágenes del additionalData
    List<String> imagenes = [];
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen${i}Base64';
      if (additionalData.containsKey(imagenKey) && 
          additionalData[imagenKey] != null && 
          additionalData[imagenKey].toString().isNotEmpty) {
        imagenes.add(additionalData[imagenKey]);
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
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _mostrarImagenCompleta(context, imagenes[index]),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(imagenes[index]),
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

  void _mostrarImagenCompleta(BuildContext context, String imagenBase64) {
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
                  child: Image.memory(
                    base64Decode(imagenBase64),
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

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }
}