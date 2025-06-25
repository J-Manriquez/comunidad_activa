class MensajeModel {
  final String id;
  final String fechaRegistro;
  final List<String> participantes;
  final List<ContenidoMensajeModel> contenido;
  final String tipo;

  MensajeModel({
    required this.id,
    required this.fechaRegistro,
    required this.participantes,
    required this.contenido,
    this.tipo = '',
  });

  factory MensajeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MensajeModel(
      id: id,
      fechaRegistro: data['fechaRegistro'] ?? '',
      participantes: List<String>.from(data['participantes'] ?? []),
      contenido: [], // Se carga por separado desde la subcolección
      tipo: data['tipo']?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fechaRegistro': fechaRegistro,
      'participantes': participantes,
      'tipo': tipo,
    };
  }
}

class ContenidoMensajeModel {
  final String id;
  final String? texto;
  final Map<String, dynamic>? additionalData;
  final Map<String, dynamic>? isRead;
  final String fechaHoraCreacion;
  final String autorUid;

  ContenidoMensajeModel({
    required this.id,
    this.texto,
    this.additionalData,
    this.isRead,
    required this.fechaHoraCreacion,
    required this.autorUid,
  });

  factory ContenidoMensajeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ContenidoMensajeModel(
      id: id,
      texto: data['texto'],
      additionalData: data['additionalData'] != null 
          ? Map<String, dynamic>.from(data['additionalData']) 
          : null,
      isRead: data['isRead'] != null 
          ? Map<String, dynamic>.from(data['isRead']) 
          : null,
      fechaHoraCreacion: data['fechaHoraCreacion'] ?? '',
      autorUid: data['autorUid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'additionalData': additionalData,
      'isRead': isRead,
      'fechaHoraCreacion': fechaHoraCreacion,
      'autorUid': autorUid,
    };
  }

  ContenidoMensajeModel copyWith({
    String? id,
    String? texto,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? isRead,
    String? fechaHoraCreacion,
    String? autorUid,
  }) {
    return ContenidoMensajeModel(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      additionalData: additionalData ?? this.additionalData,
      isRead: isRead ?? this.isRead,
      fechaHoraCreacion: fechaHoraCreacion ?? this.fechaHoraCreacion,
      autorUid: autorUid ?? this.autorUid,
    );
  }
}