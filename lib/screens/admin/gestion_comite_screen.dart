import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/comite_model.dart';
import '../../services/firestore_service.dart';
import 'configuracion_permisos_comite_screen.dart';

class GestionComiteScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionComiteScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<GestionComiteScreen> createState() => _GestionComiteScreenState();
}

class _GestionComiteScreenState extends State<GestionComiteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ComiteModel> _miembrosComite = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarMiembrosComite();
  }

  Future<void> _cargarMiembrosComite() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Obtener todos los miembros del comité del condominio
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(widget.currentUser.condominioId!)
          .doc('usuarios')
          .collection('comite')
          .get();

      List<ComiteModel> miembrosComite = [];
      for (var doc in querySnapshot.docs) {
        if (doc.id != '_placeholder') {
          try {
            miembrosComite.add(ComiteModel.fromFirestore(doc));
          } catch (e) {
            print('Error al procesar miembro del comité ${doc.id}: $e');
          }
        }
      }

      setState(() {
        _miembrosComite = miembrosComite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar miembros del comité: $e';
        _isLoading = false;
      });
    }
  }

  Color _getColorPorDefecto() {
    return Colors.purple;
  }

  IconData _getIconoPorDefecto() {
    return Icons.group;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión del Comité'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarMiembrosComite,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _miembrosComite.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay miembros del comité registrados',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los miembros del comité aparecerán aquí cuando se registren',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarMiembrosComite,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _miembrosComite.length,
                          itemBuilder: (context, index) {
                            final miembro = _miembrosComite[index];
                            return _buildMiembroComiteCard(miembro);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildMiembroComiteCard(ComiteModel miembro) {
    final color = _getColorPorDefecto();
    final icono = _getIconoPorDefecto();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navegar a la pantalla de configuración de permisos
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracionPermisosComiteScreen(
                currentUser: widget.currentUser,
                miembroComite: miembro,
              ),
            ),
          );
          
          // Si se realizaron cambios, recargar la lista
          if (result == true) {
            _cargarMiembrosComite();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con icono del comité
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Información del miembro del comité
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      miembro.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      miembro.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chip con el rol de comité
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Miembro del Comité',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de funciones activas
              Column(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${miembro.funcionesDisponibles.values.where((v) => v).length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'funciones',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}