import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { administrador, residente, trabajador }

class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final UserType tipoUsuario;
  final String? condominioId;
  final bool? esComite; // Nuevo campo

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.tipoUsuario,
    this.condominioId,
    this.esComite, // Nuevo parámetro
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'tipoUsuario': tipoUsuario.toString().split('.').last,
      'condominioId': condominioId,
      'esComite': esComite, // Incluir en el mapa
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      tipoUsuario: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipoUsuario'],
        orElse: () => UserType.residente,
      ),
      condominioId: map['condominioId'],
      esComite: map['esComite'] ?? false, // Obtener del mapa
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }
}