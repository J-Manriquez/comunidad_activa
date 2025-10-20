import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroDiario {
  final String id;
  final String hora;
  final String nombre;
  final String uidUsuario;
  final String tipoUsuario;
  final String comentario;
  final Map<String, dynamic> additionalData;

  RegistroDiario({
    required this.id,
    required this.hora,
    required this.nombre,
    required this.uidUsuario,
    required this.tipoUsuario,
    required this.comentario,
    required this.additionalData,
  });

  // Constructor para crear desde Firestore
  factory RegistroDiario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RegistroDiario(
      id: doc.id,
      hora: data['hora'] ?? '',
      nombre: data['nombre'] ?? '',
      uidUsuario: data['uidUsuario'] ?? '',
      tipoUsuario: data['tipoUsuario'] ?? '',
      comentario: data['comentario'] ?? '',
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  // Constructor para crear desde Map
  factory RegistroDiario.fromMap(Map<String, dynamic> data, String documentId) {
    return RegistroDiario(
      id: documentId,
      hora: data['hora'] ?? '',
      nombre: data['nombre'] ?? '',
      uidUsuario: data['uidUsuario'] ?? '',
      tipoUsuario: data['tipoUsuario'] ?? '',
      comentario: data['comentario'] ?? '',
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hora': hora,
      'nombre': nombre,
      'uidUsuario': uidUsuario,
      'tipoUsuario': tipoUsuario,
      'comentario': comentario,
      'additionalData': additionalData,
    };
  }

  // Método copyWith para crear copias con modificaciones
  RegistroDiario copyWith({
    String? id,
    String? hora,
    String? nombre,
    String? uidUsuario,
    String? tipoUsuario,
    String? comentario,
    Map<String, dynamic>? additionalData,
  }) {
    return RegistroDiario(
      id: id ?? this.id,
      hora: hora ?? this.hora,
      nombre: nombre ?? this.nombre,
      uidUsuario: uidUsuario ?? this.uidUsuario,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      comentario: comentario ?? this.comentario,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'RegistroDiario{id: $id, hora: $hora, nombre: $nombre, uidUsuario: $uidUsuario, tipoUsuario: $tipoUsuario, comentario: $comentario, additionalData: $additionalData}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistroDiario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          hora == other.hora &&
          nombre == other.nombre &&
          uidUsuario == other.uidUsuario &&
          tipoUsuario == other.tipoUsuario &&
          comentario == other.comentario;

  @override
  int get hashCode =>
      id.hashCode ^
      hora.hashCode ^
      nombre.hashCode ^
      uidUsuario.hashCode ^
      tipoUsuario.hashCode ^
      comentario.hashCode;
}