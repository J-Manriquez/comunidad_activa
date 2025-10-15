import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para el documento controlAcceso
class ControlAcceso {
  final Map<String, dynamic> camposAdicionales;
  final Map<String, dynamic> camposActivos;

  ControlAcceso({
    required this.camposAdicionales,
    required this.camposActivos,
  });

  factory ControlAcceso.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ControlAcceso(
      camposAdicionales: data['camposAdicionales'] ?? {},
      camposActivos: data['camposActivos'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'camposAdicionales': camposAdicionales,
      'camposActivos': camposActivos,
    };
  }

  ControlAcceso copyWith({
    Map<String, dynamic>? camposAdicionales,
    Map<String, dynamic>? camposActivos,
  }) {
    return ControlAcceso(
      camposAdicionales: camposAdicionales ?? this.camposAdicionales,
      camposActivos: camposActivos ?? this.camposActivos,
    );
  }
}

// Modelo para los documentos de la colección controlDiario
class ControlDiario {
  final String id;
  final String nombre;
  final String rut;
  final Timestamp fecha;
  final String hora;
  final String tipoIngreso;
  final String tipoTransporte;
  final String tipoAuto;
  final String color;
  final String vivienda;
  final String usaEstacionamiento;
  final String patente;
  final Map<String, dynamic> additionalData;

  ControlDiario({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.fecha,
    required this.hora,
    required this.tipoIngreso,
    required this.tipoTransporte,
    required this.tipoAuto,
    required this.color,
    required this.vivienda,
    required this.usaEstacionamiento,
    required this.patente,
    required this.additionalData,
  });

  factory ControlDiario.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ControlDiario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      rut: data['rut'] ?? '',
      fecha: data['fecha'] ?? Timestamp.now(),
      hora: data['hora'] ?? '',
      tipoIngreso: data['tipoIngreso'] ?? '',
      tipoTransporte: data['tipoTransporte'] ?? '',
      tipoAuto: data['tipoAuto'] ?? '',
      color: data['color'] ?? '',
      vivienda: data['vivienda'] ?? '',
      usaEstacionamiento: _convertUsaEstacionamientoToString(data['usaEstacionamiento']),
      patente: data['patente'] ?? '',
      additionalData: data['additionalData'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nombre': nombre,
      'rut': rut,
      'fecha': fecha,
      'hora': hora,
      'tipoIngreso': tipoIngreso,
      'tipoTransporte': tipoTransporte,
      'tipoAuto': tipoAuto,
      'color': color,
      'vivienda': vivienda,
      'usaEstacionamiento': usaEstacionamiento,
      'patente': patente,
      'additionalData': additionalData,
    };
  }

  ControlDiario copyWith({
    String? id,
    String? nombre,
    String? rut,
    Timestamp? fecha,
    String? hora,
    String? tipoIngreso,
    String? tipoTransporte,
    String? tipoAuto,
    String? color,
    String? vivienda,
    String? usaEstacionamiento,
    String? patente,
    Map<String, dynamic>? additionalData,
  }) {
    return ControlDiario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      rut: rut ?? this.rut,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      tipoIngreso: tipoIngreso ?? this.tipoIngreso,
      tipoTransporte: tipoTransporte ?? this.tipoTransporte,
      tipoAuto: tipoAuto ?? this.tipoAuto,
      color: color ?? this.color,
      vivienda: vivienda ?? this.vivienda,
      usaEstacionamiento: usaEstacionamiento ?? this.usaEstacionamiento,
      patente: patente ?? this.patente,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Método para obtener la fecha formateada
  String get fechaFormateada {
    DateTime dateTime = fecha.toDate();
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  // Método para obtener fecha y hora combinadas
  String get fechaHoraCompleta {
    return '$fechaFormateada $hora';
  }

  // Método helper para convertir usaEstacionamiento de bool a String
  static String _convertUsaEstacionamientoToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is bool) return value ? 'true' : '';
    return '';
  }
}

// Modelo para filtros de búsqueda en el historial
class FiltroControlAcceso {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? tipoIngreso;
  final String? tipoTransporte;
  final String? vivienda;
  final String? nombre;
  final String? rut;

  FiltroControlAcceso({
    this.fechaInicio,
    this.fechaFin,
    this.tipoIngreso,
    this.tipoTransporte,
    this.vivienda,
    this.nombre,
    this.rut,
  });

  FiltroControlAcceso copyWith({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? tipoIngreso,
    String? tipoTransporte,
    String? vivienda,
    String? nombre,
    String? rut,
  }) {
    return FiltroControlAcceso(
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      tipoIngreso: tipoIngreso ?? this.tipoIngreso,
      tipoTransporte: tipoTransporte ?? this.tipoTransporte,
      vivienda: vivienda ?? this.vivienda,
      nombre: nombre ?? this.nombre,
      rut: rut ?? this.rut,
    );
  }

  // Método para verificar si hay filtros activos
  bool get tienesFiltrosActivos {
    return fechaInicio != null ||
        fechaFin != null ||
        (tipoIngreso != null && tipoIngreso!.isNotEmpty) ||
        (tipoTransporte != null && tipoTransporte!.isNotEmpty) ||
        (vivienda != null && vivienda!.isNotEmpty) ||
        (nombre != null && nombre!.isNotEmpty) ||
        (rut != null && rut!.isNotEmpty);
  }
}

// Enums para los tipos de datos
enum TipoIngreso {
  residente,
  visita,
  trabajador,
  delivery,
  emergencia,
}

enum TipoTransporte {
  auto,
  moto,
  bicicleta,
  caminando,
  taxi,
  uber,
  otro,
}

// Extensiones para convertir enums a string y viceversa
extension TipoIngresoExtension on TipoIngreso {
  String get displayName {
    switch (this) {
      case TipoIngreso.residente:
        return 'Residente';
      case TipoIngreso.visita:
        return 'Visita';
      case TipoIngreso.trabajador:
        return 'Trabajador';
      case TipoIngreso.delivery:
        return 'Delivery';
      case TipoIngreso.emergencia:
        return 'Emergencia';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static TipoIngreso fromString(String value) {
    return TipoIngreso.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoIngreso.visita,
    );
  }
}

extension TipoTransporteExtension on TipoTransporte {
  String get displayName {
    switch (this) {
      case TipoTransporte.auto:
        return 'Auto';
      case TipoTransporte.moto:
        return 'Moto';
      case TipoTransporte.bicicleta:
        return 'Bicicleta';
      case TipoTransporte.caminando:
        return 'Caminando';
      case TipoTransporte.taxi:
        return 'Taxi';
      case TipoTransporte.uber:
        return 'Uber';
      case TipoTransporte.otro:
        return 'Otro';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static TipoTransporte fromString(String value) {
    return TipoTransporte.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoTransporte.caminando,
    );
  }
}