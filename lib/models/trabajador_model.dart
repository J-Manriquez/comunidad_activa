import 'package:cloud_firestore/cloud_firestore.dart';

class TrabajadorModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String codigo;
  final String tipoTrabajador;
  final String? cargoEspecifico;
  final String fechaRegistro;

  TrabajadorModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.condominioId,
    required this.codigo,
    required this.tipoTrabajador,
    this.cargoEspecifico,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'condominioId': condominioId,
      'codigo': codigo,
      'tipoTrabajador': tipoTrabajador,
      'cargoEspecifico': cargoEspecifico,
      'fechaRegistro': fechaRegistro,
    };
  }

  factory TrabajadorModel.fromMap(Map<String, dynamic> map) {
    return TrabajadorModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      condominioId: map['condominioId'] ?? '',
      codigo: map['codigo'] ?? '',
      tipoTrabajador: map['tipoTrabajador'] ?? '',
      cargoEspecifico: map['cargoEspecifico'],
      fechaRegistro: map['fechaRegistro'] ?? '',
    );
  }

  factory TrabajadorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TrabajadorModel.fromMap(data);
  }
}