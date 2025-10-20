class TipoReclamo {
  final String id;
  final String tipoReclamo;

  TipoReclamo({
    required this.id,
    required this.tipoReclamo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoReclamo': tipoReclamo,
    };
  }

  factory TipoReclamo.fromMap(Map<String, dynamic> map) {
    return TipoReclamo(
      id: map['id'] ?? '',
      tipoReclamo: map['tipoReclamo'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoReclamo &&
        other.id == id &&
        other.tipoReclamo == tipoReclamo;
  }

  @override
  int get hashCode => id.hashCode ^ tipoReclamo.hashCode;

  @override
  String toString() => 'TipoReclamo(id: $id, tipoReclamo: $tipoReclamo)';
}