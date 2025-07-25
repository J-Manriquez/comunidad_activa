import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../services/multa_service.dart';
import '../../../models/user_model.dart';
import '../../../models/multa_model.dart';
import 'package:intl/intl.dart';
import 'historial_multas_screen.dart';

class MultasResidenteScreen extends StatefulWidget {
  final UserModel currentUser;
  final String? multaIdToOpen; // Agregar este parámetro opcional

  const MultasResidenteScreen({
    Key? key, 
    required this.currentUser,
    this.multaIdToOpen, // Parámetro opcional
  }) : super(key: key);

  @override
  _MultasResidenteScreenState createState() => _MultasResidenteScreenState();
}

class _MultasResidenteScreenState extends State<MultasResidenteScreen> {
  final MultaService _multaService = MultaService();
  Map<String, List<MultaModel>> _multasAgrupadas = {};
  Map<String, bool> _fechasExpandidas = {};
  bool _modalAbierto = false; // Agregar esta variable
  List<MultaModel> _multasDelMes = [];
  int _totalMultasDelMes = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Multas'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              if (value == 'historial') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialMultasScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'historial',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Historial'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<MultaModel>>(
        stream: _multaService.obtenerMultasResidente(
          widget.currentUser.condominioId.toString(),
          widget.currentUser.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final multas = snapshot.data ?? [];

          // Abrir modal automáticamente si se especificó una multa
          if (widget.multaIdToOpen != null && !_modalAbierto && multas.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _abrirMultaEspecifica(multas, widget.multaIdToOpen!);
            });
          }

          // Filtrar multas del mes actual
           final now = DateTime.now();
           _multasDelMes = multas.where((multa) {
              final fechaMulta = DateTime.parse(multa.fechaRegistro);
              return fechaMulta.year == now.year && fechaMulta.month == now.month;
            }).toList();
          
          // Calcular total de multas del mes y valor total
          _totalMultasDelMes = _multasDelMes.length;
          double _valorTotalMultas = 0;
          for (var multa in _multasDelMes) {
            if (multa.additionalData != null && multa.additionalData!['valor'] != null) {
              var valor = multa.additionalData!['valor'];
              if (valor is int) {
                _valorTotalMultas += valor.toDouble();
              } else if (valor is double) {
                _valorTotalMultas += valor;
              } else if (valor is String) {
                _valorTotalMultas += double.tryParse(valor) ?? 0;
              }
            }
          }
          
          // Agrupar multas del mes por fecha
          _multasAgrupadas = _agruparMultasPorFecha(_multasDelMes);
          final fechasOrdenadas = _multasAgrupadas.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Más reciente primero

          return Column(
            children: [
              // Container con el total de multas del mes
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[700]!, Colors.red[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Multas del Mes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor Total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '\$${_valorTotalMultas.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _totalMultasDelMes == 0 ? 'Sin multas' : 
                              _totalMultasDelMes == 1 ? '1 multa' : '$_totalMultasDelMes multas',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy', 'es').format(now),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _totalMultasDelMes == 0 ? '¡Mes limpio!' : 'Multas pendientes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Lista de multas del mes actual
              Expanded(
                child: _multasDelMes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '¡Excelente!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No tienes multas este mes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Nuevo método para abrir una multa específica
  void _abrirMultaEspecifica(List<MultaModel> multas, String multaId) {
    final multa = multas.firstWhere(
      (m) => m.id == multaId,
      orElse: () => multas.first, // Si no encuentra la multa específica, abre la primera
    );
    
    _modalAbierto = true;
    _abrirModalDetalle(multa);
  }

  Widget _buildMultaItem(MultaModel multa) {
    // Verificar si el usuario actual ya leyó esta multa
    bool yaLeida = multa.isRead?.containsKey(widget.currentUser.uid) ?? false;
    
    // Obtener el valor de la multa
    String valorMulta = '\$0';
    if (multa.additionalData != null && multa.additionalData!['valor'] != null) {
      var valor = multa.additionalData!['valor'];
      if (valor is int) {
        valorMulta = '\$${valor.toString()}';
      } else if (valor is double) {
        valorMulta = '\$${valor.toStringAsFixed(0)}';
      } else if (valor is String) {
        valorMulta = '\$${valor}';
      }
    }

    return GestureDetector(
      onTap: () => _abrirModalDetalle(multa),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: yaLeida ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: yaLeida ? Colors.grey[300]! : Colors.red[200]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: Tipo de multa y estado
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: yaLeida ? Colors.grey[600] : Colors.red[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      multa.tipoMulta,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: yaLeida ? Colors.grey[700] : Colors.red[800],
                      ),
                    ),
                  ),
                  if (!yaLeida)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NUEVA',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Segunda fila: Descripción
              Text(
                multa.contenido,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: yaLeida ? Colors.grey[600] : Colors.black87,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tercera fila: Monto y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Monto
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: yaLeida ? Colors.grey[200] : Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: yaLeida ? Colors.grey[400]! : Colors.red[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      valorMulta,
                      style: TextStyle(
                        color: yaLeida ? Colors.grey[700] : Colors.red[700],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Fecha de aplicación
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatearFecha(multa.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Indicador de leída (si aplica)
              if (yaLeida) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Leída',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Nuevo método para abrir el modal de detalle
  Future<void> _abrirModalDetalle(MultaModel multa) async {
    // Marcar como leída automáticamente si no ha sido leída
    bool yaLeida = multa.isRead?.containsKey(widget.currentUser.uid) ?? false;
    
    if (!yaLeida) {
      try {
        await _multaService.marcarMultaComoLeida(
          widget.currentUser.condominioId.toString(),
          multa.id,
          widget.currentUser.uid,
        );
      } catch (e) {
        print('Error al marcar multa como leída: $e');
      }
    }

    // Mostrar el modal
    showDialog(
      context: context,
      builder: (BuildContext context) => _MultaDetalleModal(
        multa: multa,
        currentUser: widget.currentUser,
      ),
    );
  }

  Map<String, List<MultaModel>> _agruparMultasPorFecha(
    List<MultaModel> multas,
  ) {
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

// Nuevo widget para el modal de detalle
class _MultaDetalleModal extends StatelessWidget {
  final MultaModel multa;
  final UserModel currentUser;

  const _MultaDetalleModal({
    Key? key,
    required this.multa,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool yaLeida = multa.isRead?.containsKey(currentUser.uid) ?? false;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    // Tipo de multa
                    _buildDetailRow(
                      'Tipo de Multa:',
                      multa.tipoMulta,
                      Icons.category,
                      Colors.orange[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Contenido
                    _buildDetailSection(
                      'Descripción:',
                      multa.contenido,
                      Icons.description,
                      Colors.blue[700]!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Fecha y hora
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
                      _buildImagenesEvidencia(multa.additionalData!),
                    
                    const SizedBox(height: 20),
                    
                    // Estado de lectura
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: yaLeida ? Colors.green[50] : Colors.orange[50],
                    //     borderRadius: BorderRadius.circular(8),
                    //     border: Border.all(
                    //       color: yaLeida ? Colors.green[200]! : Colors.orange[200]!,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         yaLeida ? Icons.check_circle : Icons.visibility,
                    //         color: yaLeida ? Colors.green[700] : Colors.orange[700],
                    //         size: 20,
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               yaLeida ? 'Multa Leída' : 'Multa Marcada como Leída',
                    //               style: TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //                 color: yaLeida ? Colors.green[700] : Colors.orange[700],
                    //               ),
                    //             ),
                    //             if (yaLeida && multa.isRead![currentUser.uid] is Map)
                    //               Text(
                    //                 'Leída el ${_formatearFechaHora(multa.isRead![currentUser.uid]['fechaHora'])}',
                    //                 style: TextStyle(
                    //                   color: Colors.green[600],
                    //                   fontSize: 12,
                    //                 ),
                    //               ),
                    //             if (!yaLeida)
                    //               Text(
                    //                 'Esta multa se ha marcado automáticamente como leída',
                    //                 style: TextStyle(
                    //                   color: Colors.orange[600],
                    //                   fontSize: 12,
                    //                 ),
                    //               ),
                    //           ],
                    //         ),
                    //       ),   
                    //     ],
                    //   ),
                    // ),
                  
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
                Row(
                  children: [
                    Icon(Icons.apartment, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Edificio: ${additionalData['etiquetaEdificio']} - Depto: ${additionalData['numeroDepartamento']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
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
                  onTap: () => _mostrarImagenCompleta(imagenes[index], context),

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

  String _formatearFechaHora(String fechaHora) {
    try {
      final dateTime = DateTime.parse(fechaHora);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} a las ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaHora;
    }
  }
}
