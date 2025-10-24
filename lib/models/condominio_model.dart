import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/models/multa_model.dart';
import 'package:comunidad_activa/models/tipo_reclamo_model.dart';

enum TipoCondominio { casas, edificio, mixto }

class GestionFunciones {
  final bool correspondencia;
  final bool controlAcceso;
  final bool espaciosComunes;
  final bool multas;
  final bool reclamos;
  final bool publicaciones;
  final bool registroDiario;
  final bool bloqueoVisitas;
  final bool gastosComunes;
  final bool turnosTrabajadores;
  final bool chatEntreRes;
  final bool chatGrupal;
  final bool chatAdministrador;
  final bool chatConserjeria;
  final bool chatPrivado;

  GestionFunciones({
    this.correspondencia = false,
    this.controlAcceso = false,
    this.espaciosComunes = false,
    this.multas = false,
    this.reclamos = false,
    this.publicaciones = false,
    this.registroDiario = false,
    this.bloqueoVisitas = false,
    this.gastosComunes = false,
    this.turnosTrabajadores = false,
    this.chatEntreRes = false,
    this.chatGrupal = false,
    this.chatAdministrador = false,
    this.chatConserjeria = false,
    this.chatPrivado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'correspondencia': correspondencia,
      'controlAcceso': controlAcceso,
      'espaciosComunes': espaciosComunes,
      'multas': multas,
      'reclamos': reclamos,
      'publicaciones': publicaciones,
      'registroDiario': registroDiario,
      'bloqueoVisitas': bloqueoVisitas,
      'gastosComunes': gastosComunes,
      'turnosTrabajadores': turnosTrabajadores,
      'chatEntreRes': chatEntreRes,
      'chatGrupal': chatGrupal,
      'chatAdministrador': chatAdministrador,
      'chatConserjeria': chatConserjeria,
      'chatPrivado': chatPrivado,
    };
  }

  factory GestionFunciones.fromMap(Map<String, dynamic> map) {
    return GestionFunciones(
      correspondencia: map['correspondencia'] ?? false,
      controlAcceso: map['controlAcceso'] ?? false,
      espaciosComunes: map['espaciosComunes'] ?? false,
      multas: map['multas'] ?? false,
      reclamos: map['reclamos'] ?? false,
      publicaciones: map['publicaciones'] ?? false,
      registroDiario: map['registroDiario'] ?? false,
      bloqueoVisitas: map['bloqueoVisitas'] ?? false,
      gastosComunes: map['gastosComunes'] ?? false,
      turnosTrabajadores: map['turnosTrabajadores'] ?? false,
      chatEntreRes: map['chatEntreRes'] ?? false,
      chatGrupal: map['chatGrupal'] ?? false,
      chatAdministrador: map['chatAdministrador'] ?? false,
      chatConserjeria: map['chatConserjeria'] ?? false,
      chatPrivado: map['chatPrivado'] ?? false,
    );
  }

  GestionFunciones copyWith({
    bool? correspondencia,
    bool? controlAcceso,
    bool? espaciosComunes,
    bool? multas,
    bool? reclamos,
    bool? publicaciones,
    bool? registroDiario,
    bool? bloqueoVisitas,
    bool? gastosComunes,
    bool? turnosTrabajadores,
    bool? chatEntreRes,
    bool? chatGrupal,
    bool? chatAdministrador,
    bool? chatConserjeria,
    bool? chatPrivado,
  }) {
    return GestionFunciones(
      correspondencia: correspondencia ?? this.correspondencia,
      controlAcceso: controlAcceso ?? this.controlAcceso,
      espaciosComunes: espaciosComunes ?? this.espaciosComunes,
      multas: multas ?? this.multas,
      reclamos: reclamos ?? this.reclamos,
      publicaciones: publicaciones ?? this.publicaciones,
      registroDiario: registroDiario ?? this.registroDiario,
      bloqueoVisitas: bloqueoVisitas ?? this.bloqueoVisitas,
      gastosComunes: gastosComunes ?? this.gastosComunes,
      turnosTrabajadores: turnosTrabajadores ?? this.turnosTrabajadores,
      chatEntreRes: chatEntreRes ?? this.chatEntreRes,
      chatGrupal: chatGrupal ?? this.chatGrupal,
      chatAdministrador: chatAdministrador ?? this.chatAdministrador,
      chatConserjeria: chatConserjeria ?? this.chatConserjeria,
      chatPrivado: chatPrivado ?? this.chatPrivado,
    );
  }
}

class ConfiguracionEdificio {
  final String id;
  final String nombre;
  final int numeroTorres;
  final int apartamentosPorTorre;
  final String? numeracion;
  final String? etiquetasTorres;
  final String? rangoTorres;

  ConfiguracionEdificio({
    required this.id,
    required this.nombre,
    required this.numeroTorres,
    required this.apartamentosPorTorre,
    this.numeracion,
    this.etiquetasTorres,
    this.rangoTorres,
  });

  int get totalApartamentos => numeroTorres * apartamentosPorTorre;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'numeroTorres': numeroTorres,
      'apartamentosPorTorre': apartamentosPorTorre,
      'numeracion': numeracion,
      'etiquetasTorres': etiquetasTorres,
      'rangoTorres': rangoTorres,
    };
  }

  factory ConfiguracionEdificio.fromMap(Map<String, dynamic> map) {
    return ConfiguracionEdificio(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      numeroTorres: map['numeroTorres'] ?? 0,
      apartamentosPorTorre: map['apartamentosPorTorre'] ?? 0,
      numeracion: map['numeracion'],
      etiquetasTorres: map['etiquetasTorres'],
      rangoTorres: map['rangoTorres'],
    );
  }
}

class CondominioModel {
  final String id;
  final String nombre;
  final String direccion;
  final String fechaCreacion;
  final bool pruebaActiva;
  final String? fechaFinPrueba;
  final bool? comunicacionEntreResidentes;
  final TipoCondominio? tipoCondominio;
  
  // Propiedades específicas para tipo 'casas'
  final int? numeroCasas;
  final String? rangoCasas;
  
  // Propiedades específicas para tipo 'edificio' (compatibilidad hacia atrás)
  final int? numeroTorres;
  final int? apartamentosPorTorre;
  final String? numeracion;
  final String? etiquetasTorres;
  final String? rangoTorres;
  
  // Nuevas propiedades para múltiples configuraciones
  final bool? edificiosIguales;
  final List<ConfiguracionEdificio>? configuracionesEdificios;
  
  // Campo calculado automáticamente
  final int? totalInmuebles;
  final bool? requiereConfirmacionAdmin;
  
  // Nueva propiedad para gestión de multas
  final List<GestionMulta>? gestionMultas;
  
  // Nueva propiedad para gestión de reclamos
  final List<TipoReclamo>? gestionReclamos;
  
  // Configuración para cobrar multas junto con gastos comunes
  final bool? cobrarMultasConGastos;
  
  // Configuración para cobrar espacios comunes junto con gastos comunes
  final bool? cobrarEspaciosConGastos;
  
  // Mapa de tipos de trabajadores del condominio
  final Map<String, String>? tiposTrabajadores;
  
  // Gestión de funciones y permisos del condominio
  final GestionFunciones gestionFunciones;

  CondominioModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.fechaCreacion,
    required this.pruebaActiva,
    this.fechaFinPrueba,
    this.comunicacionEntreResidentes,
    this.tipoCondominio,
    this.numeroCasas,
    this.rangoCasas,
    this.numeroTorres,
    this.apartamentosPorTorre,
    this.numeracion,
    this.etiquetasTorres,
    this.rangoTorres,
    this.edificiosIguales,
    this.configuracionesEdificios,
    this.totalInmuebles,
    this.requiereConfirmacionAdmin,
    this.gestionMultas,
    this.gestionReclamos,
    this.cobrarMultasConGastos,
    this.cobrarEspaciosConGastos,
    this.tiposTrabajadores,
    GestionFunciones? gestionFunciones,
  }) : gestionFunciones = gestionFunciones ?? GestionFunciones();

  // Método para calcular el total de inmuebles
  int calcularTotalInmuebles() {
    int total = 0;
    
    // Sumar casas
    if (numeroCasas != null) {
      total += numeroCasas!;
    }
    
    // Sumar edificios
    if (configuracionesEdificios != null && configuracionesEdificios!.isNotEmpty) {
      for (var config in configuracionesEdificios!) {
        total += config.totalApartamentos;
      }
    } else if (numeroTorres != null && apartamentosPorTorre != null) {
      // Compatibilidad hacia atrás
      total += numeroTorres! * apartamentosPorTorre!;
    }
    
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'fechaCreacion': fechaCreacion,
      'pruebaActiva': pruebaActiva,
      'fechaFinPrueba': fechaFinPrueba,
      'comunicacionEntreResidentes': comunicacionEntreResidentes,
      'tipoCondominio': tipoCondominio?.toString().split('.').last,
      'numeroCasas': numeroCasas,
      'rangoCasas': rangoCasas,
      'numeroTorres': numeroTorres,
      'apartamentosPorTorre': apartamentosPorTorre,
      'numeracion': numeracion,
      'etiquetasTorres': etiquetasTorres,
      'rangoTorres': rangoTorres,
      'edificiosIguales': edificiosIguales,
      'configuracionesEdificios': configuracionesEdificios?.map((e) => e.toMap()).toList(),
      'totalInmuebles': calcularTotalInmuebles(),
      'requiereConfirmacionAdmin': requiereConfirmacionAdmin,
      'gestionMultas': gestionMultas?.map((e) => e.toMap()).toList(),
      'gestionReclamos': gestionReclamos?.map((e) => e.toMap()).toList(),
      'cobrarMultasConGastos': cobrarMultasConGastos,
      'cobrarEspaciosConGastos': cobrarEspaciosConGastos,
      'tiposTrabajadores': tiposTrabajadores,
      'gestionFunciones': gestionFunciones.toMap(),
    };
  }

  factory CondominioModel.fromMap(Map<String, dynamic> map) {
    TipoCondominio? tipo;
    if (map['tipoCondominio'] != null) {
      switch (map['tipoCondominio']) {
        case 'casas':
          tipo = TipoCondominio.casas;
          break;
        case 'edificio':
          tipo = TipoCondominio.edificio;
          break;
        case 'mixto':
          tipo = TipoCondominio.mixto;
          break;
      }
    }
    
    List<ConfiguracionEdificio>? configuraciones;
    if (map['configuracionesEdificios'] != null) {
      configuraciones = (map['configuracionesEdificios'] as List)
          .map((e) => ConfiguracionEdificio.fromMap(e))
          .toList();
    }
    
    List<GestionMulta>? gestionMultasList;
    if (map['gestionMultas'] != null) {
      gestionMultasList = (map['gestionMultas'] as List)
          .map((e) => GestionMulta.fromMap(e))
          .toList();
    }
    
    List<TipoReclamo>? gestionReclamosList;
    if (map['gestionReclamos'] != null) {
      gestionReclamosList = (map['gestionReclamos'] as List)
          .map((e) => TipoReclamo.fromMap(e))
          .toList();
    }
    
    return CondominioModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      fechaCreacion: map['fechaCreacion'] ?? '',
      pruebaActiva: map['pruebaActiva'] ?? true,
      fechaFinPrueba: map['fechaFinPrueba'],
      comunicacionEntreResidentes: map['comunicacionEntreResidentes'] ?? false,
      tipoCondominio: tipo,
      numeroCasas: map['numeroCasas'],
      rangoCasas: map['rangoCasas'],
      numeroTorres: map['numeroTorres'],
      apartamentosPorTorre: map['apartamentosPorTorre'],
      numeracion: map['numeracion'],
      etiquetasTorres: map['etiquetasTorres'],
      rangoTorres: map['rangoTorres'],
      edificiosIguales: map['edificiosIguales'],
      configuracionesEdificios: configuraciones,
      totalInmuebles: map['totalInmuebles'],
      requiereConfirmacionAdmin: map['requiereConfirmacionAdmin'],
      gestionMultas: gestionMultasList,
      gestionReclamos: gestionReclamosList,
      cobrarMultasConGastos: map['cobrarMultasConGastos'],
      cobrarEspaciosConGastos: map['cobrarEspaciosConGastos'],
      tiposTrabajadores: map['tiposTrabajadores'] != null 
          ? Map<String, String>.from(map['tiposTrabajadores'])
          : null,
      gestionFunciones: map['gestionFunciones'] != null
          ? GestionFunciones.fromMap(map['gestionFunciones'])
          : GestionFunciones(),
    );
  }

  factory CondominioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CondominioModel.fromMap(data);
  }

  CondominioModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? fechaCreacion,
    bool? pruebaActiva,
    String? fechaFinPrueba,
    bool? comunicacionEntreResidentes,
    TipoCondominio? tipoCondominio,
    int? numeroCasas,
    String? rangoCasas,
    int? numeroTorres,
    int? apartamentosPorTorre,
    String? numeracion,
    String? etiquetasTorres,
    String? rangoTorres,
    bool? edificiosIguales,
    List<ConfiguracionEdificio>? configuracionesEdificios,
    int? totalInmuebles,
    bool? requiereConfirmacionAdmin,
    List<GestionMulta>? gestionMultas,
    List<TipoReclamo>? gestionReclamos,
    bool? cobrarMultasConGastos,
    bool? cobrarEspaciosConGastos,
    Map<String, String>? tiposTrabajadores,
    GestionFunciones? gestionFunciones,
  }) {
    return CondominioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      pruebaActiva: pruebaActiva ?? this.pruebaActiva,
      fechaFinPrueba: fechaFinPrueba ?? this.fechaFinPrueba,
      comunicacionEntreResidentes: comunicacionEntreResidentes ?? this.comunicacionEntreResidentes,
      tipoCondominio: tipoCondominio ?? this.tipoCondominio,
      numeroCasas: numeroCasas ?? this.numeroCasas,
      rangoCasas: rangoCasas ?? this.rangoCasas,
      numeroTorres: numeroTorres ?? this.numeroTorres,
      apartamentosPorTorre: apartamentosPorTorre ?? this.apartamentosPorTorre,
      numeracion: numeracion ?? this.numeracion,
      etiquetasTorres: etiquetasTorres ?? this.etiquetasTorres,
      rangoTorres: rangoTorres ?? this.rangoTorres,
      edificiosIguales: edificiosIguales ?? this.edificiosIguales,
      configuracionesEdificios: configuracionesEdificios ?? this.configuracionesEdificios,
      totalInmuebles: totalInmuebles ?? this.totalInmuebles,
      requiereConfirmacionAdmin: requiereConfirmacionAdmin ?? this.requiereConfirmacionAdmin,
      gestionMultas: gestionMultas ?? this.gestionMultas,
      gestionReclamos: gestionReclamos ?? this.gestionReclamos,
      cobrarMultasConGastos: cobrarMultasConGastos ?? this.cobrarMultasConGastos,
      cobrarEspaciosConGastos: cobrarEspaciosConGastos ?? this.cobrarEspaciosConGastos,
      tiposTrabajadores: tiposTrabajadores ?? this.tiposTrabajadores,
      gestionFunciones: gestionFunciones ?? this.gestionFunciones,
    );
  }
}