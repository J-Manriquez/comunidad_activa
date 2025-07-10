class EspacioComunModel {
  final String id;
  final String nombre;
  final int capacidad;
  final int? precio;
  final String estado;
  final String tiempoUso;
  final String? descripcion;
  final String? horaApertura;
  final String? horaCierre;
  final Map<String, dynamic>? additionalData;

  EspacioComunModel({
    required this.id,
    required this.nombre,
    required this.capacidad,
    this.precio,
    required this.estado,
    required this.tiempoUso,
    this.descripcion,
    this.horaApertura,
    this.horaCierre,
    this.additionalData,
  });

  factory EspacioComunModel.fromFirestore(Map<String, dynamic> data, String id) {
    print('🔧 [DEBUG] EspacioComunModel.fromFirestore - ID: $id');
    //print estas claves descripcion, nombre, id, tiempoUso,horaApertura, horaCierre, estado, capacidad, precio
    // print('🔧 [DEBUG] Datos recibidos: $data.descripcion $data.nombre $data.id');
    print('🔧 [DEBUG] Claves disponibles: ${data.keys.toList()}');
    
    final nombre = data['nombre'] ?? '';
    final capacidad = data['capacidad'] ?? 0;
    final precio = data['precio'];
    final estado = data['estado'] ?? 'activo';
    final tiempoUso = data['tiempoUso'] ?? '1';
    final descripcion = data['descripcion'];
    final horaApertura = data['horaApertura'];
    final horaCierre = data['horaCierre'];
    final additionalData = data['additionalData'] != null 
        ? Map<String, dynamic>.from(data['additionalData']) 
        : null;
    
    print('🔧 [DEBUG] Valores extraídos:');
    print('  - nombre: $nombre');
    print('  - capacidad: $capacidad');
    print('  - precio: $precio');
    print('  - estado: $estado');
    print('  - tiempoUso: $tiempoUso');
    print('  - descripcion: $descripcion');
    print('  - horaApertura: $horaApertura');
    print('  - horaCierre: $horaCierre');
    // print('  - additionalData: $additionalData');
    
    final espacio = EspacioComunModel(
      id: id,
      nombre: nombre,
      capacidad: capacidad,
      precio: precio,
      estado: estado,
      tiempoUso: tiempoUso,
      descripcion: descripcion,
      horaApertura: horaApertura,
      horaCierre: horaCierre,
      additionalData: additionalData,
    );
    
    print('✅ [DEBUG] EspacioComunModel creado exitosamente: ${espacio.nombre}');
    return espacio;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'capacidad': capacidad,
      'precio': precio,
      'estado': estado,
      'tiempoUso': tiempoUso,
      'descripcion': descripcion,
      'horaApertura': horaApertura,
      'horaCierre': horaCierre,
      'additionalData': additionalData,
    };
  }

  EspacioComunModel copyWith({
    String? id,
    String? nombre,
    int? capacidad,
    int? precio,
    String? estado,
    String? tiempoUso,
    String? descripcion,
    String? horaApertura,
    String? horaCierre,
    Map<String, dynamic>? additionalData,
  }) {
    return EspacioComunModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      capacidad: capacidad ?? this.capacidad,
      precio: precio ?? this.precio,
      estado: estado ?? this.estado,
      tiempoUso: tiempoUso ?? this.tiempoUso,
      descripcion: descripcion ?? this.descripcion,
      horaApertura: horaApertura ?? this.horaApertura,
      horaCierre: horaCierre ?? this.horaCierre,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}