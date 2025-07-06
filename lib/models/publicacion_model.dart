class PublicacionModel {
  final String id;
  final String tipoPublicacion; // residentes/trabajadores
  final String contenido;
  final String titulo;
  final String fechaPublicacion;
  final Map<String, dynamic>? isRead;
  final String estado;
  final Map<String, dynamic>? additionalData;

  PublicacionModel({
    required this.id,
    required this.tipoPublicacion,
    required this.contenido,
    required this.titulo,
    required this.fechaPublicacion,
    this.isRead,
    required this.estado,
    this.additionalData,
  });

  factory PublicacionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return PublicacionModel(
      id: id ?? map['id'] ?? '',
      tipoPublicacion: map['tipoPublicacion'] ?? '',
      contenido: map['contenido'] ?? '',
      titulo: map['titulo'] ?? '',
      fechaPublicacion: map['fechaPublicacion'] ?? '',
      isRead: map['isRead'],
      estado: map['estado'] ?? '',
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoPublicacion': tipoPublicacion,
      'contenido': contenido,
      'titulo': titulo,
      'fechaPublicacion': fechaPublicacion,
      'isRead': isRead,
      'estado': estado,
      'additionalData': additionalData,
    };
  }

  PublicacionModel copyWith({
    String? id,
    String? tipoPublicacion,
    String? contenido,
    String? titulo,
    String? fechaPublicacion,
    Map<String, dynamic>? isRead,
    String? estado,
    Map<String, dynamic>? additionalData,
  }) {
    return PublicacionModel(
      id: id ?? this.id,
      tipoPublicacion: tipoPublicacion ?? this.tipoPublicacion,
      contenido: contenido ?? this.contenido,
      titulo: titulo ?? this.titulo,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      isRead: isRead ?? this.isRead,
      estado: estado ?? this.estado,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
