import 'package:cloud_firestore/cloud_firestore.dart';

class VisitaBloqueadaModel {
  final String id;
  final String nombreVisitante;
  final String rutVisitante;
  final String viviendaBloqueo;
  final String motivoBloqueo;
  final Timestamp fechaBloqueo;
  final String bloqueadoPor;
  final String estado; // "activo", "expirado", etc.
  final Map<String, dynamic>? additionalData; // Para imágenes base64

  VisitaBloqueadaModel({
    required this.id,
    required this.nombreVisitante,
    required this.rutVisitante,
    required this.viviendaBloqueo,
    required this.motivoBloqueo,
    required this.fechaBloqueo,
    required this.bloqueadoPor,
    required this.estado,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreVisitante': nombreVisitante,
      'rutVisitante': rutVisitante,
      'viviendaBloqueo': viviendaBloqueo,
      'motivoBloqueo': motivoBloqueo,
      'fechaBloqueo': fechaBloqueo,
      'bloqueadoPor': bloqueadoPor,
      'estado': estado,
      'additionalData': additionalData,
    };
  }

  factory VisitaBloqueadaModel.fromMap(Map<String, dynamic> map) {
    return VisitaBloqueadaModel(
      id: map['id']?.toString() ?? '',
      nombreVisitante: map['nombreVisitante']?.toString() ?? '',
      rutVisitante: map['rutVisitante']?.toString() ?? '',
      viviendaBloqueo: map['viviendaBloqueo']?.toString() ?? '',
      motivoBloqueo: map['motivoBloqueo']?.toString() ?? '',
      fechaBloqueo: map['fechaBloqueo'] as Timestamp? ?? Timestamp.now(),
      bloqueadoPor: map['bloqueadoPor']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'activo',
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  factory VisitaBloqueadaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VisitaBloqueadaModel.fromMap(data);
  }

  // Método para obtener las imágenes base64 del additionalData
  Map<String, String>? get imagenesBase64 {
    if (additionalData == null) return null;
    
    final imagenes = additionalData!['imagenesBase64'];
    if (imagenes is Map<String, dynamic>) {
      return imagenes.cast<String, String>();
    }
    return null;
  }

  // Método para obtener la fecha formateada
  String get fechaBloqueoFormateada {
    final fecha = fechaBloqueo.toDate();
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  // Método para crear una copia con nuevos valores
  VisitaBloqueadaModel copyWith({
    String? id,
    String? nombreVisitante,
    String? rutVisitante,
    String? viviendaBloqueo,
    String? motivoBloqueo,
    Timestamp? fechaBloqueo,
    String? bloqueadoPor,
    String? estado,
    Map<String, dynamic>? additionalData,
  }) {
    return VisitaBloqueadaModel(
      id: id ?? this.id,
      nombreVisitante: nombreVisitante ?? this.nombreVisitante,
      rutVisitante: rutVisitante ?? this.rutVisitante,
      viviendaBloqueo: viviendaBloqueo ?? this.viviendaBloqueo,
      motivoBloqueo: motivoBloqueo ?? this.motivoBloqueo,
      fechaBloqueo: fechaBloqueo ?? this.fechaBloqueo,
      bloqueadoPor: bloqueadoPor ?? this.bloqueadoPor,
      estado: estado ?? this.estado,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'VisitaBloqueadaModel(id: $id, nombreVisitante: $nombreVisitante, rutVisitante: $rutVisitante, viviendaBloqueo: $viviendaBloqueo, estado: $estado)';
  }
}