import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'ingresar_correspondencia_screen.dart';
import 'configuracion_correspondencia_screen.dart';
import 'correspondencias_activas_screen.dart';
import 'historial_correspondencias_screen.dart';

class CorrespondenciasScreen extends StatelessWidget {
  final UserModel currentUser;

  const CorrespondenciasScreen({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondencias'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IngresarCorrespondenciaScreen(
                    condominioId: currentUser.condominioId!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card de configuración (solo visible para administradores)
            if (currentUser.tipoUsuario == UserType.administrador) ...[
              Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Colors.blue.shade600,
                    size: 32,
                  ),
                  title: const Text(
                    'Configuración de Correspondencias',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Gestionar configuraciones del sistema de correspondencias',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfiguracionCorrespondenciaScreen(
                          condominioId: currentUser.condominioId!,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Cards para correspondencias activas e historial
            Expanded(
              child: Column(
                children: [
                  // Card de correspondencias activas
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CorrespondenciasActivasScreen(
                                condominioId: currentUser.condominioId!,
                                currentUser: currentUser,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mail,
                                size: 64,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Correspondencias Activas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ver correspondencias pendientes de entrega',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Card de historial de correspondencias
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistorialCorrespondenciasScreen(
                                condominioId: currentUser.condominioId!,
                                currentUser: currentUser,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Historial de Correspondencias',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ver correspondencias ya entregadas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}