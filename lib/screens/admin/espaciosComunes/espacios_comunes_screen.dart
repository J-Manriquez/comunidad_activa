import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';
import 'lista_espacios_comunes_screen.dart';
import 'solicitudes_reservas_screen.dart';
import 'revisiones_post_uso_screen.dart';
import 'historial_revisiones_screen.dart';
import 'solicitudes_rechazadas_screen.dart';

class EspaciosComunesScreen extends StatefulWidget {
  final UserModel currentUser;

  const EspaciosComunesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<EspaciosComunesScreen> createState() => _EspaciosComunesScreenState();
}

class _EspaciosComunesScreenState extends State<EspaciosComunesScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  int _solicitudesPendientesCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _cargarContadorSolicitudesPendientes();
  }

  Future<void> _cargarContadorSolicitudesPendientes() async {
    try {
      final reservas = await _espaciosComunesService.obtenerReservas(
        widget.currentUser.condominioId!,
      );
      
      final solicitudesPendientes = reservas
          .where((reserva) => reserva.estado == 'pendiente')
          .length;
      
      if (mounted) {
        setState(() {
          _solicitudesPendientesCount = solicitudesPendientes;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios Comunes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card para gestión de espacios comunes
            _buildNavigationCard(
              context,
              title: 'Gestión de Espacios Comunes',
              subtitle: 'Crear, editar y eliminar espacios comunes',
              icon: Icons.business,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListaEspaciosComunesScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Card para solicitudes de reservas
            _buildNavigationCardWithCounter(
              context,
              title: 'Solicitudes de Reservas',
              subtitle: 'Aprobar o rechazar reservas de espacios comunes',
              icon: Icons.event_available,
              color: Colors.orange,
              counter: _solicitudesPendientesCount,
              isLoadingCounter: _isLoadingCount,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SolicitudesReservasScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
                // Recargar contador al regresar
                if (result != null || mounted) {
                  _cargarContadorSolicitudesPendientes();
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Card para revisiones pre y post uso
            _buildNavigationCard(
              context,
              title: 'Revisiones Pre y Post Uso',
              subtitle: 'Realizar revisiones antes o después del uso de espacios',
              icon: Icons.rate_review,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RevisionesUsoScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Card para solicitudes rechazadas
            _buildNavigationCard(
              context,
              title: 'Solicitudes Rechazadas',
              subtitle: 'Ver reservas que han sido rechazadas',
              icon: Icons.cancel,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SolicitudesRechazadasScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Card para historial de revisiones
            _buildNavigationCard(
              context,
              title: 'Historial de Revisiones',
              subtitle: 'Ver todas las revisiones realizadas',
              icon: Icons.history,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistorialRevisionesScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCardWithCounter(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int counter,
    required bool isLoadingCounter,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isLoadingCounter)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else if (counter > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              counter.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}