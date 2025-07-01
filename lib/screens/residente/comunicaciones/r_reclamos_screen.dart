import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/reclamo_model.dart';
import '../../../services/reclamo_service.dart';
import 'crear_reclamo_screen.dart';
import 'package:intl/intl.dart';

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
                Text(
                  '${reclamo.fechaFormateada} - ${reclamo.horaFormateada}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (reclamo.isResuelto &&
                    reclamo.estado?['mensajeRespuesta'] != null) ...[
                  const Spacer(),
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
                const Spacer(),
                Text(
                  'Toca para ver detalles',
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
}

// Agregar al final del archivo, antes del último }

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
}
