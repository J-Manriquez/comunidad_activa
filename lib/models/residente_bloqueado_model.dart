import 'package:cloud_firestore/cloud_firestore.dart';

class ResidenteBloqueadoModel {
  final String id;
  final String nombre;
  final String correo;
  final String motivo;
  final DateTime fechaHora;

  ResidenteBloqueadoModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.motivo,
    required this.fechaHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'motivo': motivo,
      'fecha-hora': Timestamp.fromDate(fechaHora),
    };
  }

  factory ResidenteBloqueadoModel.fromMap(Map<String, dynamic> map) {
    return ResidenteBloqueadoModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      correo: map['correo'] ?? '',
      motivo: map['motivo'] ?? '',
      fechaHora: (map['fecha-hora'] as Timestamp).toDate(),
    );
  }

  factory ResidenteBloqueadoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResidenteBloqueadoModel.fromMap(data);
  }
}