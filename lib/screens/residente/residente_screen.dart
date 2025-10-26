import 'package:comunidad_activa/screens/residente/correspondencia/correspondencias_residente_screen.dart';
import 'package:comunidad_activa/screens/residente/r_seleccion_vivienda_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/residente_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_card_widget.dart';
import '../../widgets/modal_confirmacion_entrega_residente.dart';
import '../../widgets/test/screen_navigator_widget.dart';
import '../../models/correspondencia_config_model.dart';
import '../../services/correspondencia_service.dart';
import 'comunicaciones/r_notifications_screen.dart';
import 'r_config_screen.dart';
import 'gastos_comunes_residente_screen.dart';
import 'estacionamientos_residente_screen.dart';
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
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
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

                              _buildCorrespondenciasTile(),
                              const SizedBox(height: 8),
                              _buildActionTile(
                                'Estacionamientos',
                                'Gestionar estacionamientos y solicitudes',
                                Icons.local_parking,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EstacionamientosResidenteScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
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

                      const SizedBox(height: 16),

                      // Widget de navegación de pantallas
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Navegación de pantallas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 400,
                                child: ScreenNavigatorWidget(
                                  currentUser: _residente!.toUserModel(),
                                ),
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
  
  Widget _buildCorrespondenciasTile() {
    final user = _authService.currentUser;
    if (user == null) {
      return _buildActionTile(
        'Correspondencias',
        'Ver y gestionar correspondencias',
        Icons.mail,
        () => _handleCorrespondenciasNavigation(),
      );
    }
    
    return StreamBuilder(
      stream: _notificationService.getEntregaNotificationsStream(
        condominioId: widget.condominioId,
        userId: user.uid,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildActionTile(
            'Correspondencias',
            'Ver y gestionar correspondencias',
            Icons.mail,
            () => _handleCorrespondenciasNavigation(),
          );
        }
        
        final notifications = snapshot.data!;
        
        // Verificar notificaciones de entrega pendientes y no expiradas
        final hasEntregaNotifications = notifications.any((notification) {
          if (notification.notificationType == 'confirmacion_entrega' &&
              notification.isRead == null &&
              (notification.additionalData?['estado'] == null || 
               notification.additionalData?['estado'] == 'pendiente')) {
            // Verificar si la notificación no ha expirado
            return !_esNotificacionSistemaExpirada(notification);
          }
          return false;
        });
        
        // También verificar correspondencias con notificaciones pendientes usando FutureBuilder interno
        return FutureBuilder<bool>(
          future: _checkCorrespondenciasConNotificacionesPendientes(),
          builder: (context, futureSnapshot) {
            final hasCorrespondenciasConNotificaciones = futureSnapshot.data ?? false;
            final hasAnyNotifications = hasEntregaNotifications || hasCorrespondenciasConNotificaciones;
        
            return Container(
              decoration: hasAnyNotifications
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                      color: Colors.red.shade50,
                    )
                  : null,
              child: ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      Icons.mail,
                      color: hasAnyNotifications
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                    ),
                    if (hasAnyNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  'Correspondencias',
                  style: TextStyle(
                    fontWeight: hasAnyNotifications
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: hasAnyNotifications
                        ? Colors.red.shade700
                        : null,
                  ),
                ),
                subtitle: Text(
                  hasAnyNotifications
                      ? 'Tienes entregas pendientes de confirmar'
                      : 'Ver y gestionar correspondencias',
                  style: TextStyle(
                    color: hasAnyNotifications
                        ? Colors.red.shade600
                        : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAnyNotifications)
                      Icon(
                        Icons.notification_important,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () => _handleCorrespondenciasNavigation(),
              ),
            );
           },
         );
       },
    );
  }
  
  Future<void> _handleCorrespondenciasNavigation() async {
    try {
      // Verificar si hay notificaciones de entrega de correspondencia pendientes
      final user = _authService.currentUser;
      if (user == null || _residente == null) {
        _navigateToCorrespondencias();
        return;
      }
      
      // Buscar notificaciones de confirmación de entrega para este residente
      final notifications = await _notificationService.getNotificationsForUser(
        user.uid,
        widget.condominioId,
      );
      
      // Filtrar notificaciones de entrega de correspondencia no leídas, pendientes y no expiradas
      final entregaNotifications = notifications.where((notification) {
        if (notification.notificationType == 'confirmacion_entrega' &&
            notification.isRead == null &&
            (notification.additionalData?['estado'] == null || 
             notification.additionalData?['estado'] == 'pendiente')) {
          // Verificar si la notificación no ha expirado
          return !_esNotificacionSistemaExpirada(notification);
        }
        return false;
      }).toList();
      
      if (entregaNotifications.isNotEmpty) {
        // Si hay notificaciones de entrega, mostrar el modal
        final notification = entregaNotifications.first;
        await _showEntregaModal(notification);
      } else {
        // Si no hay notificaciones, navegar directamente a la pantalla
        _navigateToCorrespondencias();
      }
    } catch (e) {
      print('Error al verificar notificaciones de entrega: $e');
      // En caso de error, navegar directamente a la pantalla
      _navigateToCorrespondencias();
    }
  }
  
  void _navigateToCorrespondencias() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CorrespondenciasResidenteScreen(
          condominioId: widget.condominioId,
        ),
      ),
    );
  }
  
  Future<void> _showEntregaModal(dynamic notification) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        _navigateToCorrespondencias();
        return;
      }
      
      // Mostrar el modal de confirmación para residentes
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ModalConfirmacionEntregaResidente(
          notification: notification,
          userId: user.uid,
          condominioId: widget.condominioId,
        ),
      );
      
      // Marcar la notificación como leída
      await _notificationService.markNotificationAsRead(
         condominioId: widget.condominioId,
         notificationId: notification.id,
         userId: user.uid,
         userType: 'residentes',
       );
    } catch (e) {
      print('Error al mostrar modal de entrega: $e');
      _navigateToCorrespondencias();
    }
  }
  
  /// Verifica si hay correspondencias con notificaciones de entrega pendientes
  Future<bool> _checkCorrespondenciasConNotificacionesPendientes() async {
    try {
      if (_residente == null) return false;
      
      final correspondenciasSnapshot = await FirebaseFirestore.instance
          .collection(widget.condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .where('viviendaRecepcion', isEqualTo: _residente!.descripcionVivienda)
          .get();
      
      for (final doc in correspondenciasSnapshot.docs) {
        final data = doc.data();
        final notificacionEntrega = data['notificacionEntrega'] as Map<String, dynamic>? ?? {};
        
        // Verificar si hay alguna notificación pendiente y no expirada
        for (final entry in notificacionEntrega.entries) {
          final notifData = entry.value as Map<String, dynamic>;
          if (notifData['respuesta'] == 'pendiente') {
            // Verificar si la notificación no ha expirado
            if (!_esNotificacionExpirada(entry.key, notifData)) {
              return true; // Hay al menos una notificación pendiente y activa
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error al verificar correspondencias con notificaciones pendientes: $e');
      return false;
    }
  }
  
  /// Verifica si una notificación ha expirado (más de 5 minutos)
  bool _esNotificacionExpirada(String timestamp, Map<String, dynamic> notifData) {
    try {
      // Si tiene fechaRespuesta, verificar expiración desde esa fecha
      String? fechaParaVerificar;
      if (notifData['fechaRespuesta'] != null) {
        fechaParaVerificar = notifData['fechaRespuesta'];
      } else {
        // Si no tiene respuesta, verificar desde fechaEnvio
        fechaParaVerificar = notifData['fechaEnvio'];
      }
      
      if (fechaParaVerificar == null) return false;
      
      // Parsear el timestamp en formato: DD-MM-YYYY-HH-MM-SS
      final parts = fechaParaVerificar.split('-');
      if (parts.length != 6) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final hour = int.parse(parts[3]);
      final minute = int.parse(parts[4]);
      final second = int.parse(parts[5]);
      
      final fechaReferencia = DateTime(year, month, day, hour, minute, second);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaReferencia);
      
      // Considerar expirada si han pasado más de 5 minutos
      return diferencia.inMinutes > 5;
    } catch (e) {
      print('Error al parsear timestamp $timestamp: $e');
      return false;
    }
  }
  
  /// Verifica si una notificación del sistema ha expirado (más de 5 minutos)
  bool _esNotificacionSistemaExpirada(dynamic notification) {
    try {
      // Verificar si tiene mostrarHasta en additionalData
      final mostrarHasta = notification.additionalData?['mostrarHasta'];
      if (mostrarHasta != null) {
        final fechaLimite = DateTime.parse(mostrarHasta);
        return DateTime.now().isAfter(fechaLimite);
      }
      
      // Si no tiene mostrarHasta, verificar por fechaRegistro (5 minutos)
      final fechaRegistro = DateTime.parse(notification.fechaRegistro);
      final diferencia = DateTime.now().difference(fechaRegistro);
      return diferencia.inMinutes > 5;
    } catch (e) {
      print('Error al verificar expiración de notificación del sistema: $e');
      return false;
    }
  }
}
