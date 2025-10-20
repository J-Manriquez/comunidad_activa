import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/models/multa_model.dart';
import 'package:comunidad_activa/models/tipo_reclamo_model.dart';

enum TipoCondominio { casas, edificio, mixto }

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
  });

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
    );
  }

  factory CondominioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CondominioModel.fromMap(data);
  }
}