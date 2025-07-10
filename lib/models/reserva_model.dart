import 'revision_uso_model.dart';


class ReservaModel {
  final String id;
  final String fechaHoraSolicitud;
  final String fechaHoraReserva;
  final String? fechaHoraFinReserva;
  final String? nombreSolicitante;
  final List<String> participantes;
  final String espacioComunId;
  final String nombreEspacioComun;
  final String estado;
  final List<String> idSolicitante;
  final String vivienda;
  final Map<String, dynamic>? revisionPrePostUso;
  
  // Nuevos campos para residentes
  final String? espacioId;
  final String? residenteId;
  final String? nombreResidente;
  final String? nombreEspacio;
  final DateTime? fechaUso;
  final String? horaInicio;
  final String? horaFin;
  final String? motivo;
  final DateTime? fechaSolicitud;
  final List<RevisionUsoModel>? revisionesUso;

  ReservaModel({
    required this.id,
    required this.fechaHoraSolicitud,
    required this.fechaHoraReserva,
    this.fechaHoraFinReserva,
    this.nombreSolicitante,
    required this.participantes,
    required this.espacioComunId,
    required this.nombreEspacioComun,
    required this.estado,
    required this.idSolicitante,
    required this.vivienda,
    this.revisionPrePostUso,
    // Nuevos campos opcionales
    this.espacioId,
    this.residenteId,
    this.nombreResidente,
    this.nombreEspacio,
    this.fechaUso,
    this.horaInicio,
    this.horaFin,
    this.motivo,
    this.fechaSolicitud,
    this.revisionesUso,
  });

  factory ReservaModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<RevisionUsoModel>? revisiones;
    if (data['revisionesUso'] != null) {
      final revisionesData = data['revisionesUso'] as Map<String, dynamic>;
      revisiones = revisionesData.entries
          .map((entry) => RevisionUsoModel.fromFirestore(
              Map<String, dynamic>.from(entry.value), entry.key))
          .toList();
    }

    return ReservaModel(
      id: id,
      fechaHoraSolicitud: data['fechaHoraSolicitud'] ?? '',
      fechaHoraReserva: data['fechaHoraReserva'] ?? '',
      fechaHoraFinReserva: data['fechaHoraFinReserva'],
      nombreSolicitante: data['nombreSolicitante'],
      participantes: List<String>.from(data['participantes'] ?? []),
      espacioComunId: data['espacioComunId'] ?? '',
      nombreEspacioComun: data['nombreEspacioComun'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      idSolicitante: List<String>.from(data['idSolicitante'] ?? []),
      vivienda: data['vivienda'] ?? '',
      revisionPrePostUso: data['revisionPrePostUso'] != null 
          ? Map<String, dynamic>.from(data['revisionPrePostUso']) 
          : null,
      // Nuevos campos
      espacioId: data['espacioId'],
      residenteId: data['residenteId'],
      nombreResidente: data['nombreResidente'],
      nombreEspacio: data['nombreEspacio'],
      fechaUso: data['fechaUso'] != null ? DateTime.parse(data['fechaUso']) : null,
      horaInicio: data['horaInicio'],
      horaFin: data['horaFin'],
      motivo: data['motivo'],
      fechaSolicitud: data['fechaSolicitud'] != null ? DateTime.parse(data['fechaSolicitud']) : null,
      revisionesUso: revisiones,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'id': id,
      'fechaHoraSolicitud': fechaHoraSolicitud,
      'fechaHoraReserva': fechaHoraReserva,
      'participantes': participantes,
      'espacioComunId': espacioComunId,
      'nombreEspacioComun': nombreEspacioComun,
      'estado': estado,
      'idSolicitante': idSolicitante,
      'vivienda': vivienda,
      'revisionPrePostUso': revisionPrePostUso,
    };

    // Agregar campos opcionales si existen
    if (fechaHoraFinReserva != null) data['fechaHoraFinReserva'] = fechaHoraFinReserva;
    if (nombreSolicitante != null) data['nombreSolicitante'] = nombreSolicitante;

    // Agregar nuevos campos si existen
    if (espacioId != null) data['espacioId'] = espacioId;
    if (residenteId != null) data['residenteId'] = residenteId;
    if (nombreResidente != null) data['nombreResidente'] = nombreResidente;
    if (nombreEspacio != null) data['nombreEspacio'] = nombreEspacio;
    if (fechaUso != null) data['fechaUso'] = fechaUso!.toIso8601String();
    if (horaInicio != null) data['horaInicio'] = horaInicio;
    if (horaFin != null) data['horaFin'] = horaFin;
    if (motivo != null) data['motivo'] = motivo;
    if (fechaSolicitud != null) data['fechaSolicitud'] = fechaSolicitud!.toIso8601String();
    
    if (revisionesUso != null && revisionesUso!.isNotEmpty) {
      final revisionesMap = <String, dynamic>{};
      for (final revision in revisionesUso!) {
        revisionesMap[revision.id] = revision.toFirestore();
      }
      data['revisionesUso'] = revisionesMap;
    }

    return data;
  }

  ReservaModel copyWith({
    String? id,
    String? fechaHoraSolicitud,
    String? fechaHoraReserva,
    String? fechaHoraFinReserva,
    String? nombreSolicitante,
    List<String>? participantes,
    String? espacioComunId,
    String? nombreEspacioComun,
    String? estado,
    List<String>? idSolicitante,
    String? vivienda,
    Map<String, dynamic>? revisionPrePostUso,
    String? espacioId,
    String? residenteId,
    String? nombreResidente,
    String? nombreEspacio,
    DateTime? fechaUso,
    String? horaInicio,
    String? horaFin,
    String? motivo,
    DateTime? fechaSolicitud,
    List<RevisionUsoModel>? revisionesUso,
  }) {
    return ReservaModel(
      id: id ?? this.id,
      fechaHoraSolicitud: fechaHoraSolicitud ?? this.fechaHoraSolicitud,
      fechaHoraReserva: fechaHoraReserva ?? this.fechaHoraReserva,
      fechaHoraFinReserva: fechaHoraFinReserva ?? this.fechaHoraFinReserva,
      nombreSolicitante: nombreSolicitante ?? this.nombreSolicitante,
      participantes: participantes ?? this.participantes,
      espacioComunId: espacioComunId ?? this.espacioComunId,
      nombreEspacioComun: nombreEspacioComun ?? this.nombreEspacioComun,
      estado: estado ?? this.estado,
      idSolicitante: idSolicitante ?? this.idSolicitante,
      vivienda: vivienda ?? this.vivienda,
      revisionPrePostUso: revisionPrePostUso ?? this.revisionPrePostUso,
      espacioId: espacioId ?? this.espacioId,
      residenteId: residenteId ?? this.residenteId,
      nombreResidente: nombreResidente ?? this.nombreResidente,
      nombreEspacio: nombreEspacio ?? this.nombreEspacio,
      fechaUso: fechaUso ?? this.fechaUso,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      motivo: motivo ?? this.motivo,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      revisionesUso: revisionesUso ?? this.revisionesUso,
    );
  }
}