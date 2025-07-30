import 'package:cloud_firestore/cloud_firestore.dart';

class CorrespondenciaConfigModel {
  final String tiempoMaximoRetencion;
  final bool fotoObligatoria;
  final bool aceptacionResidente;
  final bool eleccionResidente;
  final String tipoFirma;

  CorrespondenciaConfigModel({
    required this.tiempoMaximoRetencion,
    required this.fotoObligatoria,
    required this.aceptacionResidente,
    required this.eleccionResidente,
    required this.tipoFirma,
  });

  Map<String, dynamic> toMap() {
    return {
      'tiempoMaximoRetencion': tiempoMaximoRetencion,
      'fotoObligatoria': fotoObligatoria,
      'aceptacionResidente': aceptacionResidente,
      'eleccionResidente': eleccionResidente,
      'tipoFirma': tipoFirma,
    };
  }

  factory CorrespondenciaConfigModel.fromMap(Map<String, dynamic> map) {
    return CorrespondenciaConfigModel(
      tiempoMaximoRetencion: map['tiempoMaximoRetencion']?.toString() ?? '3 dias',
      fotoObligatoria: _parseBool(map['fotoObligatoria']),
      aceptacionResidente: _parseBool(map['aceptacionResidente']),
      eleccionResidente: _parseBool(map['eleccionResidente']),
      tipoFirma: map['tipoFirma']?.toString() ?? 'no solicitar firma',
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

  factory CorrespondenciaConfigModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CorrespondenciaConfigModel.fromMap(data);
  }

  // Método para crear una copia con nuevos valores
  CorrespondenciaConfigModel copyWith({
    String? tiempoMaximoRetencion,
    bool? fotoObligatoria,
    bool? aceptacionResidente,
    bool? eleccionResidente,
    String? tipoFirma,
  }) {
    return CorrespondenciaConfigModel(
      tiempoMaximoRetencion: tiempoMaximoRetencion ?? this.tiempoMaximoRetencion,
      fotoObligatoria: fotoObligatoria ?? this.fotoObligatoria,
      aceptacionResidente: aceptacionResidente ?? this.aceptacionResidente,
      eleccionResidente: eleccionResidente ?? this.eleccionResidente,
      tipoFirma: tipoFirma ?? this.tipoFirma,
    );
  }

  // Valores por defecto
  static CorrespondenciaConfigModel get defaultConfig => CorrespondenciaConfigModel(
    tiempoMaximoRetencion: '3 dias',
    fotoObligatoria: false,
    aceptacionResidente: false,
    eleccionResidente: false,
    tipoFirma: 'no solicitar firma',
  );
}

class CorrespondenciaModel {
  final String id;
  final String tipoEntrega;
  final String tipoCorrespondencia;
  final String fechaHoraRecepcion;
  final String? fechaHoraEntrega;
  final String? viviendaRecepcion;
  final String? residenteIdRecepcion;
  final String datosEntrega;
  final String? residenteIdEntrega;
  final String? firma;
  final Map<String, dynamic> adjuntos;
  final List<Map<String, dynamic>>? infAdicional;
  final Map<String, Map<String, dynamic>> notificacionEntrega;
  final bool solicitarAceptacion;

  CorrespondenciaModel({
    required this.id,
    required this.tipoEntrega,
    required this.tipoCorrespondencia,
    required this.fechaHoraRecepcion,
    this.fechaHoraEntrega,
    this.viviendaRecepcion,
    this.residenteIdRecepcion,
    required this.datosEntrega,
    this.residenteIdEntrega,
    this.firma,
    this.adjuntos = const {},
    this.infAdicional,
    this.notificacionEntrega = const {},
    this.solicitarAceptacion = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoEntrega': tipoEntrega,
      'tipoCorrespondencia': tipoCorrespondencia,
      'fechaHoraRecepcion': fechaHoraRecepcion,
      'fechaHoraEntrega': fechaHoraEntrega,
      'viviendaRecepcion': viviendaRecepcion,
      'residenteIdRecepcion': residenteIdRecepcion,
      'datosEntrega': datosEntrega,
      'residenteIdEntrega': residenteIdEntrega,
      'firma': firma,
      'adjuntos': adjuntos,
      'infAdicional': infAdicional,
      'notificacionEntrega': notificacionEntrega,
      'solicitarAceptacion': solicitarAceptacion,
    };
  }

  factory CorrespondenciaModel.fromMap(Map<String, dynamic> map) {
    return CorrespondenciaModel(
      id: map['id']?.toString() ?? '',
      tipoEntrega: map['tipoEntrega']?.toString() ?? '',
      tipoCorrespondencia: map['tipoCorrespondencia']?.toString() ?? '',
      fechaHoraRecepcion: map['fechaHoraRecepcion']?.toString() ?? '',
      fechaHoraEntrega: map['fechaHoraEntrega']?.toString(),
      viviendaRecepcion: map['viviendaRecepcion']?.toString(),
      residenteIdRecepcion: map['residenteIdRecepcion']?.toString(),
      datosEntrega: map['datosEntrega']?.toString() ?? '',
      residenteIdEntrega: map['residenteIdEntrega']?.toString(),
      firma: map['firma']?.toString(),
      adjuntos: Map<String, dynamic>.from(map['adjuntos'] ?? {}),
      infAdicional: map['infAdicional'] != null ? 
        (map['infAdicional'] is List ? 
          List<Map<String, dynamic>>.from(map['infAdicional']) : 
          [Map<String, dynamic>.from(map['infAdicional'])]) : null,
      notificacionEntrega: map['notificacionEntrega'] != null ?
        Map<String, Map<String, dynamic>>.from(
          (map['notificacionEntrega'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value))
          )
        ) : {},
      solicitarAceptacion: CorrespondenciaConfigModel._parseBool(map['solicitarAceptacion']),
    );
  }

  factory CorrespondenciaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CorrespondenciaModel.fromMap(data);
  }

  // Método para crear una copia con nuevos valores
  CorrespondenciaModel copyWith({
    String? id,
    String? tipoEntrega,
    String? tipoCorrespondencia,
    String? fechaHoraRecepcion,
    String? fechaHoraEntrega,
    String? viviendaRecepcion,
    String? residenteIdRecepcion,
    String? datosEntrega,
    String? residenteIdEntrega,
    String? firma,
    Map<String, dynamic>? adjuntos,
    List<Map<String, dynamic>>? infAdicional,
    Map<String, Map<String, dynamic>>? notificacionEntrega,
    bool? solicitarAceptacion,
  }) {
    return CorrespondenciaModel(
      id: id ?? this.id,
      tipoEntrega: tipoEntrega ?? this.tipoEntrega,
      tipoCorrespondencia: tipoCorrespondencia ?? this.tipoCorrespondencia,
      fechaHoraRecepcion: fechaHoraRecepcion ?? this.fechaHoraRecepcion,
      fechaHoraEntrega: fechaHoraEntrega ?? this.fechaHoraEntrega,
      viviendaRecepcion: viviendaRecepcion ?? this.viviendaRecepcion,
      residenteIdRecepcion: residenteIdRecepcion ?? this.residenteIdRecepcion,
      datosEntrega: datosEntrega ?? this.datosEntrega,
      residenteIdEntrega: residenteIdEntrega ?? this.residenteIdEntrega,
      firma: firma ?? this.firma,
      adjuntos: adjuntos ?? this.adjuntos,
      infAdicional: infAdicional ?? this.infAdicional,
      notificacionEntrega: notificacionEntrega ?? this.notificacionEntrega,
      solicitarAceptacion: solicitarAceptacion ?? this.solicitarAceptacion,
    );
  }
}