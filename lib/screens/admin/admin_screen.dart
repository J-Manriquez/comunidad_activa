import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_card_widget.dart';
import 'comunicaciones/admin_notifications_screen.dart';

class AdminScreen extends StatefulWidget {
  final String condominioId;

  const AdminScreen({super.key, required this.condominioId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  CondominioModel? _condominio;
  int _residentes = 0;
  int _comite = 0;
  int _trabajadores = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
  }

  Future<void> _loadCondominioData() async {
    try {
      // Obtener datos del condominio
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      
      // Obtener conteos de usuarios
      final residentes = await _firestoreService.getResidentesCount(widget.condominioId);
      final comite = await _firestoreService.getComiteCount(widget.condominioId);
      final trabajadores = await _firestoreService.getTrabajadoresCount(widget.condominioId);
      
      if (mounted) {
        setState(() {
          _condominio = condominio;
          _residentes = residentes;
          _comite = comite;
          _trabajadores = trabajadores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_condominio == null) {
      return const Center(child: Text('No se encontró información del condominio'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de notificaciones
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCondominioNotificationsCount(widget.condominioId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return NotificationCardWidget(
                unreadCount: unreadCount,
                title: 'Notificaciones del Condominio',
                color: Colors.orange.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminNotificationsScreen(
                        condominioId: widget.condominioId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Información del condominio
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _condominio!.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dirección: ${_condominio!.direccion}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Código de registro:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.condominioId,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(widget.condominioId),
                        tooltip: 'Copiar código',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comparte este código con los residentes y trabajadores para que puedan registrarse.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas de usuarios
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas de usuarios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticTile('Residentes', _residentes, Icons.people),
                  const Divider(),
                  _buildStatisticTile('Comité', _comite, Icons.group),
                  const Divider(),
                  _buildStatisticTile('Trabajadores', _trabajadores, Icons.work),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticTile(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}