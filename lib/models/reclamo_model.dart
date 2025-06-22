class ReclamoModel {
  final String id;
  final String fechaRegistro;
  final String tipoReclamo;
  final String contenido;
  final String? residenteId;
  final Map<String, dynamic>? estado;
  final List<dynamic>? isRead;
  final Map<String, dynamic>? additionalData;

  ReclamoModel({
    required this.id,
    required this.fechaRegistro,
    required this.tipoReclamo,
    required this.contenido,
    this.residenteId,
    this.estado,
    this.isRead,
    this.additionalData,
  });

  // Getter para obtener residenteId de cualquier fuente
  String get residenteIdEffective {
    return residenteId ?? 
           additionalData?['residenteId'] ?? 
           'unknown';
  }

  // ✅ CORRECCIÓN: Verificar correctamente si está resuelto
  bool get isResuelto {
    if (estado == null) return false;
    return estado!['resuelto'] == true;
  }

  // ✅ NUEVO: Getter para obtener mensaje de respuesta
  String? get mensajeRespuesta {
    if (estado == null) return null;
    final mensaje = estado!['mensajeRespuesta'];
    return (mensaje != null && mensaje.toString().isNotEmpty) ? mensaje.toString() : null;
  }

  // ✅ NUEVO: Getter para obtener fecha de resolución
  String? get fechaResolucion {
    if (estado == null) return null;
    return estado!['fechaResolucion'];
  }

  // ✅ NUEVO: Getter para obtener quien resolvió
  String? get resolvidoPor {
    if (estado == null) return null;
    return estado!['resolvidoPor'];
  }

  factory ReclamoModel.fromMap(Map<String, dynamic> map) {
    try {
      return ReclamoModel(
        id: map['id'] ?? '',
        fechaRegistro: map['fechaRegistro'] ?? '',
        tipoReclamo: map['tipoReclamo'] ?? '',
        contenido: map['contenido'] ?? '',
        residenteId: map['residenteId'],
        estado: map['estado'],
        isRead: map['isRead'],
        additionalData: map['additionalData'],
      );
    } catch (e) {
      print('❌ Error al crear ReclamoModel desde map: $e');
      print('📋 Map problemático: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaRegistro': fechaRegistro,
      'tipoReclamo': tipoReclamo,
      'contenido': contenido,
      'residenteId': residenteId,
      'estado': estado,
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  // Método para obtener la fecha formateada
  String get fechaFormateada {
    try {
      final dateTime = DateTime.parse(fechaRegistro);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return fechaRegistro;
    }
  }

  // Método para obtener la hora formateada
  String get horaFormateada {
    try {
      final dateTime = DateTime.parse(fechaRegistro);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}