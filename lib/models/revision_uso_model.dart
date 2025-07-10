class RevisionUsoModel {
  final String id;
  final String fecha;
  final String descripcion;
  final String estado;
  final int? costo;
  final String tipoRevision; // 'pre_uso' o 'post_uso'
  final Map<String, dynamic>? additionalData;

  RevisionUsoModel({
    required this.id,
    required this.fecha,
    required this.descripcion,
    required this.estado,
    this.costo,
    required this.tipoRevision,
    this.additionalData,
  });

  factory RevisionUsoModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RevisionUsoModel(
      id: id,
      fecha: data['fecha'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      costo: data['costo'],
      tipoRevision: data['tipoRevision'] ?? 'post_uso', // valor por defecto para compatibilidad
      additionalData: data['additionalData'] != null 
          ? Map<String, dynamic>.from(data['additionalData']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'fecha': fecha,
      'descripcion': descripcion,
      'estado': estado,
      'costo': costo,
      'tipoRevision': tipoRevision,
      'additionalData': additionalData,
    };
  }

  RevisionUsoModel copyWith({
    String? id,
    String? fecha,
    String? descripcion,
    String? estado,
    int? costo,
    String? tipoRevision,
    Map<String, dynamic>? additionalData,
  }) {
    return RevisionUsoModel(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      costo: costo ?? this.costo,
      tipoRevision: tipoRevision ?? this.tipoRevision,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}