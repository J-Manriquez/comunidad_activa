import 'package:cloud_firestore/cloud_firestore.dart';

class ResidenteModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String codigo;
  final bool esComite;
  final String fechaRegistro;
  // Nuevos campos para vivienda
  final String? tipoVivienda; // 'casa' o 'departamento'
  final String? numeroVivienda; // Para casas
  final String? etiquetaEdificio; // Para departamentos
  final String? numeroDepartamento; // Para departamentos
  final String viviendaSeleccionada; // 'no_seleccionada', 'pendiente', 'seleccionada'

  ResidenteModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.condominioId,
    required this.codigo,
    required this.esComite,
    required this.fechaRegistro,
    this.tipoVivienda,
    this.numeroVivienda,
    this.etiquetaEdificio,
    this.numeroDepartamento,
    this.viviendaSeleccionada = 'no_seleccionada',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'condominioId': condominioId,
      'codigo': codigo,
      'esComite': esComite,
      'fechaRegistro': fechaRegistro,
      'tipoVivienda': tipoVivienda,
      'numeroVivienda': numeroVivienda,
      'etiquetaEdificio': etiquetaEdificio,
      'numeroDepartamento': numeroDepartamento,
      'viviendaSeleccionada': viviendaSeleccionada,
    };
  }

  factory ResidenteModel.fromMap(Map<String, dynamic> map) {
    return ResidenteModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      condominioId: map['condominioId'] ?? '',
      codigo: map['codigo'] ?? '',
      esComite: map['esComite'] ?? false,
      fechaRegistro: map['fechaRegistro'] ?? '',
      tipoVivienda: map['tipoVivienda'],
      numeroVivienda: map['numeroVivienda'],
      etiquetaEdificio: map['etiquetaEdificio'],
      numeroDepartamento: map['numeroDepartamento'],
      viviendaSeleccionada: map['viviendaSeleccionada'] ?? 'no_seleccionada',
    );
  }

  factory ResidenteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResidenteModel.fromMap(data);
  }

  // Método para obtener la descripción completa de la vivienda
  String get descripcionVivienda {
    if (viviendaSeleccionada == 'no_seleccionada') return 'Sin vivienda asignada';
    if (viviendaSeleccionada == 'pendiente') return 'Solicitud pendiente';
    
    if (tipoVivienda == 'casa') {
      return 'Casa $numeroVivienda';
    } else if (tipoVivienda == 'departamento') {
      return '$etiquetaEdificio-$numeroDepartamento';
    }
    
    return 'Vivienda no especificada';
  }

  // Método para crear una copia con nuevos valores
  ResidenteModel copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? condominioId,
    String? codigo,
    bool? esComite,
    String? fechaRegistro,
    String? tipoVivienda,
    String? numeroVivienda,
    String? etiquetaEdificio,
    String? numeroDepartamento,
    String? viviendaSeleccionada,
  }) {
    return ResidenteModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      condominioId: condominioId ?? this.condominioId,
      codigo: codigo ?? this.codigo,
      esComite: esComite ?? this.esComite,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      tipoVivienda: tipoVivienda ?? this.tipoVivienda,
      numeroVivienda: numeroVivienda ?? this.numeroVivienda,
      etiquetaEdificio: etiquetaEdificio ?? this.etiquetaEdificio,
      numeroDepartamento: numeroDepartamento ?? this.numeroDepartamento,
      viviendaSeleccionada: viviendaSeleccionada ?? this.viviendaSeleccionada,
    );
  }
}