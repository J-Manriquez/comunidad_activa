import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../models/user_model.dart';
import '../../../services/correspondencia_service.dart';

class HistorialCorrespondenciasScreen extends StatefulWidget {
  final String condominioId;
  final UserModel currentUser;

  const HistorialCorrespondenciasScreen({
    super.key,
    required this.condominioId,
    required this.currentUser,
  });

  @override
  State<HistorialCorrespondenciasScreen> createState() =>
      _HistorialCorrespondenciasScreenState();
}

class _HistorialCorrespondenciasScreenState
    extends State<HistorialCorrespondenciasScreen> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Correspondencias'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CorrespondenciaModel>>(
        stream: _correspondenciaService.getCorrespondencias(widget.condominioId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                    'Error al cargar historial',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final correspondencias = snapshot.data ?? [];
          
          // Filtrar solo correspondencias entregadas (con fecha de entrega)
          final correspondenciasEntregadas = correspondencias
              .where((c) => c.fechaHoraEntrega != null && c.fechaHoraEntrega!.isNotEmpty)
              .toList();

          // Ordenar por fecha de entrega (más recientes primero)
          correspondenciasEntregadas.sort((a, b) {
            final fechaA = DateTime.tryParse(a.fechaHoraEntrega!) ?? DateTime.now();
            final fechaB = DateTime.tryParse(b.fechaHoraEntrega!) ?? DateTime.now();
            return fechaB.compareTo(fechaA);
          });

          if (correspondenciasEntregadas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay correspondencias entregadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El historial aparecerá cuando se entreguen correspondencias',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: correspondenciasEntregadas.length,
            itemBuilder: (context, index) {
              final correspondencia = correspondenciasEntregadas[index];
              return _buildCorrespondenciaCard(correspondencia);
            },
          );
        },
      ),
    );
  }

  Widget _buildCorrespondenciaCard(CorrespondenciaModel correspondencia) {
    final fechaRecepcion = DateTime.tryParse(correspondencia.fechaHoraRecepcion);
    final fechaRecepcionFormateada = fechaRecepcion != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRecepcion)
        : correspondencia.fechaHoraRecepcion;

    final fechaEntrega = DateTime.tryParse(correspondencia.fechaHoraEntrega!);
    final fechaEntregaFormateada = fechaEntrega != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaEntrega)
        : correspondencia.fechaHoraEntrega!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => _mostrarDetallesCorrespondencia(correspondencia),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con tipo y estado entregado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTipoColor(correspondencia.tipoCorrespondencia),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'ENTREGADA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
            
            const SizedBox(height: 12),
            
            // Fechas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recibida: $fechaRecepcionFormateada',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Entregada: $fechaEntregaFormateada',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Adjuntos
            if (correspondencia.adjuntos != null && correspondencia.adjuntos!.isNotEmpty) ...[
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
            
            // Firma (si existe)
            if (correspondencia.firma != null && correspondencia.firma!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.draw,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Firmada',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ));
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
        correspondencia: correspondencia,
      ),
    );
  }
}

class _DetalleCorrespondenciaModal extends StatelessWidget {
  final CorrespondenciaModel correspondencia;

  const _DetalleCorrespondenciaModal({
    required this.correspondencia,
  });

  @override
  Widget build(BuildContext context) {
    final fechaRecepcion = DateTime.tryParse(correspondencia.fechaHoraRecepcion);
    final fechaRecepcionFormateada = fechaRecepcion != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRecepcion)
        : correspondencia.fechaHoraRecepcion;

    final fechaEntrega = correspondencia.fechaHoraEntrega != null
        ? DateTime.tryParse(correspondencia.fechaHoraEntrega!)
        : null;
    final fechaEntregaFormateada = fechaEntrega != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaEntrega)
        : correspondencia.fechaHoraEntrega ?? 'No entregada';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getTipoColor(correspondencia.tipoCorrespondencia),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mail,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detalles de Correspondencia',
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de correspondencia
                    _buildDetailRow(
                      'Tipo de Correspondencia',
                      correspondencia.tipoCorrespondencia,
                      Icons.category,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de entrega
                    _buildDetailRow(
                      'Tipo de Entrega',
                      correspondencia.tipoEntrega,
                      _getTipoEntregaIcon(correspondencia.tipoEntrega),
                    ),
                    const SizedBox(height: 16),
                    
                    // Datos de entrega
                    _buildDetailRow(
                      'Datos de Entrega',
                      correspondencia.datosEntrega,
                      Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    
                    // Vivienda de recepción
                    if (correspondencia.viviendaRecepcion != null) ...[
                      _buildDetailRow(
                        'Vivienda de Recepción',
                        correspondencia.viviendaRecepcion!,
                        Icons.home,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Fecha de recepción
                    _buildDetailRow(
                      'Fecha de Recepción',
                      fechaRecepcionFormateada,
                      Icons.schedule,
                    ),
                    const SizedBox(height: 16),
                    
                    // Fecha de entrega
                    if (correspondencia.fechaHoraEntrega != null) ...[
                      _buildDetailRow(
                        'Fecha de Entrega',
                        fechaEntregaFormateada,
                        Icons.check_circle,
                        valueColor: Colors.green.shade600,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Estado
                    _buildDetailRow(
                      'Estado',
                      correspondencia.fechaHoraEntrega != null ? 'Entregada' : 'Pendiente',
                      correspondencia.fechaHoraEntrega != null ? Icons.check_circle : Icons.pending,
                      valueColor: correspondencia.fechaHoraEntrega != null 
                          ? Colors.green.shade600 
                          : Colors.orange.shade600,
                    ),
                    
                    // Adjuntos
                    if (correspondencia.adjuntos != null && correspondencia.adjuntos!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Archivos Adjuntos (${correspondencia.adjuntos!.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...correspondencia.adjuntos!.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (entry.value != null && entry.value.toString().isNotEmpty)
                                IconButton(
                                  onPressed: () => _mostrarImagen(context, entry.value.toString()),
                                  icon: Icon(
                                    Icons.visibility,
                                    color: Colors.blue.shade600,
                                  ),
                                  tooltip: 'Ver imagen',
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    
                    // Información adicional
                    if (correspondencia.infAdicional != null && correspondencia.infAdicional!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.message,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mensajes Adicionales (${correspondencia.infAdicional!.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...correspondencia.infAdicional!.map((mensaje) {
                        final fechaMensaje = DateTime.tryParse(mensaje['fechaHora'] ?? '');
                        final fechaFormateada = fechaMensaje != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(fechaMensaje)
                            : mensaje['fechaHora'] ?? '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mensaje['usuarioId'] ?? 'Usuario',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    fechaFormateada,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mensaje['mensaje'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    
                    // Firma
                    if (correspondencia.firma != null && correspondencia.firma!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.draw,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Firma de Entrega',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(correspondencia.firma!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  void _mostrarImagen(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Imagen Adjunta'),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}