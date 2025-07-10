import 'package:comunidad_activa/models/reserva_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';

class SolicitudesRechazadasScreen extends StatefulWidget {
  final UserModel currentUser;

  const SolicitudesRechazadasScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SolicitudesRechazadasScreen> createState() => _SolicitudesRechazadasScreenState();
}

class _SolicitudesRechazadasScreenState extends State<SolicitudesRechazadasScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  Map<String, List<ReservaModel>> _solicitudesPorMes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudesRechazadas();
  }

  Future<void> _cargarSolicitudesRechazadas() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final reservas = await _espaciosComunesService.obtenerReservas(
        widget.currentUser.condominioId!,
      );
      
      // Filtrar solo las reservas rechazadas
      final solicitudesRechazadas = reservas
          .where((reserva) => reserva.estado == 'rechazado')
          .toList();
      
      // Agrupar por mes-año basado en la fecha de solicitud
      final Map<String, List<ReservaModel>> agrupadas = {};
      
      for (final reserva in solicitudesRechazadas) {
        final fechaSolicitud = DateTime.parse(reserva.fechaHoraSolicitud);
        final mesAno = DateFormat('MMMM yyyy', 'es').format(fechaSolicitud);
        
        if (!agrupadas.containsKey(mesAno)) {
          agrupadas[mesAno] = [];
        }
        agrupadas[mesAno]!.add(reserva);
      }
      
      // Ordenar cada grupo por fecha de solicitud (más recientes primero)
      agrupadas.forEach((key, value) {
        value.sort((a, b) => 
            DateTime.parse(b.fechaHoraSolicitud).compareTo(DateTime.parse(a.fechaHoraSolicitud)));
      });
      
      if (mounted) {
        setState(() {
          _solicitudesPorMes = agrupadas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar solicitudes rechazadas: $e')),
        );
      }
    }
  }

  void _mostrarDetalleSolicitud(ReservaModel reserva) {
    showDialog(
      context: context,
      builder: (context) => _DetalleSolicitudDialog(reserva: reserva),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Rechazadas'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudesPorMes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes rechazadas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudesRechazadas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudesPorMes.keys.length,
                    itemBuilder: (context, index) {
                      final mesAno = _solicitudesPorMes.keys.elementAt(index);
                      final solicitudes = _solicitudesPorMes[mesAno]!;
                      return _buildMesSection(mesAno, solicitudes);
                    },
                  ),
                ),
    );
  }

  Widget _buildMesSection(String mesAno, List<ReservaModel> solicitudes) {
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
              color: Colors.red.shade600,
            ),
          ),
        ),
        ...solicitudes.map((reserva) => _buildSolicitudCard(reserva)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSolicitudCard(ReservaModel reserva) {
    final fechaSolicitud = DateTime.parse(reserva.fechaHoraSolicitud);
    final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleSolicitud(reserva),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'RECHAZADO',
                      style: TextStyle(
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
                'Fecha solicitada: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rechazado el: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaSolicitud)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[600],
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleSolicitudDialog extends StatelessWidget {
  final ReservaModel reserva;

  const _DetalleSolicitudDialog({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fechaSolicitud = DateTime.parse(reserva.fechaHoraSolicitud);
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
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Solicitud Rechazada',
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
                    // Información básica
                    _buildInfoSection('Información de la Solicitud', [
                      _buildInfoRow('Espacio:', reserva.nombreEspacioComun),
                      _buildInfoRow('Vivienda:', reserva.vivienda),
                      _buildInfoRow('Fecha solicitada:', DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva)),
                      _buildInfoRow('Fecha de solicitud:', DateFormat('dd/MM/yyyy HH:mm').format(fechaSolicitud)),
                      _buildInfoRow('Participantes:', '${reserva.participantes.length} personas'),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de participantes
                    if (reserva.participantes.isNotEmpty) ...[
                      const Text(
                        'Lista de Participantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reserva.participantes.map((participante) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              participante,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                    
                    // Estado de rechazo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Solicitud Rechazada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Esta solicitud de reserva fue rechazada por el administrador.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
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
            width: 120,
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
}