import 'package:cloud_firestore/cloud_firestore.dart';

class TurnoTrabajador {
  final String id;
  final String hora;
  final String fecha;
  final String estado; // inicio o termino
  final String nombre;
  final String uidUsuario;
  final String tipoTrabajador;

  TurnoTrabajador({
    required this.id,
    required this.hora,
    required this.fecha,
    required this.estado,
    required this.nombre,
    required this.uidUsuario,
    required this.tipoTrabajador,
  });

  // Constructor para crear desde Firestore
  factory TurnoTrabajador.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TurnoTrabajador(
      id: data['id'] ?? '',
      hora: data['hora'] ?? '',
      fecha: data['fecha'] ?? '',
      estado: data['estado'] ?? 'inicio',
      nombre: data['nombre'] ?? '',
      uidUsuario: data['uidUsuario'] ?? '',
      tipoTrabajador: data['tipoTrabajador'] ?? '',
    );
  }

  // Constructor para crear desde Map
  factory TurnoTrabajador.fromMap(Map<String, dynamic> data) {
    return TurnoTrabajador(
      id: data['id'] ?? '',
      hora: data['hora'] ?? '',
      fecha: data['fecha'] ?? '',
      estado: data['estado'] ?? 'inicio',
      nombre: data['nombre'] ?? '',
      uidUsuario: data['uidUsuario'] ?? '',
      tipoTrabajador: data['tipoTrabajador'] ?? '',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hora': hora,
      'fecha': fecha,
      'estado': estado,
      'nombre': nombre,
      'uidUsuario': uidUsuario,
      'tipoTrabajador': tipoTrabajador,
    };
  }

  // Método copyWith para crear copias con modificaciones
  TurnoTrabajador copyWith({
    String? id,
    String? hora,
    String? fecha,
    String? estado,
    String? nombre,
    String? uidUsuario,
    String? tipoTrabajador,
  }) {
    return TurnoTrabajador(
      id: id ?? this.id,
      hora: hora ?? this.hora,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      nombre: nombre ?? this.nombre,
      uidUsuario: uidUsuario ?? this.uidUsuario,
      tipoTrabajador: tipoTrabajador ?? this.tipoTrabajador,
    );
  }

  @override
  String toString() {
    return 'TurnoTrabajador(id: $id, hora: $hora, fecha: $fecha, estado: $estado, nombre: $nombre, uidUsuario: $uidUsuario, tipoTrabajador: $tipoTrabajador)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnoTrabajador &&
        other.id == id &&
        other.hora == hora &&
        other.fecha == fecha &&
        other.estado == estado &&
        other.nombre == nombre &&
        other.uidUsuario == uidUsuario &&
        other.tipoTrabajador == tipoTrabajador;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        hora.hashCode ^
        fecha.hashCode ^
        estado.hashCode ^
        nombre.hashCode ^
        uidUsuario.hashCode ^
        tipoTrabajador.hashCode;
  }
}