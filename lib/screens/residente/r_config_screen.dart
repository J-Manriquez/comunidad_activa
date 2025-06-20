import 'package:flutter/material.dart';
import '../../models/residente_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'r_seleccion_vivienda_screen.dart';

class ResidenteConfigScreen extends StatefulWidget {
  final String condominioId;

  const ResidenteConfigScreen({super.key, required this.condominioId});

  @override
  State<ResidenteConfigScreen> createState() => _ResidenteConfigScreenState();
}

class _ResidenteConfigScreenState extends State<ResidenteConfigScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  ResidenteModel? _residente;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _residente == null
              ? const Center(child: Text('No se encontró información del residente'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de Vivienda
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.home, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Vivienda',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: Icon(
                                  _residente!.viviendaSeleccionada != 'no_seleccionada' ? Icons.home : Icons.home_outlined,
                                  color: _residente!.viviendaSeleccionada != 'no_seleccionada' ? Colors.green : Colors.grey,
                                ),
                                title: const Text('Seleccionar Vivienda'),
                                subtitle: Text(
                                  _residente!.viviendaSeleccionada != 'no_seleccionada'
                                      ? 'Actual: ${_residente!.descripcionVivienda}'
                                      : 'No ha seleccionado una vivienda',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResidenteSeleccionViviendaScreen(
                                        condominioId: widget.condominioId,
                                        onViviendaSeleccionada: () {
                                          _loadResidenteData();
                                        },
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
                      
                      // Información Personal
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Información Personal',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoTile('Nombre', _residente!.nombre, Icons.person),
                              _buildInfoTile('Email', _residente!.email, Icons.email),
                              _buildInfoTile('Código', _residente!.codigo, Icons.code),
                              if (_residente!.esComite)
                                _buildInfoTile('Rol', 'Miembro del Comité', Icons.star),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}