import 'package:flutter/material.dart';
import '../../../services/multa_service.dart';
import '../../../models/user_model.dart';
import '../../../models/multa_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HistorialMultasScreen extends StatefulWidget {
  final UserModel currentUser;

  const HistorialMultasScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<HistorialMultasScreen> createState() => _HistorialMultasScreenState();
}

class _HistorialMultasScreenState extends State<HistorialMultasScreen> {
  final MultaService _multaService = MultaService();
  Map<String, List<MultaModel>> _multasPorMes = {};
  Map<String, bool> _mesesExpandidos = {};
  bool _modalAbierto = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Multas'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MultaModel>>(
        stream: _multaService.obtenerMultasResidente(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay historial de multas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final multas = snapshot.data!;
          final now = DateTime.now();
          
          // Filtrar multas de meses pasados (excluyendo el mes actual)
          final multasPasadas = multas.where((multa) {
            final fechaMulta = DateTime.parse(multa.fechaRegistro);
            return fechaMulta.year < now.year || 
                   (fechaMulta.year == now.year && fechaMulta.month < now.month);
          }).toList();

          if (multasPasadas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay multas en meses anteriores',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Agrupar multas por mes
          _multasPorMes = _agruparMultasPorMes(multasPasadas);
          final mesesOrdenados = _multasPorMes.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Más reciente primero

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mesesOrdenados.length,
            itemBuilder: (context, index) {
              final mesKey = mesesOrdenados[index];
              final multasDelMes = _multasPorMes[mesKey]!;
              final estaExpandido = _mesesExpandidos[mesKey] ?? false;
              
              // Parsear el mes para mostrar formato legible
              final fechaMes = DateTime.parse('$mesKey-01');
              final nombreMes = DateFormat('MMMM yyyy', 'es').format(fechaMes);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: Colors.red[700],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          nombreMes.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                        subtitle: Text(
                          '${multasDelMes.length} multa${multasDelMes.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            estaExpandido
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.red[700],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _mesesExpandidos[mesKey] = !estaExpandido;
                          });
                        },
                      ),
                    ),
                    if (estaExpandido)
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: multasDelMes.map((multa) => _buildMultaItem(multa)).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<MultaModel>> _agruparMultasPorMes(List<MultaModel> multas) {
    final Map<String, List<MultaModel>> agrupadas = {};
    
    for (final multa in multas) {
      final fecha = DateTime.parse(multa.fechaRegistro);
      final mesKey = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      
      if (!agrupadas.containsKey(mesKey)) {
        agrupadas[mesKey] = [];
      }
      agrupadas[mesKey]!.add(multa);
    }
    
    return agrupadas;
  }

  Widget _buildMultaItem(MultaModel multa) {
    final currentUser = widget.currentUser;
    final yaLeida = multa.isRead != null && 
                   multa.isRead!.containsKey(currentUser.uid) && 
                   multa.isRead![currentUser.uid] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: yaLeida ? Colors.green[200]! : Colors.orange[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: yaLeida ? Colors.green[50] : Colors.orange[50],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: yaLeida ? Colors.green[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            yaLeida ? Icons.check_circle : Icons.warning_amber,
            color: yaLeida ? Colors.green[700] : Colors.orange[700],
            size: 20,
          ),
        ),
        title: Text(
          multa.tipoMulta,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              multa.contenido,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatearFechaHora(multa.fechaRegistro),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          yaLeida ? Icons.visibility : Icons.visibility_off,
          color: yaLeida ? Colors.green[600] : Colors.orange[600],
          size: 18,
        ),
        onTap: () => _abrirModalDetalle(multa),
      ),
    );
  }

  void _abrirModalDetalle(MultaModel multa) async {
    if (_modalAbierto) return;
    
    setState(() {
      _modalAbierto = true;
    });

    // Marcar como leída si no lo está
    final currentUser = widget.currentUser;
    final yaLeida = multa.isRead != null && 
                   multa.isRead!.containsKey(currentUser.uid) && 
                   multa.isRead![currentUser.uid] == true;

    if (!yaLeida) {
      await _multaService.marcarMultaComoLeida(
        widget.currentUser.condominioId!,
        multa.id,
        currentUser.uid,
      );
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => _MultaDetalleModal(multa: multa),
      ).then((_) {
        setState(() {
          _modalAbierto = false;
        });
      });
    }
  }

  String _formatearFechaHora(String fechaHora) {
    try {
      final dateTime = DateTime.parse(fechaHora);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaHora;
    }
  }
}

class _MultaDetalleModal extends StatelessWidget {
  final MultaModel multa;

  const _MultaDetalleModal({required this.multa});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalle de Multa',
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
            
            // Contenido del modal
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Tipo de Multa:',
                      multa.tipoMulta,
                      Icons.category,
                      Colors.red[700]!,
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
                      'Fecha y Hora:',
                      _formatearFechaHora(multa.fechaRegistro),
                      Icons.access_time,
                      Colors.green[700]!,
                    ),
                    if (multa.additionalData != null && multa.additionalData!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAdditionalInfo(multa.additionalData!),
                    ],
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
                    backgroundColor: Colors.red[700],
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

  String _formatearFechaHora(String fechaHora) {
    try {
      final dateTime = DateTime.parse(fechaHora);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} a las ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaHora;
    }
  }

  Widget _buildImagenesEvidencia(Map<String, dynamic> additionalData) {
    List<String> imagenes = [];
    
    // Extraer imágenes del additionalData
    if (additionalData['imagen1'] != null) imagenes.add(additionalData['imagen1']);
    if (additionalData['imagen2'] != null) imagenes.add(additionalData['imagen2']);
    if (additionalData['imagen3'] != null) imagenes.add(additionalData['imagen3']);
    
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
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: index < imagenes.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _mostrarImagenCompleta(imagenes[index], context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(imagenes[index]),
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
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
  
  void _mostrarImagenCompleta(String imagenBase64, BuildContext context) {
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
}