class GastoComunModel {
  final String id;
  final int monto;
  final String descripcion;
  final Map<String, dynamic>? pctjePorRes; // Contiene nombre de lista y datos de respaldo
  final String tipoCobro; // 'igual para todos' o 'porcentaje por residente'
  final String? periodo; // Solo para gastos adicionales, formato "dd-mm-aaaa hasta dd-mm-aaaa"
  final String? periodicidad; // Para gastos fijos y variables: 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual'
  final Map<String, Map<String, dynamic>>? additionalData; // Mapa de mapas para datos adicionales
  final TipoGasto tipo;

  GastoComunModel({
    required this.id,
    required this.monto,
    required this.descripcion,
    this.pctjePorRes,
    required this.tipoCobro,
    this.periodo,
    this.periodicidad,
    this.additionalData,
    required this.tipo,
  });

  factory GastoComunModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
    TipoGasto tipo,
  ) {
    return GastoComunModel(
      id: id,
      monto: data['monto'] ?? 0,
      descripcion: data['descripcion'] ?? '',
      pctjePorRes: data['pctjePorRes'],
      tipoCobro: data['tipoCobro'] ?? 'igual',
      periodo: data['periodo'],
      periodicidad: data['periodicidad'],
      additionalData: data['additionalData'] != null 
          ? Map<String, Map<String, dynamic>>.from(
              data['additionalData'].map((key, value) => 
                MapEntry(key, Map<String, dynamic>.from(value))
              )
            )
          : null,
      tipo: tipo,
    );
  }

// conservar este metodo
  Map<String, dynamic> toFirestore() {
    final data = {
      'monto': monto,
      'descripcion': descripcion,
      'tipoCobro': tipoCobro,
    };

    if (pctjePorRes != null) {
      data['pctjePorRes'] = pctjePorRes!;
    }

    if (periodo != null) {
      data['periodo'] = periodo!;
    }

    if (periodicidad != null) {
      data['periodicidad'] = periodicidad!;
    }

    if (additionalData != null) {
      data['additionalData'] = additionalData!;
    }

    return data;
  }

  GastoComunModel copyWith({
    String? id,
    int? monto,
    String? descripcion,
    Map<String, dynamic>? pctjePorRes,
    String? tipoCobro,
    String? periodo,
    String? periodicidad,
    Map<String, Map<String, dynamic>>? additionalData,
    TipoGasto? tipo,
  }) {
    return GastoComunModel(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      pctjePorRes: pctjePorRes ?? this.pctjePorRes,
      tipoCobro: tipoCobro ?? this.tipoCobro,
      periodo: periodo ?? this.periodo,
      periodicidad: periodicidad ?? this.periodicidad,
      additionalData: additionalData ?? this.additionalData,
      tipo: tipo ?? this.tipo,
    );
  }
}

enum TipoGasto {
  fijo,
  variable,
  adicional,
}

extension TipoGastoExtension on TipoGasto {
  String get nombre {
    switch (this) {
      case TipoGasto.fijo:
        return 'Fijo';
      case TipoGasto.variable:
        return 'Variable';
      case TipoGasto.adicional:
        return 'Adicional';
    }
  }

  String get coleccion {
    switch (this) {
      case TipoGasto.fijo:
        return 'fijo';
      case TipoGasto.variable:
        return 'variable';
      case TipoGasto.adicional:
        return 'adicional';
    }
  }
}