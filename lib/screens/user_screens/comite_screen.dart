import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comite_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/test/screen_navigator_widget.dart';

class ComiteScreen extends StatefulWidget {
  final String condominioId;

  const ComiteScreen({super.key, required this.condominioId});

  @override
  State<ComiteScreen> createState() => _ComiteScreenState();
}

class _ComiteScreenState extends State<ComiteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  ComiteModel? _comite;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosComite();
  }

  Future<void> _cargarDatosComite() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Cargar datos del comité
      final comiteDoc = await FirebaseFirestore.instance
          .collection(widget.condominioId)
          .doc('usuarios')
          .collection('comite')
          .doc(user.uid)
          .get();

      if (!comiteDoc.exists) {
        throw Exception('Miembro del comité no encontrado');
      }

      _comite = ComiteModel.fromFirestore(comiteDoc);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
                fontSize: 16,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatosComite,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_comite == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos del comité'),
      );
    }

    // Pantalla principal con widget de navegación
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del comité
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
                          Icons.group,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _comite!.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text('Email: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(child: Text(_comite!.email)),
                      ],
                    ),
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
                        currentUser: UserModel(
                          uid: _comite!.uid,
                          email: _comite!.email,
                          nombre: _comite!.nombre,
                          tipoUsuario: UserType.comite,
                          condominioId: _comite!.condominioId,
                          esComite: true,
                        ),
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