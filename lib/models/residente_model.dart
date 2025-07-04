import 'package:cloud_firestore/cloud_firestore.dart';

class ResidenteModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String codigo;
  final bool esComite;
  final String fechaRegistro;
  final bool permitirMsjsResidentes;
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
    required this.permitirMsjsResidentes,
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
      'permitirMsjsResidentes': permitirMsjsResidentes,
      'tipoVivienda': tipoVivienda,
      'numeroVivienda': numeroVivienda,
      'etiquetaEdificio': etiquetaEdificio,
      'numeroDepartamento': numeroDepartamento,
      'viviendaSeleccionada': viviendaSeleccionada,
    };
  }

  factory ResidenteModel.fromMap(Map<String, dynamic> map) {
    return ResidenteModel(
      uid: map['uid']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      condominioId: map['condominioId']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      esComite: _parseBool(map['esComite']),
      fechaRegistro: map['fechaRegistro']?.toString() ?? '',
      permitirMsjsResidentes: _parseBool(map['permitirMsjsResidentes'], defaultValue: true),
      tipoVivienda: map['tipoVivienda']?.toString(),
      numeroVivienda: map['numeroVivienda']?.toString(),
      etiquetaEdificio: map['etiquetaEdificio']?.toString(),
      numeroDepartamento: map['numeroDepartamento']?.toString(),
      viviendaSeleccionada: map['viviendaSeleccionada']?.toString() ?? 'no_seleccionada',
    );
  }

  // Método auxiliar para parsear valores booleanos de manera segura
  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
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
      return '$numeroDepartamento';
    }
    
    return 'Vivienda no especificada';
  }

  // // Método para obtener una clave única de la vivienda
  // String get vivienda {
  //   if (viviendaSeleccionada != 'seleccionada') return '';
    
  //   if (tipoVivienda == 'casa') {
  //     return 'casa_$numeroVivienda';
  //   } else if (tipoVivienda == 'departamento') {
  //     return 'depto_${etiquetaEdificio}_$numeroDepartamento';
  //   }
    
  //   return '';
  // }

  // Método para crear una copia con nuevos valores
  ResidenteModel copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? condominioId,
    String? codigo,
    bool? esComite,
    String? fechaRegistro,
    bool? permitirMsjsResidentes,
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
      permitirMsjsResidentes: permitirMsjsResidentes?? this.permitirMsjsResidentes,
      tipoVivienda: tipoVivienda ?? this.tipoVivienda,
      numeroVivienda: numeroVivienda ?? this.numeroVivienda,
      etiquetaEdificio: etiquetaEdificio ?? this.etiquetaEdificio,
      numeroDepartamento: numeroDepartamento ?? this.numeroDepartamento,
      viviendaSeleccionada: viviendaSeleccionada ?? this.viviendaSeleccionada,
    );
  }
}