import 'package:comunidad_activa/models/reserva_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';
import 'crear_revision_screen.dart';

class RevisionesUsoScreen extends StatefulWidget {
  final UserModel currentUser;

  const RevisionesUsoScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<RevisionesUsoScreen> createState() => _RevisionesUsoScreenState();
}

class _RevisionesUsoScreenState extends State<RevisionesUsoScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  List<ReservaModel> _reservasSinRevision = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarReservasSinRevision();
  }

  Future<void> _cargarReservasSinRevision() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Usar el método específico para obtener reservas sin revisión
      final reservasSinRevision = await _espaciosComunesService.obtenerReservasSinRevision(
        widget.currentUser.condominioId!,
      );
      
      // Ordenar por fecha de reserva (más antiguas primero)
      reservasSinRevision.sort((a, b) => 
          DateTime.parse(a.fechaHoraReserva).compareTo(DateTime.parse(b.fechaHoraReserva)));
      
      if (mounted) {
        setState(() {
          _reservasSinRevision = reservasSinRevision;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reservas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisiones Pre y Post Uso'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservasSinRevision.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay reservas pendientes de revisión',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las reservas aceptadas sin revisión aparecerán aquí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarReservasSinRevision,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservasSinRevision.length,
                    itemBuilder: (context, index) {
                      final reserva = _reservasSinRevision[index];
                      return _buildReservaCard(reserva);
                    },
                  ),
                ),
    );
  }

  Widget _buildReservaCard(ReservaModel reserva) {
    final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
    final ahora = DateTime.now();
    final yaOcurrio = fechaReserva.isBefore(ahora);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearRevisionScreen(
                currentUser: widget.currentUser,
                reserva: reserva,
              ),
            ),
          );
          
          if (resultado == true) {
            _cargarReservasSinRevision();
          }
        },
        borderRadius: BorderRadius.circular(8),
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
                      color: yaOcurrio ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      yaOcurrio ? 'PENDIENTE REVISIÓN' : 'PROGRAMADA',
                      style: const TextStyle(
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
              
              if (yaOcurrio) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Esta reserva ya ocurrió y requiere revisión post uso',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Indicador de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Toque para crear revisión',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
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