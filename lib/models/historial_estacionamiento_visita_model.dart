class HistorialEstacionamientoVisitaModel {
  final String id;
  final String nroEstacionamiento;
  final bool prestado;
  final String? viviendaAsignada;
  final String? viviendaPrestamo;
  final String? viviendaSolicitante;
  final String? estadoSolicitud;
  final String? fechaHoraSolicitud;
  final String? fechaHoraInicio;
  final String? fechaHoraFin;
  final List<String>? idSolicitante;
  final List<String>? nombreSolicitante;
  final String? respuestaSolicitud;
  final DateTime fechaCreacionHistorial;
  final String creadoPor;
  final String motivoFinalizacion;

  HistorialEstacionamientoVisitaModel({
    required this.id,
    required this.nroEstacionamiento,
    required this.prestado,
    this.viviendaAsignada,
    this.viviendaPrestamo,
    this.viviendaSolicitante,
    this.estadoSolicitud,
    this.fechaHoraSolicitud,
    this.fechaHoraInicio,
    this.fechaHoraFin,
    this.idSolicitante,
    this.nombreSolicitante,
    this.respuestaSolicitud,
    required this.fechaCreacionHistorial,
    required this.creadoPor,
    required this.motivoFinalizacion,
  });

  factory HistorialEstacionamientoVisitaModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HistorialEstacionamientoVisitaModel(
      id: documentId,
      nroEstacionamiento: map['nroEstacionamiento'] ?? '',
      prestado: map['prestado'] ?? false,
      viviendaAsignada: map['viviendaAsignada'],
      viviendaPrestamo: map['viviendaPrestamo'],
      viviendaSolicitante: map['viviendaSolicitante'],
      estadoSolicitud: map['estadoSolicitud'],
      fechaHoraSolicitud: map['fechaHoraSolicitud'],
      fechaHoraInicio: map['fechaHoraInicio'],
      fechaHoraFin: map['fechaHoraFin'],
      idSolicitante: map['idSolicitante'] != null 
          ? List<String>.from(map['idSolicitante']) 
          : null,
      nombreSolicitante: map['nombreSolicitante'] != null 
          ? List<String>.from(map['nombreSolicitante']) 
          : null,
      respuestaSolicitud: map['respuestaSolicitud'],
      fechaCreacionHistorial: map['fechaCreacionHistorial'] != null
          ? DateTime.parse(map['fechaCreacionHistorial'])
          : DateTime.now(),
      creadoPor: map['creadoPor'] ?? '',
      motivoFinalizacion: map['motivoFinalizacion'] ?? 'Finalización manual',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nroEstacionamiento': nroEstacionamiento,
      'prestado': prestado,
      'viviendaAsignada': viviendaAsignada,
      'viviendaPrestamo': viviendaPrestamo,
      'viviendaSolicitante': viviendaSolicitante,
      'estadoSolicitud': estadoSolicitud,
      'fechaHoraSolicitud': fechaHoraSolicitud,
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
      'idSolicitante': idSolicitante,
      'nombreSolicitante': nombreSolicitante,
      'respuestaSolicitud': respuestaSolicitud,
      'fechaCreacionHistorial': fechaCreacionHistorial.toIso8601String(),
      'creadoPor': creadoPor,
      'motivoFinalizacion': motivoFinalizacion,
    };
  }

  @override
  String toString() {
    return 'HistorialEstacionamientoVisitaModel(id: $id, nroEstacionamiento: $nroEstacionamiento, prestado: $prestado, fechaCreacionHistorial: $fechaCreacionHistorial)';
  }
}