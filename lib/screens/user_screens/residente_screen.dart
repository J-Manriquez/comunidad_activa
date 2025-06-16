import 'package:flutter/material.dart';

class ResidenteScreen extends StatelessWidget {
  final String condominioId;

  const ResidenteScreen({super.key, required this.condominioId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Pantalla de Residente',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Condominio ID: $condominioId',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Esta pantalla será implementada próximamente',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}