import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';

class PermisosModal extends StatefulWidget {
  final String condominioId;
  final GestionFunciones gestionFunciones;
  final Function(GestionFunciones) onPermissionsUpdated;

  const PermisosModal({
    super.key,
    required this.condominioId,
    required this.gestionFunciones,
    required this.onPermissionsUpdated,
  });

  @override
  State<PermisosModal> createState() => _PermisosModalState();
}

class _PermisosModalState extends State<PermisosModal> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUpdating = false;

  // Definición de las funciones con sus metadatos
  final List<Map<String, dynamic>> _funcionesData = [
    {
      'key': 'correspondencia',
      'title': 'Correspondencia',
      'description': 'Gestión de correspondencia y paquetes',
      'icon': Icons.mail,
      'color': Colors.blue,
    },
    {
      'key': 'controlAcceso',
      'title': 'Control de Acceso',
      'description': 'Registro de ingresos y salidas',
      'icon': Icons.security,
      'color': Colors.green,
    },
    {
      'key': 'gestionEstacionamientos',
      'title': 'Gestión de Estacionamientos',
      'description': 'Administración de estacionamientos y solicitudes',
      'icon': Icons.local_parking,
      'color': Colors.indigo,
    },
    {
      'key': 'espaciosComunes',
      'title': 'Espacios Comunes',
      'description': 'Reserva y gestión de espacios comunes',
      'icon': Icons.meeting_room,
      'color': Colors.teal,
    },
    {
      'key': 'multas',
      'title': 'Multas',
      'description': 'Gestión de multas y sanciones',
      'icon': Icons.gavel,
      'color': Colors.red,
    },
    {
      'key': 'reclamos',
      'title': 'Reclamos',
      'description': 'Sistema de reclamos y sugerencias',
      'icon': Icons.report_problem,
      'color': Colors.orange,
    },
    {
      'key': 'publicaciones',
      'title': 'Publicaciones',
      'description': 'Anuncios y comunicados',
      'icon': Icons.article,
      'color': Colors.purple,
    },
    {
      'key': 'registroDiario',
      'title': 'Registro Diario',
      'description': 'Registro de actividades diarias',
      'icon': Icons.assignment,
      'color': Colors.brown,
    },
    {
      'key': 'bloqueoVisitas',
      'title': 'Bloqueo de Visitas',
      'description': 'Control de acceso de visitantes',
      'icon': Icons.block,
      'color': Colors.deepOrange,
    },
    {
      'key': 'gastosComunes',
      'title': 'Gastos Comunes',
      'description': 'Gestión de gastos del condominio',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
    },
    {
      'key': 'turnosTrabajadores',
      'title': 'Turnos de Trabajadores',
      'description': 'Gestión de horarios de trabajadores',
      'icon': Icons.schedule,
      'color': Colors.indigo,
    },
    {
      'key': 'chatEntreRes',
      'title': 'Chat entre Residentes',
      'description': 'Comunicación entre residentes',
      'icon': Icons.people,
      'color': Colors.cyan,
    },
    {
      'key': 'chatGrupal',
      'title': 'Chat Grupal',
      'description': 'Chat grupal del condominio',
      'icon': Icons.forum,
      'color': Colors.cyan,
    },
    {
      'key': 'chatAdministrador',
      'title': 'Chat con Administrador',
      'description': 'Comunicación con administración',
      'icon': Icons.admin_panel_settings,
      'color': Colors.cyan,
    },
    {
      'key': 'chatConserjeria',
      'title': 'Chat con Conserjería',
      'description': 'Comunicación con conserjería',
      'icon': Icons.support_agent,
      'color': Colors.cyan,
    },
    {
      'key': 'chatPrivado',
      'title': 'Chat Privado',
      'description': 'Mensajes privados entre usuarios',
      'icon': Icons.message,
      'color': Colors.cyan,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  bool _getPermissionValue(String key, GestionFunciones gestionFunciones) {
    switch (key) {
      case 'correspondencia':
        return gestionFunciones.correspondencia;
      case 'controlAcceso':
        return gestionFunciones.controlAcceso;
      case 'gestionEstacionamientos':
        return gestionFunciones.gestionEstacionamientos;
      case 'espaciosComunes':
        return gestionFunciones.espaciosComunes;
      case 'multas':
        return gestionFunciones.multas;
      case 'reclamos':
        return gestionFunciones.reclamos;
      case 'publicaciones':
        return gestionFunciones.publicaciones;
      case 'registroDiario':
        return gestionFunciones.registroDiario;
      case 'bloqueoVisitas':
        return gestionFunciones.bloqueoVisitas;
      case 'gastosComunes':
        return gestionFunciones.gastosComunes;
      case 'turnosTrabajadores':
        return gestionFunciones.turnosTrabajadores;
      case 'chatEntreRes':
        return gestionFunciones.chatEntreRes;
      case 'chatGrupal':
        return gestionFunciones.chatGrupal;
      case 'chatAdministrador':
        return gestionFunciones.chatAdministrador;
      case 'chatConserjeria':
        return gestionFunciones.chatConserjeria;
      case 'chatPrivado':
        return gestionFunciones.chatPrivado;
      default:
        return false;
    }
  }

  Future<void> _updatePermission(String key, bool value) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });

    try {
      final userData = await FirestoreService().getCurrentUserData();
      if (userData?.condominioId == null) {
        throw Exception('No se encontró el condominio del usuario');
      }

      final condominioId = userData!.condominioId!;
      
      // Actualizar el permiso general en el condominio
      bool success = await FirestoreService().updateFuncionEspecifica(
        condominioId,
        key,
        value,
      );

      if (success) {
        // Si es correspondencia, solo desactivar permisos masivamente cuando se desactiva
        if (key == 'correspondencia') {
          if (!value) {
            // Desactivar permisos de correspondencia para todos
            await FirestoreService().desactivarPermisosCorrespondenciaTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosCorrespondenciaComite(condominioId);
          }
        }

        // Manejar permisos de control de acceso - solo desactivar cuando se desactiva
        if (key == 'controlAcceso') {
          if (!value) {
            // Desactivar permisos de control de acceso para todos
            await FirestoreService().desactivarPermisosControlAccesoTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosControlAccesoComite(condominioId);
          }
        }

        // Manejar permisos de gestión de estacionamientos - solo desactivar cuando se desactiva
        if (key == 'gestionEstacionamientos') {
          if (!value) {
            // Desactivar permisos de gestión de estacionamientos para todos
            await FirestoreService().desactivarPermisosGestionEstacionamientosTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosGestionEstacionamientosComite(condominioId);
          }
        }

        // Manejar permisos de espacios comunes - solo desactivar cuando se desactiva
        if (key == 'espaciosComunes') {
          if (!value) {
            // Desactivar permisos de espacios comunes para todos
            await FirestoreService().desactivarPermisosEspaciosComunesTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosEspaciosComunesComite(condominioId);
          }
        }

        // Manejar permisos de gastos comunes - solo desactivar cuando se desactiva
        if (key == 'gastosComunes') {
          if (!value) {
            // Desactivar permisos de gastos comunes para todos
            await FirestoreService().desactivarPermisosGastosComunesTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosGastosComunesComite(condominioId);
          }
        }

        // Manejar permisos de multas - solo desactivar cuando se desactiva
        if (key == 'multas') {
          if (!value) {
            // Desactivar permisos de multas para todos
            await FirestoreService().desactivarPermisosMultasTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosMultasComite(condominioId);
          }
        }

        // Manejar permisos de reclamos - solo desactivar cuando se desactiva
        if (key == 'reclamos') {
          if (!value) {
            // Desactivar permisos de reclamos para todos
            await FirestoreService().desactivarPermisosReclamosTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosReclamosComite(condominioId);
          }
        }

        // Manejar permisos de publicaciones - solo desactivar cuando se desactiva
        if (key == 'publicaciones') {
          if (!value) {
            // Desactivar permisos de publicaciones para todos
            await FirestoreService().desactivarPermisosPublicacionesTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosPublicacionesComite(condominioId);
          }
        }

        // Manejar permisos de registro diario - solo desactivar cuando se desactiva
        if (key == 'registroDiario') {
          if (!value) {
            // Desactivar permisos de registro diario para todos
            await FirestoreService().desactivarPermisosRegistroDiarioTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosRegistroDiarioComite(condominioId);
          }
        }

        // Manejar permisos de bloqueo de visitas - solo desactivar cuando se desactiva
        if (key == 'bloqueoVisitas') {
          if (!value) {
            // Desactivar permisos de bloqueo de visitas para todos
            await FirestoreService().desactivarPermisosBloqueoVisitasTrabajadores(condominioId);
            await FirestoreService().desactivarPermisosBloqueoVisitasComite(condominioId);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                ? 'Función activada correctamente' 
                : 'Función desactivada correctamente',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Error al actualizar la función');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Widget _buildPermisosContent(GestionFunciones gestionFunciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.security,
              color: Colors.blue[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Configurar Permisos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              color: Colors.grey[600],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Activa o desactiva las funcionalidades disponibles en el condominio',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        
        // Lista de permisos
        Expanded(
          child: ListView.builder(
            itemCount: _funcionesData.length,
            itemBuilder: (context, index) {
              final funcion = _funcionesData[index];
              final key = funcion['key'] as String;
              final isActive = _getPermissionValue(key, gestionFunciones);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (funcion['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          funcion['icon'] as IconData,
                          color: funcion['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              funcion['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              funcion['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: isActive,
                        onChanged: _isUpdating 
                            ? null 
                            : (value) => _updatePermission(key, value),
                        activeColor: funcion['color'] as Color,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Footer con información
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Los cambios se aplican inmediatamente a todos los usuarios',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<CondominioModel?>(
          stream: _firestoreService.getCondominioStream(widget.condominioId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar permisos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor, intenta nuevamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Text(
                  'No se encontraron datos del condominio',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final condominio = snapshot.data!;
            return _buildPermisosContent(condominio.gestionFunciones);
          },
        ),
      ),
    );
  }
}