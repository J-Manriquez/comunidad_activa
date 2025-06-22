class MultaModel {
  final String id;
  final String fechaRegistro;
  final String tipoMulta;
  final String contenido;
  final Map<String, dynamic>? isRead;
  final String? estado;
  // additionalData ahora incluirá:
  // - valor: int
  // - unidadMedida: String
  // - tipoVivienda: String
  // - numeroVivienda: String
  // - etiquetaEdificio: String? (para departamentos)
  // - numeroDepartamento: String? (para departamentos)
  // - residentesIds: List<String> (IDs de los residentes de la vivienda)
  final Map<String, dynamic>? additionalData;

  MultaModel({
    required this.id,
    required this.fechaRegistro,
    required this.tipoMulta,
    required this.contenido,
    this.isRead,
    this.estado,
    this.additionalData,
  });

  factory MultaModel.fromMap(Map<String, dynamic> data) {
    return MultaModel(
      id: data['id'] ?? '',
      fechaRegistro: data['fechaRegistro'] ?? '',
      tipoMulta: data['tipoMulta'] ?? '',
      contenido: data['contenido'] ?? '',
      isRead: data['isRead'],
      estado: data['estado'],
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaRegistro': fechaRegistro,
      'tipoMulta': tipoMulta,
      'contenido': contenido,
      'isRead': isRead,
      'estado': estado,
      'additionalData': additionalData,
    };
  }

  // Método auxiliar para obtener los IDs de residentes
  List<String> get residentesIds {
    if (additionalData != null && additionalData!['residentesIds'] != null) {
      return List<String>.from(additionalData!['residentesIds']);
    }
    return [];
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

// Modelo para la gestión de multas en el condominio
class GestionMulta {
  final String id;
  final String tipoMulta;
  final int valor;
  final String unidadMedida;

  GestionMulta({
    required this.id,
    required this.tipoMulta,
    required this.valor,
    required this.unidadMedida,
  });

  factory GestionMulta.fromMap(Map<String, dynamic> data) {
    return GestionMulta(
      id: data['id'] ?? '',
      tipoMulta: data['tipoMulta'] ?? '',
      valor: data['valor'] ?? 0,
      unidadMedida: data['unidadMedida'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoMulta': tipoMulta,
      'valor': valor,
      'unidadMedida': unidadMedida,
    };
  }
}