import 'package:cloud_firestore/cloud_firestore.dart';

class TurnoDefinido {
  final String id;
  final String tipoTrabajador;
  final String tipoTurno; // semana, fin de semana, toda la semana
  final String horaInicio;
  final String horaTermino;

  TurnoDefinido({
    required this.id,
    required this.tipoTrabajador,
    required this.tipoTurno,
    required this.horaInicio,
    required this.horaTermino,
  });

  // Constructor para crear desde Firestore
  factory TurnoDefinido.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TurnoDefinido(
      id: data['id'] ?? '',
      tipoTrabajador: data['tipoTrabajador'] ?? '',
      tipoTurno: data['tipoTurno'] ?? '',
      horaInicio: data['horaInicio'] ?? '',
      horaTermino: data['horaTermino'] ?? '',
    );
  }

  // Constructor para crear desde Map
  factory TurnoDefinido.fromMap(Map<String, dynamic> data) {
    return TurnoDefinido(
      id: data['id'] ?? '',
      tipoTrabajador: data['tipoTrabajador'] ?? '',
      tipoTurno: data['tipoTurno'] ?? '',
      horaInicio: data['horaInicio'] ?? '',
      horaTermino: data['horaTermino'] ?? '',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoTrabajador': tipoTrabajador,
      'tipoTurno': tipoTurno,
      'horaInicio': horaInicio,
      'horaTermino': horaTermino,
    };
  }

  // Método copyWith para crear copias con modificaciones
  TurnoDefinido copyWith({
    String? id,
    String? tipoTrabajador,
    String? tipoTurno,
    String? horaInicio,
    String? horaTermino,
  }) {
    return TurnoDefinido(
      id: id ?? this.id,
      tipoTrabajador: tipoTrabajador ?? this.tipoTrabajador,
      tipoTurno: tipoTurno ?? this.tipoTurno,
      horaInicio: horaInicio ?? this.horaInicio,
      horaTermino: horaTermino ?? this.horaTermino,
    );
  }

  // Método para obtener los tipos de turno disponibles
  static List<String> get tiposTurnoDisponibles => [
    'semana',
    'fin de semana',
    'toda la semana',
  ];

  // Método para validar si el tipo de turno es válido
  bool get esTipoTurnoValido => tiposTurnoDisponibles.contains(tipoTurno);

  @override
  String toString() {
    return 'TurnoDefinido(id: $id, tipoTrabajador: $tipoTrabajador, tipoTurno: $tipoTurno, horaInicio: $horaInicio, horaTermino: $horaTermino)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnoDefinido &&
        other.id == id &&
        other.tipoTrabajador == tipoTrabajador &&
        other.tipoTurno == tipoTurno &&
        other.horaInicio == horaInicio &&
        other.horaTermino == horaTermino;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tipoTrabajador.hashCode ^
        tipoTurno.hashCode ^
        horaInicio.hashCode ^
        horaTermino.hashCode;
  }
}