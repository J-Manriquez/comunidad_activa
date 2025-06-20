import 'package:comunidad_activa/screens/residente/r_seleccion_vivienda_screen.dart';
import 'package:flutter/material.dart';
import '../../models/residente_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_card_widget.dart';
import 'residente_notifications_screen.dart';
import 'r_config_screen.dart';
import '../home_screen.dart';

class ResidenteScreen extends StatefulWidget {
  final String condominioId;

  const ResidenteScreen({super.key, required this.condominioId});

  @override
  State<ResidenteScreen> createState() => _ResidenteScreenState();
}

class _ResidenteScreenState extends State<ResidenteScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  ResidenteModel? _residente;
  bool _isLoading = true;
  bool _modalShown = false; // Para evitar mostrar el modal múltiples veces

  @override
  void initState() {
    super.initState();
    _loadResidenteData();
  }

  Future<void> _loadResidenteData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        if (mounted) {
          setState(() {
            _residente = residente;
            _isLoading = false;
          });

          // Mostrar modal si no ha seleccionado vivienda
          _checkAndShowModal(residente);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkAndShowModal(ResidenteModel? residente) {
    if (residente != null &&
        residente.viviendaSeleccionada == 'no_seleccionada' &&
        !_modalShown) {
      _modalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarModalSeleccionVivienda();
      });
    }
  }

  void _mostrarModalSeleccionVivienda() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.home, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('Seleccionar Vivienda'),
              ],
            ),
            content: const Text(
              'Debe seleccionar su vivienda para continuar usando la aplicación.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(
                    context,
                    '/residente/seleccion-vivienda',
                    arguments: {
                      'condominioId': widget.condominioId,
                      'residente': _residente,
                    },
                  ).then((_) {
                    // Reset modal flag cuando regrese de la selección
                    _modalShown = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Seleccionar Vivienda'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResidenteContent(ResidenteModel residente) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenido principal
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _residente == null
              ? const Center(
                  child: Text('No se encontró información del residente'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card de notificaciones
                      StreamBuilder<int>(
                        stream: _notificationService
                            .getUnreadUserNotificationsCount(
                              condominioId: widget.condominioId,
                              userId: _authService.currentUser!.uid,
                              userType: 'residentes',
                            ),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return NotificationCardWidget(
                            unreadCount: unreadCount,
                            title: 'Mis Notificaciones',
                            color: Colors.green.shade600,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ResidenteNotificationsScreen(
                                        condominioId: widget.condominioId,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Información del residente
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.green.shade600,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _residente!.nombre,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Email',
                                _residente!.email,
                                Icons.email,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Vivienda',
                                _residente!.descripcionVivienda,
                                Icons.home,
                              ),
                              if (_residente!.esComite) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.blue.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Miembro del Comité',
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Acciones rápidas
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Acciones Rápidas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionTile(
                                'Configuración',
                                'Gestionar configuración personal',
                                Icons.settings,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ResidenteConfigScreen(
                                            condominioId: widget.condominioId,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

          // StreamBuilder para escuchar cambios en tiempo real
          StreamBuilder<ResidenteModel?>(
            stream: _firestoreService.getResidenteStream(
              _authService.currentUser!.uid,
              // widget.condominioId,
            ),
            builder: (context, snapshot) {
              print(
                '🔄 StreamBuilder - Estado del snapshot: ${snapshot.connectionState}',
              );

              if (snapshot.hasData) {
                final residenteActual = snapshot.data;
                print(
                  '👤 Datos del residente en stream: ${residenteActual?.viviendaSeleccionada}',
                );

                if (residenteActual != null) {
                  // Actualizar el estado local
                  if (_residente?.viviendaSeleccionada !=
                      residenteActual.viviendaSeleccionada) {
                    print(
                      '🔄 Cambio detectado en viviendaSeleccionada: ${_residente?.viviendaSeleccionada} -> ${residenteActual.viviendaSeleccionada}',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _residente = residenteActual;
                        });
                      }
                    });
                  }

                  // Cerrar modal si está abierto y ya no es necesario
                  if (residenteActual.viviendaSeleccionada !=
                      'no_seleccionada') {
                    print(
                      '✅ Vivienda seleccionada, verificando si hay modal abierto',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (Navigator.canPop(context)) {
                        print('🚪 Cerrando modal de selección de vivienda');
                        Navigator.pop(context);
                      }
                    });
                  }
                }
              }

              if (snapshot.hasError) {
                print('❌ Error en StreamBuilder: ${snapshot.error}');
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return Scaffold(
      body: StreamBuilder<ResidenteModel?>(
        stream: _firestoreService.getResidenteStream(
          user.uid,
          // widget.condominioId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _residente == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final residente = snapshot.data;
          if (residente == null) {
            return const Center(
              child: Text('No se encontraron datos del residente'),
            );
          }

          // Actualizar el residente local
          if (_residente?.viviendaSeleccionada !=
              residente.viviendaSeleccionada) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _residente = residente;
                _modalShown =
                    false; // Reset para permitir mostrar el modal nuevamente
              });
              _checkAndShowModal(residente);
            });
          }

          return _buildResidenteContent(residente);
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
