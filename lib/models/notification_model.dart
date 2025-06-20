class NotificationModel {
  final String id;
  final String fechaRegistro; // Campo unificado para fecha y hora
  final String notificationType;
  final String content;
  final Map<String, dynamic>? isRead;
  final String status;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.fechaRegistro,
    required this.notificationType,
    required this.content,
    required this.isRead,
    required this.status,
    this.additionalData,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    print('Datos recibidos en fromMap: $data'); // Print de depuración
    return NotificationModel(
      id: data['id'] ?? '',
      fechaRegistro: data['fechaRegistro'] ?? '',
      notificationType: data['tipoNotificacion'] ?? '',
      content: data['contenido'] ?? '',
      isRead: data['isRead'],
      status: data['estado'] ?? '',
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaRegistro': fechaRegistro,
      'tipoNotificacion': notificationType,
      'contenido': content,
      'isRead': isRead,
      'estado': status,
      'additionalData': additionalData,
    };
  }

  // Métodos auxiliares para obtener fecha y hora por separado
  String get date {
    try {
      final dateTime = DateTime.parse(fechaRegistro);
      return dateTime.toIso8601String().split('T')[0];
    } catch (e) {
      return fechaRegistro.split(' ')[0];
    }
  }

  String get time {
    try {
      final dateTime = DateTime.parse(fechaRegistro);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaRegistro.split(' ')[1] ?? '00:00';
    }
  }
}