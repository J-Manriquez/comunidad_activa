import 'package:flutter/material.dart';
import '../../../services/multa_service.dart';
import '../../../models/user_model.dart';
import '../../../models/multa_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../utils/storage_service.dart';
import '../../../utils/image_display_widget.dart';

class HistorialMultasScreen extends StatefulWidget {
  final UserModel currentUser;

  const HistorialMultasScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  _HistorialMultasScreenState createState() => _HistorialMultasScreenState();
}

class _HistorialMultasScreenState extends State<HistorialMultasScreen> {
  final MultaService _multaService = MultaService();
  Map<String, List<MultaModel>> _multasAgrupadas = {};
  Map<String, bool> _fechasExpandidas = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Multas'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MultaModel>>(
        stream: _multaService.obtenerMultasCondominio(widget.currentUser.condominioId.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final multas = snapshot.data ?? [];
          
          if (multas.isEmpty) {
            return const Center(
              child: Text('No hay multas registradas'),
            );
          }

          // Agrupar multas por fecha
          _multasAgrupadas = _agruparMultasPorFecha(multas);
          final fechasOrdenadas = _multasAgrupadas.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Más reciente primero

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fechasOrdenadas.length,
            itemBuilder: (context, index) {
              final fecha = fechasOrdenadas[index];
              final multasDeFecha = _multasAgrupadas[fecha]!;
              final isExpanded = _fechasExpandidas[fecha] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        _formatearFecha(fecha),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${multasDeFecha.length} multa(s)'),
                      trailing: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onTap: () {
                        setState(() {
                          _fechasExpandidas[fecha] = !isExpanded;
                        });
                      },
                    ),
                    if (isExpanded)
                      ...multasDeFecha.map((multa) => _buildMultaItem(multa)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMultaItem(MultaModel multa) {
    return GestureDetector(
      onTap: () => _abrirModalDetalle(multa),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    multa.tipoMulta,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  multa.time,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              multa.contenido,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (multa.additionalData != null) ...[
              const SizedBox(height: 8),
              _buildAdditionalInfo(multa.additionalData!),
            ],
            // Agregar información de lectura
            if (multa.isRead != null && multa.isRead!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReadStatusInfo(multa.isRead!),
            ],
          ],
        ),
      ),
    );
  }

  // Nuevo método para abrir el modal de detalle (administrador)
  void _abrirModalDetalle(MultaModel multa) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _MultaDetalleModalAdmin(
        multa: multa,
      ),
    );
  }

  // Nuevo método para mostrar información de lectura
  Widget _buildReadStatusInfo(Map<String, dynamic> isRead) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: Colors.green[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Estado de Lectura:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isRead.isEmpty)
            Text(
              'No leída por ningún residente',
              style: TextStyle(color: Colors.orange[700], fontSize: 12),
            )
          else
            ...isRead.entries.map((entry) {
              final readData = entry.value as Map<String, dynamic>;
              final nombre = readData['nombre'] ?? 'Usuario';
              final fechaHora = readData['fechaHora'] ?? '';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green[600], size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$nombre - ${_formatearFechaHoraLectura(fechaHora)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Método auxiliar para formatear fecha y hora de lectura
  String _formatearFechaHoraLectura(String fechaHora) {
    try {
      final dateTime = DateTime.parse(fechaHora);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} a las ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
       return fechaHora;
     }
   }

  void _mostrarImagenCompleta(String imagenBase64) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(imagenBase64),
                  fit: BoxFit.contain,
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesEvidenciaModal(Map<String, dynamic> additionalData) {
    List<String> imagenes = [];
    
    // Extraer imágenes del additionalData
    if (additionalData['imagen1'] != null) imagenes.add(additionalData['imagen1']);
    if (additionalData['imagen2'] != null) imagenes.add(additionalData['imagen2']);
    if (additionalData['imagen3'] != null) imagenes.add(additionalData['imagen3']);
    
    if (imagenes.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.photo_library, color: Colors.purple[700], size: 20),
            const SizedBox(width: 12),
            Text(
              'Imágenes de evidencia:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: index < imagenes.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () => _mostrarImagenCompleta(imagenes[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(imagenes[index]),
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> additionalData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (additionalData['valor'] != null)
            Text('Valor: ${additionalData['valor']} ${additionalData['unidadMedida'] ?? ''}'),
          if (additionalData['tipoVivienda'] != null)
            Text('Vivienda: ${additionalData['tipoVivienda']} ${additionalData['numeroVivienda']}'),
          if (additionalData['etiquetaEdificio'] != null)
            Text('Edificio: ${additionalData['etiquetaEdificio']} - Depto: ${additionalData['numeroDepartamento']}'),
        ],
      ),
    );
  }

  Map<String, List<MultaModel>> _agruparMultasPorFecha(List<MultaModel> multas) {
    Map<String, List<MultaModel>> agrupadas = {};
    
    for (var multa in multas) {
      final fecha = multa.date;
      if (agrupadas[fecha] == null) {
        agrupadas[fecha] = [];
      }
      agrupadas[fecha]!.add(multa);
    }
    
    return agrupadas;
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return fecha;
    }
  }
}

// Modal de detalle para administradores
class _MultaDetalleModalAdmin extends StatelessWidget {
  final MultaModel multa;

  const _MultaDetalleModalAdmin({
    Key? key,
    required this.multa,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.gavel,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalle de Multa - Vista Administrador',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
            // Contenido del modal
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica de la multa
                    _buildDetailRow(
                      'Tipo de Multa:',
                      multa.tipoMulta,
                      Icons.category,
                      Colors.orange[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailSection(
                      'Descripción:',
                      multa.contenido,
                      Icons.description,
                      Colors.blue[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(
                      'Fecha:',
                      '${_formatearFecha(multa.date)} - ${multa.time}',
                      Icons.access_time,
                      Colors.grey[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Información adicional
                    if (multa.additionalData != null)
                      _buildAdditionalInfo(multa.additionalData!),
                    
                    // Imágenes de evidencia
                    if (multa.additionalData != null)
                      // _buildImagenesEvidenciaModal(multa.additionalData!),
                    
                    const SizedBox(height: 20),
                    
                    // Estado de lectura detallado
                    _buildReadStatusSection(multa.isRead),
                  ],
                ),
              ),
            ),
            // Footer del modal
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadStatusSection(Map<String, dynamic>? isRead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, color: Colors.green[700], size: 20),
            const SizedBox(width: 12),
            Text(
              'Estado de Lectura:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isRead?.isEmpty ?? true) ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isRead?.isEmpty ?? true) ? Colors.orange[200]! : Colors.green[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRead?.isEmpty ?? true)
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No leída por ningún residente',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else ...[
                Text(
                  'Leída por ${isRead!.length} residente(s):',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...isRead.entries.map((entry) {
                  final readData = entry.value as Map<String, dynamic>;
                  final nombre = readData['nombre'] ?? 'Usuario';
                  final fechaHora = readData['fechaHora'] ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            Icons.person,
                            color: Colors.green[700],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Leída el ${_formatearFechaHora(fechaHora)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares similares a los del modal del residente...
  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
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
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> additionalData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            Text(
              'Información Adicional:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (additionalData['valor'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Valor: ${additionalData['valor']} ${additionalData['unidadMedida'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              if (additionalData['tipoVivienda'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Colors.blue[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Vivienda: ${additionalData['tipoVivienda']} ${additionalData['numeroVivienda']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              if (additionalData['etiquetaEdificio'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.apartment, color: Colors.blue[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Edificio: ${additionalData['etiquetaEdificio']} - Depto: ${additionalData['numeroDepartamento']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              // Agregar imágenes de evidencia
              _buildImagenesEvidencia(additionalData),
            ],
          ),
        ),
      ],
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }

  String _formatearFechaHora(String fechaHora) {
    try {
      final dateTime = DateTime.parse(fechaHora);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} a las ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaHora;
    }
  }

  Widget _buildImagenesEvidencia(Map<String, dynamic> additionalData) {
    List<Map<String, dynamic>> imagenes = [];
    
    // Extraer imágenes del additionalData (soporte para ambos formatos)
    for (int i = 1; i <= 3; i++) {
      final imagenKey = 'imagen$i';
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
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.photo_library, color: Colors.purple[700], size: 18),
            const SizedBox(width: 8),
            Text(
              'Imágenes de evidencia:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              final imagenInfo = imagenes[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: index < imagenes.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _mostrarImagenCompleta(imagenInfo, context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imagenInfo['type'] == 'base64'
                        ? Image.memory(
                            base64Decode(imagenInfo['data']),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : ImageDisplayWidget(
                            imageData: imagenInfo['data'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _mostrarImagenCompleta(Map<String, dynamic> imagenInfo, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imagenInfo['type'] == 'base64'
                    ? Image.memory(
                        base64Decode(imagenInfo['data']),
                        fit: BoxFit.contain,
                      )
                    : ImageDisplayWidget(
                        imageData: imagenInfo['data'],
                        fit: BoxFit.contain,
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}