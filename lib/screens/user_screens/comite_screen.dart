import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comite_model.dart';
import '../../services/firestore_service.dart';

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

    // Pantalla principal vacía - solo mostrará el contenido del drawer
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Utiliza el menú lateral para navegar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}