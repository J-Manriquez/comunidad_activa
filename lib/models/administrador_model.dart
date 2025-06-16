import 'package:cloud_firestore/cloud_firestore.dart';

class AdministradorModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String fechaRegistro;

  AdministradorModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.condominioId,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'condominioId': condominioId,
      'fechaRegistro': fechaRegistro,
    };
  }

  factory AdministradorModel.fromMap(Map<String, dynamic> map) {
    return AdministradorModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      condominioId: map['condominioId'] ?? '',
      fechaRegistro: map['fechaRegistro'] ?? '',
    );
  }

  factory AdministradorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdministradorModel.fromMap(data);
  }
}