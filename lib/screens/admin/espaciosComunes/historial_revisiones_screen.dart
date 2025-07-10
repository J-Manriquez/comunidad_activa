import 'package:comunidad_activa/models/reserva_model.dart';
import 'package:comunidad_activa/models/revision_uso_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';

class HistorialRevisionesScreen extends StatefulWidget {
  final UserModel currentUser;

  const HistorialRevisionesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<HistorialRevisionesScreen> createState() => _HistorialRevisionesScreenState();
}

class _HistorialRevisionesScreenState extends State<HistorialRevisionesScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  Map<String, List<ReservaModel>> _revisionesPorMes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorialRevisiones();
  }

  Future<void> _cargarHistorialRevisiones() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final reservas = await _espaciosComunesService.obtenerReservas(
        widget.currentUser.condominioId!,
      );
      
      // Filtrar solo las reservas con revisiones
      final reservasConRevision = reservas
          .where((reserva) => 
              reserva.revisionesUso != null && 
              reserva.revisionesUso!.isNotEmpty)
          .toList();
      
      // Agrupar por mes-año
      final Map<String, List<ReservaModel>> agrupadas = {};
      
      for (final reserva in reservasConRevision) {
        final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
        final mesAno = DateFormat('MMMM yyyy', 'es').format(fechaReserva);
        
        if (!agrupadas.containsKey(mesAno)) {
          agrupadas[mesAno] = [];
        }
        agrupadas[mesAno]!.add(reserva);
      }
      
      // Ordenar cada grupo por fecha
      agrupadas.forEach((key, value) {
        value.sort((a, b) => 
            DateTime.parse(b.fechaHoraReserva).compareTo(DateTime.parse(a.fechaHoraReserva)));
      });
      
      if (mounted) {
        setState(() {
          _revisionesPorMes = agrupadas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  void _mostrarDetalleRevision(ReservaModel reserva) {
    showDialog(
      context: context,
      builder: (context) => _DetalleRevisionDialog(reserva: reserva),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Revisiones'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _revisionesPorMes.isEmpty
              ? const Center(
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
                        'No hay revisiones en el historial',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarHistorialRevisiones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _revisionesPorMes.keys.length,
                    itemBuilder: (context, index) {
                      final mesAno = _revisionesPorMes.keys.elementAt(index);
                      final revisiones = _revisionesPorMes[mesAno]!;
                      return _buildMesSection(mesAno, revisiones);
                    },
                  ),
                ),
    );
  }

  Widget _buildMesSection(String mesAno, List<ReservaModel> revisiones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            mesAno.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade600,
            ),
          ),
        ),
        ...revisiones.map((reserva) => _buildRevisionCard(reserva)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRevisionCard(ReservaModel reserva) {
    final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
    
    // Obtener la primera revisión (asumiendo que hay al menos una)
    final revision = reserva.revisionesUso!.first;
    
    // Determinar el tipo de revisión
    String tipoRevision = revision.tipoRevision == 'pre_uso' ? 'PRE USO' : 'POST USO';
    Color colorTipo = revision.tipoRevision == 'pre_uso' ? Colors.blue : Colors.orange;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleRevision(reserva),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reserva.nombreEspacioComun,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorTipo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tipoRevision,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: revision.estado == 'aprobado' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      revision.estado.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Vivienda: ${reserva.vivienda}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (revision.costo != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Costo adicional: \$${NumberFormat('#,###').format(revision.costo)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleRevisionDialog extends StatelessWidget {
  final ReservaModel reserva;

  const _DetalleRevisionDialog({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle de Revisión',
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
                    // Información de la reserva
                    _buildInfoSection('Información de la Reserva', [
                      _buildInfoRow('Espacio:', reserva.nombreEspacioComun),
                      _buildInfoRow('Vivienda:', reserva.vivienda),
                      _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva)),
                      _buildInfoRow('Participantes:', '${reserva.participantes.length} personas'),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    // Revisiones
                    const Text(
                      'Revisiones Pre y Post Uso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    ...reserva.revisionesUso!.map((revision) {
                      return _buildRevisionItem(revision);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionItem(RevisionUsoModel revision) {
    final fechaRevision = DateTime.parse(revision.fecha);
    
    // Determinar el tipo y color de la revisión
    String tipoRevision = revision.tipoRevision == 'pre_uso' ? 'PRE USO' : 'POST USO';
    Color colorTipo = revision.tipoRevision == 'pre_uso' ? Colors.blue : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Revisión del ${DateFormat('dd/MM/yyyy HH:mm').format(fechaRevision)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorTipo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipoRevision,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: revision.estado == 'aprobado' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    revision.estado.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              revision.descripcion,
              style: const TextStyle(fontSize: 14),
            ),
            if (revision.costo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Costo adicional: \$${NumberFormat('#,###').format(revision.costo)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // Mostrar imágenes si las hay
            if (revision.additionalData != null) ...[
              const SizedBox(height: 8),
              _buildImagenesRevision(revision.additionalData!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagenesRevision(Map<String, dynamic> additionalData) {
    final List<String> imagenes = [];
    
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
        const Text(
          'Evidencia fotográfica:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              final imageBytes = base64Decode(imagenes[index]);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    imageBytes,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}