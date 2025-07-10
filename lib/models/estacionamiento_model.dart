import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para la configuración general de estacionamientos
class EstacionamientoConfigModel {
  final bool activo;
  final int cantidadDisponible;
  final List<String> numeracion;
  final bool permitirSeleccion;
  final bool autoAsignacion;
  final bool permitirPrestamos;
  final bool estVisitas;
  final bool reservasEstVisitas;
  final int cantidadEstVisitas;
  final List<String> numeracionEstVisitas;

  EstacionamientoConfigModel({
    required this.activo,
    required this.cantidadDisponible,
    required this.numeracion,
    required this.permitirSeleccion,
    required this.autoAsignacion,
    required this.permitirPrestamos,
    required this.estVisitas,
    required this.reservasEstVisitas,
    required this.cantidadEstVisitas,
    required this.numeracionEstVisitas,
  });

  factory EstacionamientoConfigModel.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return EstacionamientoConfigModel(
      activo: data['activo'] ?? false,
      cantidadDisponible: data['cantidadDisponible'] ?? 0,
      numeracion: List<String>.from(data['numeracion'] ?? []),
      permitirSeleccion: data['permitirSeleccion'] ?? false,
      autoAsignacion: data['autoAsignacion'] ?? false,
      permitirPrestamos: data['permitirPrestamos'] ?? false,
      estVisitas: data['estVisitas'] ?? false,
      reservasEstVisitas: data['ReservasEstVisitas'] ?? false,
      cantidadEstVisitas: data['cantidadEstVisitas'] ?? 0,
      numeracionEstVisitas: List<String>.from(data['numeracionestVisitas'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activo': activo,
      'cantidadDisponible': cantidadDisponible,
      'numeracion': numeracion,
      'permitirSeleccion': permitirSeleccion,
      'autoAsignacion': autoAsignacion,
      'permitirPrestamos': permitirPrestamos,
      'estVisitas': estVisitas,
      'ReservasEstVisitas': reservasEstVisitas,
      'cantidadEstVisitas': cantidadEstVisitas,
      'numeracionestVisitas': numeracionEstVisitas,
    };
  }

  EstacionamientoConfigModel copyWith({
    bool? activo,
    int? cantidadDisponible,
    List<String>? numeracion,
    bool? permitirSeleccion,
    bool? autoAsignacion,
    bool? permitirPrestamos,
    bool? estVisitas,
    bool? reservasEstVisitas,
    int? cantidadEstVisitas,
    List<String>? numeracionEstVisitas,
  }) {
    return EstacionamientoConfigModel(
      activo: activo ?? this.activo,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      numeracion: numeracion ?? this.numeracion,
      permitirSeleccion: permitirSeleccion ?? this.permitirSeleccion,
      autoAsignacion: autoAsignacion ?? this.autoAsignacion,
      permitirPrestamos: permitirPrestamos ?? this.permitirPrestamos,
      estVisitas: estVisitas ?? this.estVisitas,
      reservasEstVisitas: reservasEstVisitas ?? this.reservasEstVisitas,
      cantidadEstVisitas: cantidadEstVisitas ?? this.cantidadEstVisitas,
      numeracionEstVisitas: numeracionEstVisitas ?? this.numeracionEstVisitas,
    );
  }
}

// Modelo para un estacionamiento individual
class EstacionamientoModel {
  final String id;
  final bool estVisita;
  final String nroEstacionamiento;
  final String? viviendaAsignada;
  final String? fechaHoraSolicitud;
  final List<String>? idSolicitante;
  final List<String>? nombreSolicitante;
  final List<String>? viviendaSolicitante;
  final String? estadoSolicitud;
  final String? respuestaSolicitud;
  final String? nombreEspacioComun;
  final bool? prestado;
  final String? fechaHoraInicio;
  final String? fechaHoraFin;
  final String? viviendaPrestamo;

  EstacionamientoModel({
    required this.id,
    required this.estVisita,
    required this.nroEstacionamiento,
    this.viviendaAsignada,
    this.fechaHoraSolicitud,
    this.idSolicitante,
    this.nombreSolicitante,
    this.viviendaSolicitante,
    this.estadoSolicitud,
    this.respuestaSolicitud,
    this.nombreEspacioComun,
    this.prestado,
    this.fechaHoraInicio,
    this.fechaHoraFin,
    this.viviendaPrestamo,
  });

  factory EstacionamientoModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return EstacionamientoModel(
      id: documentId,
      estVisita: data['estVisita'] ?? false,
      nroEstacionamiento: data['nroEstacionamiento'] ?? '',
      viviendaAsignada: data['viviendaAsignada'],
      fechaHoraSolicitud: data['fechaHoraSolicitud'],
      idSolicitante: data['idSolicitante'] != null
          ? List<String>.from(data['idSolicitante'])
          : null,
      nombreSolicitante: data['nombreSolicitante'] != null
          ? List<String>.from(data['nombreSolicitante'])
          : null,
      viviendaSolicitante: data['viviendaSolicitante'] != null
          ? List<String>.from(data['viviendaSolicitante'])
          : null,
      estadoSolicitud: data['estadoSolicitud'],
      respuestaSolicitud: data['respuestaSolicitud'],
      nombreEspacioComun: data['nombreEspacioComun'],
      prestado: data['prestado'],
      fechaHoraInicio: data['fechaHoraInicio'],
      fechaHoraFin: data['fechaHoraFin'],
      viviendaPrestamo: data['viviendaPrestamo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'estVisita': estVisita,
      'nroEstacionamiento': nroEstacionamiento,
      'viviendaAsignada': viviendaAsignada,
      'fechaHoraSolicitud': fechaHoraSolicitud,
      'idSolicitante': idSolicitante,
      'nombreSolicitante': nombreSolicitante,
      'viviendaSolicitante': viviendaSolicitante,
      'estadoSolicitud': estadoSolicitud,
      'respuestaSolicitud': respuestaSolicitud,
      'nombreEspacioComun': nombreEspacioComun,
      'prestado': prestado,
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
      'viviendaPrestamo': viviendaPrestamo,
    };
  }
}

// Modelo para reservas de estacionamientos de visitas
class ReservaEstacionamientoVisitaModel {
  final String id;
  final String visitaVivienda;
  final String fechaHoraSolicitud;
  final String idSolicitante;
  final String nombreSolicitante;
  final String viviendaSolicitante;
  final String estadoSolicitud;
  final String? respuestaSolicitud;
  final int nroEstSolicitado;

  ReservaEstacionamientoVisitaModel({
    required this.id,
    required this.visitaVivienda,
    required this.fechaHoraSolicitud,
    required this.idSolicitante,
    required this.nombreSolicitante,
    required this.viviendaSolicitante,
    required this.estadoSolicitud,
    this.respuestaSolicitud,
    required this.nroEstSolicitado,
  });

  factory ReservaEstacionamientoVisitaModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ReservaEstacionamientoVisitaModel(
      id: documentId,
      visitaVivienda: data['visitaVivienda'] ?? '',
      fechaHoraSolicitud: data['fechaHoraSolicitud'] ?? '',
      idSolicitante: data['idSolicitante'] ?? '',
      nombreSolicitante: data['nombreSolicitante'] ?? '',
      viviendaSolicitante: data['viviendaSolicitante'] ?? '',
      estadoSolicitud: data['estadoSolicitud'] ?? 'pendiente',
      respuestaSolicitud: data['respuestaSolicitud'],
      nroEstSolicitado: data['nroEstSolicitado'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitaVivienda': visitaVivienda,
      'fechaHoraSolicitud': fechaHoraSolicitud,
      'idSolicitante': idSolicitante,
      'nombreSolicitante': nombreSolicitante,
      'viviendaSolicitante': viviendaSolicitante,
      'estadoSolicitud': estadoSolicitud,
      'respuestaSolicitud': respuestaSolicitud,
      'nroEstSolicitado': nroEstSolicitado,
    };
  }
}