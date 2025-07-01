class GastoComunModel {
  final String id;
  final int monto;
  final String descripcion;
  final Map<String, dynamic>? pctjePorRes;
  final String tipoCobro; // 'igual' o 'porcentaje'
  final String? periodo; // Solo para gastos adicionales, formato "dd-mm-aaaa hasta dd-mm-aaaa"
  final TipoGasto tipo;

  GastoComunModel({
    required this.id,
    required this.monto,
    required this.descripcion,
    this.pctjePorRes,
    required this.tipoCobro,
    this.periodo,
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
      tipo: tipo,
    );
  }

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

    return data;
  }

  GastoComunModel copyWith({
    String? id,
    int? monto,
    String? descripcion,
    Map<String, dynamic>? pctjePorRes,
    String? tipoCobro,
    String? periodo,
    TipoGasto? tipo,
  }) {
    return GastoComunModel(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      pctjePorRes: pctjePorRes ?? this.pctjePorRes,
      tipoCobro: tipoCobro ?? this.tipoCobro,
      periodo: periodo ?? this.periodo,
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