import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'permisos_modal.dart';
import 'gestion_comite_screen.dart';
import 'gestion_trabajadores_screen.dart';

class FuncionesPermisosScreen extends StatefulWidget {
  final String condominioId;
  final UserModel currentUser;
  
  const FuncionesPermisosScreen({
    super.key, 
    required this.condominioId,
    required this.currentUser,
  });

  @override
  State<FuncionesPermisosScreen> createState() => _FuncionesPermisosScreenState();
}

class _FuncionesPermisosScreenState extends State<FuncionesPermisosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  CondominioModel? _condominio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
  }

  Future<void> _loadCondominioData() async {
    try {
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      if (mounted) {
        setState(() {
          _condominio = condominio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openPermissionsModal() {
    if (_condominio != null) {
      showDialog(
        context: context,
        builder: (context) => PermisosModal(
          condominioId: widget.condominioId,
          gestionFunciones: _condominio!.gestionFunciones,
          onPermissionsUpdated: (updatedPermissions) {
            setState(() {
              _condominio = _condominio!.copyWith(gestionFunciones: updatedPermissions);
            });
          },
        ),
      );
    }
  }

  int _getActivePermissionsCount() {
    final permissions = _condominio!.gestionFunciones;
    int count = 0;
    
    if (permissions.correspondencia) count++;
    if (permissions.controlAcceso) count++;
    if (permissions.espaciosComunes) count++;
    if (permissions.multas) count++;
    if (permissions.reclamos) count++;
    if (permissions.publicaciones) count++;
    if (permissions.registroDiario) count++;
    if (permissions.bloqueoVisitas) count++;
    if (permissions.gastosComunes) count++;
    if (permissions.turnosTrabajadores) count++;
    if (permissions.chatEntreRes) count++;
    if (permissions.chatGrupal) count++;
    if (permissions.chatAdministrador) count++;
    if (permissions.chatConserjeria) count++;
    if (permissions.chatPrivado) count++;
    
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funciones y Permisos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Permisos Generales',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configura qué funcionalidades están disponibles en tu condominio',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _openPermissionsModal,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.security,
                                    color: Colors.blue[700],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Configurar Permisos',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gestiona las funcionalidades disponibles',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_getActivePermissionsCount()} de 15 funciones activas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Gestión del Comité Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => GestionComiteScreen(
                               currentUser: widget.currentUser,
                             ),
                           ),
                         );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  color: Colors.orange[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gestión del Comité',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Administrar miembros del comité',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gestión de Trabajadores Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => GestionTrabajadoresScreen(
                               currentUser: widget.currentUser,
                             ),
                           ),
                         );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.work,
                                  color: Colors.purple[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gestión de Trabajadores',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Administrar trabajadores y permisos',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Información',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Los permisos controlan qué funcionalidades están disponibles en el condominio\n'
                            '• Al desactivar una función, esta no aparecerá en los menús de los usuarios\n'
                            '• Los cambios se aplican inmediatamente a todos los usuarios\n'
                            '• Puedes activar o desactivar funciones según las necesidades del condominio',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}