import 'package:cloud_firestore/cloud_firestore.dart';

class ResidenteModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String codigo;
  final bool esComite;
  final String fechaRegistro;

  ResidenteModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.condominioId,
    required this.codigo,
    required this.esComite,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'condominioId': condominioId,
      'codigo': codigo,
      'esComite': esComite,
      'fechaRegistro': fechaRegistro,
    };
  }

  factory ResidenteModel.fromMap(Map<String, dynamic> map) {
    return ResidenteModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      condominioId: map['condominioId'] ?? '',
      codigo: map['codigo'] ?? '',
      esComite: map['esComite'] ?? false,
      fechaRegistro: map['fechaRegistro'] ?? '',
    );
  }

  factory ResidenteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResidenteModel.fromMap(data);
  }
}