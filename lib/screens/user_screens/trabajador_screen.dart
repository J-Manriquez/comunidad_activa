import 'package:flutter/material.dart';

class TrabajadorScreen extends StatelessWidget {
  final String condominioId;

  const TrabajadorScreen({super.key, required this.condominioId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Pantalla de Trabajador',
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