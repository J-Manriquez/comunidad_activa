import 'package:cloud_firestore/cloud_firestore.dart';

class TrabajadorModel {
  final String uid;
  final String nombre;
  final String email;
  final String condominioId;
  final String codigo;
  final String tipoTrabajador;
  final String? cargoEspecifico;
  final String fechaRegistro;
  final Map<String, bool> funcionesDisponibles;

  TrabajadorModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.condominioId,
    required this.codigo,
    required this.tipoTrabajador,
    this.cargoEspecifico,
    required this.fechaRegistro,
    Map<String, bool>? funcionesDisponibles,
  }) : funcionesDisponibles = funcionesDisponibles ?? _getFuncionesPorDefecto();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'condominioId': condominioId,
      'codigo': codigo,
      'tipoTrabajador': tipoTrabajador,
      'cargoEspecifico': cargoEspecifico,
      'fechaRegistro': fechaRegistro,
      'funcionesDisponibles': funcionesDisponibles,
    };
  }

  factory TrabajadorModel.fromMap(Map<String, dynamic> map) {
    return TrabajadorModel(
      uid: map['uid'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      condominioId: map['condominioId'] ?? '',
      codigo: map['codigo'] ?? '',
      tipoTrabajador: map['tipoTrabajador'] ?? '',
      cargoEspecifico: map['cargoEspecifico'],
      fechaRegistro: map['fechaRegistro'] ?? '',
      funcionesDisponibles: Map<String, bool>.from(map['funcionesDisponibles'] ?? _getFuncionesPorDefecto()),
    );
  }

  factory TrabajadorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TrabajadorModel.fromMap(data);
  }

  // Método estático para obtener funciones por defecto según el tipo de trabajador
  static Map<String, bool> _getFuncionesPorDefecto() {
    return {
      // Gestión de Correspondencia - Sub-funciones
      'configuracionCorrespondencias': false,
      'ingresarCorrespondencia': false,
      'correspondenciasActivas': false,
      'historialCorrespondencias': false,
      // Control de Acceso - Sub-funciones
      'gestionCamposAdicionales': false,
      'gestionCamposActivos': false,
      'crearRegistroAcceso': false,
      'controlDiario': false,
      'historialControlAcceso': false,
      // Gestión de Estacionamientos - Sub-funciones
      'configuracionEstacionamientos': false,
      'solicitudesEstacionamientos': false,
      'listaEstacionamientos': false,
      'estacionamientosVisitas': false,
      // Gestión de Espacios Comunes - Sub-funciones
      'gestionEspaciosComunes': false,
      'solicitudesReservas': false,
      'revisionesPrePostUso': false,
      'solicitudesRechazadas': false,
      'historialRevisiones': false,

      // Gestión de Gastos Comunes - Sub-funciones
      'verTotalGastos': false,
      'porcentajesPorResidentes': false,
      'gastosFijos': false,
      'gastosVariables': false,
      'gastosAdicionales': false,
      // Gestión de Multas - Sub-funciones
      'crearMulta': false,
      'gestionadorMultas': false,
      'historialMultas': false,
      // Gestión de Reclamos - Sub-funciones
      'gestionTiposReclamos': false,
      'gestionReclamos': false,
      // Gestión de Publicaciones - Sub-funciones
      'gestionPublicaciones': false,
      'verPublicaciones': false,
      'publicacionesTrabajadores': false,
      // Registro Diario - Sub-funciones
      'crearNuevoRegistro': false,
      'registrosDelDia': false,
      'historialRegistros': false,
      // Bloqueo de Visitas - Sub-funciones
      'crearBloqueoVisitas': false,
      'visualizarVisitasBloqueadas': false,
      // Gestión de Turnos de Trabajadores - Sub-funciones
      'crearEditarTurno': false,
      'registroTurnosRealizados': false,
      // Gestión de Mensajes - Sub-funciones
      'chatEntreRes': false,
      'chatGrupal': false,
      'chatAdministrador': false,
      'chatConserjeria': false,
      'chatPrivado': false,
  };
  }

  // Método para crear una copia con funciones actualizadas
  TrabajadorModel copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? condominioId,
    String? codigo,
    String? tipoTrabajador,
    String? cargoEspecifico,
    String? fechaRegistro,
    Map<String, bool>? funcionesDisponibles,
  }) {
    return TrabajadorModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      condominioId: condominioId ?? this.condominioId,
      codigo: codigo ?? this.codigo,
      tipoTrabajador: tipoTrabajador ?? this.tipoTrabajador,
      cargoEspecifico: cargoEspecifico ?? this.cargoEspecifico,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      funcionesDisponibles: funcionesDisponibles ?? this.funcionesDisponibles,
    );
  }
}