import 'package:comunidad_activa/models/reserva_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';

class SolicitudesReservasScreen extends StatefulWidget {
  final UserModel currentUser;

  const SolicitudesReservasScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SolicitudesReservasScreen> createState() => _SolicitudesReservasScreenState();
}

class _SolicitudesReservasScreenState extends State<SolicitudesReservasScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  List<ReservaModel> _solicitudesPendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudesPendientes();
  }

  Future<void> _cargarSolicitudesPendientes() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final reservas = await _espaciosComunesService.obtenerReservas(
        widget.currentUser.condominioId!,
      );
      
      // Filtrar solo las reservas pendientes
      final solicitudesPendientes = reservas
          .where((reserva) => reserva.estado == 'pendiente')
          .toList();
      
      // Ordenar por fecha de solicitud (más recientes primero)
      solicitudesPendientes.sort((a, b) => 
          DateTime.parse(b.fechaHoraSolicitud).compareTo(DateTime.parse(a.fechaHoraSolicitud)));
      
      if (mounted) {
        setState(() {
          _solicitudesPendientes = solicitudesPendientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar solicitudes: $e')),
        );
      }
    }
  }

  Future<void> _aprobarReserva(ReservaModel reserva) async {
    // Primero verificar horarios ocupados para mostrar información al administrador
    try {
      final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
      final horariosOcupados = await _espaciosComunesService.obtenerHorariosOcupados(
        condominioId: widget.currentUser.condominioId!,
        espacioId: reserva.espacioComunId,
        fecha: fechaReserva,
      );

      // Filtrar horarios que no sean esta misma reserva
      final horariosConflicto = horariosOcupados.where((h) => 
        h['estado'] == 'aprobada' && 
        h['nombreSolicitante'] != reserva.nombreResidente
      ).toList();

      String mensajeConfirmacion = '¿Está seguro de que desea aprobar la reserva del espacio "${reserva.nombreEspacioComun}" para el ${DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva)}?';
      
      if (horariosConflicto.isNotEmpty) {
        mensajeConfirmacion += '\n\n⚠️ ADVERTENCIA: Hay otros horarios ocupados ese día:\n';
        for (final horario in horariosConflicto) {
          mensajeConfirmacion += '• ${horario['horaInicio']} - ${horario['horaFin']} (${horario['nombreSolicitante']})\n';
        }
      }

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aprobar Reserva'),
          content: Text(mensajeConfirmacion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aprobar'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        await _espaciosComunesService.aprobarReserva(
          widget.currentUser.condominioId!,
          reserva.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva aprobada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarSolicitudesPendientes();
        }
      }
    } catch (e) {
      if (mounted) {
        String mensajeError = 'Error al aprobar reserva: $e';
        Color colorError = Colors.red;
        
        // Si el error es por conflicto de horarios, usar un mensaje más claro
        if (e.toString().contains('Ya existe otra reserva aceptada')) {
          mensajeError = 'No se puede aprobar: Ya existe una reserva aceptada para el mismo horario y fecha.';
          colorError = Colors.orange;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: colorError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _rechazarReserva(ReservaModel reserva) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        final motivoController = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Está a punto de rechazar la reserva del espacio "${reserva.nombreEspacioComun}".',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo del rechazo (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(motivoController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );

    if (motivo != null) {
      try {
        await _espaciosComunesService.rechazarReserva(
          widget.currentUser.condominioId!,
          reserva.id,
          motivoRechazo: motivo.isNotEmpty ? motivo : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva rechazada'),
              backgroundColor: Colors.red,
            ),
          );
          _cargarSolicitudesPendientes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al rechazar reserva: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Reservas'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solicitudesPendientes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes pendientes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las nuevas solicitudes aparecerán aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudesPendientes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudesPendientes.length,
                    itemBuilder: (context, index) {
                      final reserva = _solicitudesPendientes[index];
                      return _buildSolicitudCard(reserva);
                    },
                  ),
                ),
    );
  }

  Widget _buildSolicitudCard(ReservaModel reserva) {
    final fechaSolicitud = DateTime.parse(reserva.fechaHoraSolicitud);
    final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con espacio y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    reserva.nombreEspacioComun,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Información de la reserva
            _buildInfoRow(Icons.home, 'Vivienda:', reserva.vivienda),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today, 
              'Fecha y hora:', 
              DateFormat('dd/MM/yyyy HH:mm').format(fechaReserva),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.people, 
              'Participantes:', 
              '${reserva.participantes.length} personas',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time, 
              'Solicitado:', 
              DateFormat('dd/MM/yyyy HH:mm').format(fechaSolicitud),
            ),
            
            // Lista de participantes
            if (reserva.participantes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Participantes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...reserva.participantes.map((participante) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '• $participante',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
            ],
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rechazarReserva(reserva),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobarReserva(reserva),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}