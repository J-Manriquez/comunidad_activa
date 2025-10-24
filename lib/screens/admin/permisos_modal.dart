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
  late GestionFunciones _currentPermissions;
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
    _currentPermissions = widget.gestionFunciones;
  }

  bool _getPermissionValue(String key) {
    switch (key) {
      case 'correspondencia':
        return _currentPermissions.correspondencia;
      case 'controlAcceso':
        return _currentPermissions.controlAcceso;
      case 'espaciosComunes':
        return _currentPermissions.espaciosComunes;
      case 'multas':
        return _currentPermissions.multas;
      case 'reclamos':
        return _currentPermissions.reclamos;
      case 'publicaciones':
        return _currentPermissions.publicaciones;
      case 'registroDiario':
        return _currentPermissions.registroDiario;
      case 'bloqueoVisitas':
        return _currentPermissions.bloqueoVisitas;
      case 'gastosComunes':
        return _currentPermissions.gastosComunes;
      case 'turnosTrabajadores':
        return _currentPermissions.turnosTrabajadores;
      case 'chatEntreRes':
        return _currentPermissions.chatEntreRes;
      case 'chatGrupal':
        return _currentPermissions.chatGrupal;
      case 'chatAdministrador':
        return _currentPermissions.chatAdministrador;
      case 'chatConserjeria':
        return _currentPermissions.chatConserjeria;
      case 'chatPrivado':
        return _currentPermissions.chatPrivado;
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
      // Actualizar el permiso específico en Firestore
      await _firestoreService.updateFuncionEspecifica(
        widget.condominioId,
        key,
        value,
      );

      // Actualizar el estado local
      setState(() {
        _currentPermissions = _updatePermissionInModel(key, value);
      });

      // Notificar al widget padre
      widget.onPermissionsUpdated(_currentPermissions);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'Función activada correctamente'
                  : 'Función desactivada correctamente',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar permiso: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  GestionFunciones _updatePermissionInModel(String key, bool value) {
    switch (key) {
      case 'correspondencia':
        return _currentPermissions.copyWith(correspondencia: value);
      case 'controlAcceso':
        return _currentPermissions.copyWith(controlAcceso: value);
      case 'espaciosComunes':
        return _currentPermissions.copyWith(espaciosComunes: value);
      case 'multas':
        return _currentPermissions.copyWith(multas: value);
      case 'reclamos':
        return _currentPermissions.copyWith(reclamos: value);
      case 'publicaciones':
        return _currentPermissions.copyWith(publicaciones: value);
      case 'registroDiario':
        return _currentPermissions.copyWith(registroDiario: value);
      case 'bloqueoVisitas':
        return _currentPermissions.copyWith(bloqueoVisitas: value);
      case 'gastosComunes':
        return _currentPermissions.copyWith(gastosComunes: value);
      case 'turnosTrabajadores':
        return _currentPermissions.copyWith(turnosTrabajadores: value);
      case 'chatEntreRes':
        return _currentPermissions.copyWith(chatEntreRes: value);
      case 'chatGrupal':
        return _currentPermissions.copyWith(chatGrupal: value);
      case 'chatAdministrador':
        return _currentPermissions.copyWith(chatAdministrador: value);
      case 'chatConserjeria':
        return _currentPermissions.copyWith(chatConserjeria: value);
      case 'chatPrivado':
        return _currentPermissions.copyWith(chatPrivado: value);
      default:
        return _currentPermissions;
    }
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
        child: Column(
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
                  final isActive = _getPermissionValue(key);
                  
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
        ),
      ),
    );
  }
}