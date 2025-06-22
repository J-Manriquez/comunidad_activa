import 'package:comunidad_activa/screens/admin/gestion_multas_screen.dart';
import 'package:comunidad_activa/screens/admin/historial_multas_screen.dart';
import 'package:flutter/material.dart';
import '../../services/multa_service.dart';
import '../../models/user_model.dart';


class MultasAdminScreen extends StatelessWidget {
  final UserModel currentUser;
  final MultaService _multaService = MultaService();

  MultasAdminScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Multas'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.settings, color: Colors.blue[700]),
                title: const Text('Gestionador de Multas'),
                subtitle: const Text('Configurar tipos y valores de multas'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GestionMultasScreen(
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.history, color: Colors.orange[700]),
                title: const Text('Historial de Multas'),
                subtitle: const Text('Ver todas las multas creadas'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistorialMultasScreen(
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}