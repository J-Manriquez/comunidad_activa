class ListaPorcentajesModel {
  final String id;
  final String nombre;
  final String condominioId;
  final Map<String, ViviendaPorcentajeModel> viviendas;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;

  ListaPorcentajesModel({
    required this.id,
    required this.nombre,
    required this.condominioId,
    required this.viviendas,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  factory ListaPorcentajesModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final viviendasData = data['viviendas'] as Map<String, dynamic>? ?? {};
    final viviendas = <String, ViviendaPorcentajeModel>{};
    
    viviendasData.forEach((key, value) {
      viviendas[key] = ViviendaPorcentajeModel.fromMap(value as Map<String, dynamic>);
    });

    return ListaPorcentajesModel(
      id: id,
      nombre: data['nombre'] ?? '',
      condominioId: data['condominioId'] ?? '',
      viviendas: viviendas,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
        data['fechaCreacion']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      ),
      fechaModificacion: DateTime.fromMillisecondsSinceEpoch(
        data['fechaModificacion']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    final viviendasData = <String, dynamic>{};
    viviendas.forEach((key, value) {
      viviendasData[key] = value.toMap();
    });

    return {
      'nombre': nombre,
      'condominioId': condominioId,
      'viviendas': viviendasData,
      'fechaCreacion': fechaCreacion,
      'fechaModificacion': fechaModificacion,
    };
  }

  ListaPorcentajesModel copyWith({
    String? id,
    String? nombre,
    String? condominioId,
    Map<String, ViviendaPorcentajeModel>? viviendas,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return ListaPorcentajesModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      condominioId: condominioId ?? this.condominioId,
      viviendas: viviendas ?? this.viviendas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }

  // Calcular el total de porcentajes asignados
  int get totalPorcentaje {
    return viviendas.values.fold(0, (sum, vivienda) => sum + vivienda.porcentaje);
  }

  // Verificar si la distribución es válida (suma 100%)
  bool get esValida => totalPorcentaje == 100;

  // Obtener porcentaje faltante o en exceso
  int get porcentajeFaltante => 100 - totalPorcentaje;

  // Obtener viviendas con porcentaje 0
  List<String> get viviendasSinPorcentaje {
    return viviendas.entries
        .where((entry) => entry.value.porcentaje == 0)
        .map((entry) => entry.key)
        .toList();
  }
}

class ViviendaPorcentajeModel {
  final String vivienda;
  final List<String> listaIdsResidentes;
  final int porcentaje;
  final String descripcionVivienda;

  ViviendaPorcentajeModel({
    required this.vivienda,
    required this.listaIdsResidentes,
    required this.porcentaje,
    required this.descripcionVivienda,
  });

  factory ViviendaPorcentajeModel.fromMap(Map<String, dynamic> data) {
    return ViviendaPorcentajeModel(
      vivienda: data['vivienda'] ?? '',
      listaIdsResidentes: List<String>.from(data['listaIdsResidentes'] ?? []),
      porcentaje: data['porcentaje'] ?? 0,
      descripcionVivienda: data['descripcionVivienda'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vivienda': vivienda,
      'listaIdsResidentes': listaIdsResidentes,
      'porcentaje': porcentaje,
      'descripcionVivienda': descripcionVivienda,
    };
  }

  ViviendaPorcentajeModel copyWith({
    String? vivienda,
    List<String>? listaIdsResidentes,
    int? porcentaje,
    String? descripcionVivienda,
  }) {
    return ViviendaPorcentajeModel(
      vivienda: vivienda ?? this.vivienda,
      listaIdsResidentes: listaIdsResidentes ?? this.listaIdsResidentes,
      porcentaje: porcentaje ?? this.porcentaje,
      descripcionVivienda: descripcionVivienda ?? this.descripcionVivienda,
    );
  }
}