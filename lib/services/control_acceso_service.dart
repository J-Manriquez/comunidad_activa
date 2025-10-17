import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/control_acceso_model.dart';

class ControlAccesoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener referencia al documento controlAcceso
  DocumentReference _getControlAccesoRef(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('controlAcceso');
  }

  // Obtener referencia a la colección controlDiario
  CollectionReference _getControlDiarioRef(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('controlAcceso')
        .collection('controlDiario');
  }

  // Obtener referencia a la colección accesosPredeterminados
  CollectionReference _getAccesosPredeterminadosRef(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('controlAcceso')
        .collection('accesosPredeterminados');
  }

  // ==================== GESTIÓN DEL DOCUMENTO CONTROL ACCESO ====================

  /// Obtener la configuración de control de acceso
  Future<ControlAcceso?> getControlAcceso(String condominioId) async {
    try {
      DocumentSnapshot doc = await _getControlAccesoRef(condominioId).get();
      
      if (doc.exists) {
        return ControlAcceso.fromFirestore(doc);
      } else {
        // Si no existe, crear uno por defecto
        await _createDefaultControlAcceso(condominioId);
        doc = await _getControlAccesoRef(condominioId).get();
        return ControlAcceso.fromFirestore(doc);
      }
    } catch (e) {
      print('Error al obtener control de acceso: $e');
      return null;
    }
  }

  /// Crear configuración por defecto de control de acceso
  Future<void> _createDefaultControlAcceso(String condominioId) async {
    try {
      final defaultConfig = ControlAcceso(
        camposAdicionales: {
          'comentario': {
            'tipo': 'texto',
            'requerido': false,
            'activo': true,
          },
        },
        camposActivos: {
          'nombre': true,
          'rut': true,
          'fecha': true,
          'hora': true,
          'tipoIngreso': true,
          'tipoTransporte': true,
          'tipoAuto': true,
          'color': true,
          'vivienda': true,
          'usaEstacionamiento': true,
        },
        usaEstacionamientoVisitas: false,
      );

      await _getControlAccesoRef(condominioId).set(defaultConfig.toFirestore());
    } catch (e) {
      print('Error al crear configuración por defecto: $e');
      rethrow;
    }
  }

  /// Actualizar campos adicionales
  Future<bool> updateCamposAdicionales(String condominioId, Map<String, dynamic> camposAdicionales) async {
    try {
      await _getControlAccesoRef(condominioId).update({
        'camposAdicionales': camposAdicionales,
      });
      return true;
    } catch (e) {
      print('Error al actualizar campos adicionales: $e');
      return false;
    }
  }

  /// Agregar un nuevo campo adicional
  Future<bool> addCampoAdicional(String condominioId, String nombreCampo, Map<String, dynamic> configuracionCampo) async {
    try {
      ControlAcceso? controlAcceso = await getControlAcceso(condominioId);
      if (controlAcceso != null) {
        Map<String, dynamic> camposActualizados = Map.from(controlAcceso.camposAdicionales);
        camposActualizados[nombreCampo] = configuracionCampo;
        return await updateCamposAdicionales(condominioId, camposActualizados);
      }
      return false;
    } catch (e) {
      print('Error al agregar campo adicional: $e');
      return false;
    }
  }

  /// Actualizar un campo adicional existente
  Future<bool> updateCampoAdicional(String condominioId, String nombreCampo, Map<String, dynamic> configuracionCampo) async {
    try {
      ControlAcceso? controlAcceso = await getControlAcceso(condominioId);
      if (controlAcceso != null) {
        Map<String, dynamic> camposActualizados = Map.from(controlAcceso.camposAdicionales);
        camposActualizados[nombreCampo] = configuracionCampo;
        return await updateCamposAdicionales(condominioId, camposActualizados);
      }
      return false;
    } catch (e) {
      print('Error al actualizar campo adicional: $e');
      return false;
    }
  }

  /// Eliminar un campo adicional
  Future<bool> deleteCampoAdicional(String condominioId, String nombreCampo) async {
    try {
      ControlAcceso? controlAcceso = await getControlAcceso(condominioId);
      if (controlAcceso != null) {
        Map<String, dynamic> camposActualizados = Map.from(controlAcceso.camposAdicionales);
        camposActualizados.remove(nombreCampo);
        return await updateCamposAdicionales(condominioId, camposActualizados);
      }
      return false;
    } catch (e) {
      print('Error al eliminar campo adicional: $e');
      return false;
    }
  }

  /// Actualizar configuración de uso de estacionamiento para visitas
  Future<bool> updateUsaEstacionamientoVisitas(String condominioId, bool usaEstacionamientoVisitas) async {
    try {
      await _getControlAccesoRef(condominioId).update({
        'usaEstacionamientoVisitas': usaEstacionamientoVisitas,
      });
      return true;
    } catch (e) {
      print('Error al actualizar configuración de estacionamiento para visitas: $e');
      return false;
    }
  }

  /// Actualizar campos activos
  Future<bool> updateCamposActivos(String condominioId, Map<String, dynamic> camposActivos) async {
    try {
      await _getControlAccesoRef(condominioId).update({
        'camposActivos': camposActivos,
      });
      return true;
    } catch (e) {
      print('Error al actualizar campos activos: $e');
      return false;
    }
  }

  // ==================== GESTIÓN DE ACCESOS PREDETERMINADOS ====================

  /// Obtener accesos predeterminados de un residente
  Future<List<AccesoPredeterminado>> getAccesosPredeterminados(String condominioId, String uidResidente) async {
    try {
      QuerySnapshot snapshot = await _getAccesosPredeterminadosRef(condominioId)
          .where('uidResidente', isEqualTo: uidResidente)
          .limit(3) // Máximo 3 accesos predeterminados
          .get();

      List<AccesoPredeterminado> accesos = snapshot.docs
          .map((doc) => AccesoPredeterminado.fromFirestore(doc))
          .toList();

      // Ordenar por fecha en el cliente para evitar índice compuesto
      accesos.sort((a, b) => b.fecha.compareTo(a.fecha));

      return accesos;
    } catch (e) {
      print('Error al obtener accesos predeterminados: $e');
      return [];
    }
  }

  /// Crear un nuevo acceso predeterminado
  Future<String?> createAccesoPredeterminado(String condominioId, AccesoPredeterminado acceso) async {
    try {
      // Verificar que no exceda el límite de 3 accesos predeterminados
      List<AccesoPredeterminado> accesosExistentes = await getAccesosPredeterminados(condominioId, acceso.uidResidente);
      
      if (accesosExistentes.length >= 3) {
        throw Exception('No se pueden crear más de 3 accesos predeterminados por residente');
      }

      DocumentReference docRef = await _getAccesosPredeterminadosRef(condominioId).add(acceso.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error al crear acceso predeterminado: $e');
      return null;
    }
  }

  /// Actualizar un acceso predeterminado existente
  Future<bool> updateAccesoPredeterminado(String condominioId, String accesoId, AccesoPredeterminado acceso) async {
    try {
      await _getAccesosPredeterminadosRef(condominioId).doc(accesoId).update(acceso.toFirestore());
      return true;
    } catch (e) {
      print('Error al actualizar acceso predeterminado: $e');
      return false;
    }
  }

  /// Eliminar un acceso predeterminado
  Future<bool> deleteAccesoPredeterminado(String condominioId, String accesoId) async {
    try {
      await _getAccesosPredeterminadosRef(condominioId).doc(accesoId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar acceso predeterminado: $e');
      return false;
    }
  }

  /// Registrar acceso desde un acceso predeterminado
  Future<String?> registrarAccesoDesdePredeterminado(String condominioId, AccesoPredeterminado accesoPredeterminado) async {
    try {
      // Convertir el acceso predeterminado a un registro de control diario
      ControlDiario controlDiario = accesoPredeterminado.toControlDiario();
      
      // Guardar en control diario
      String? registroId = await addControlDiario(condominioId, controlDiario);
      
      return registroId;
    } catch (e) {
      print('Error al registrar acceso desde predeterminado: $e');
      return null;
    }
  }

  // ==================== GESTIÓN DEL CONTROL DIARIO ====================

  /// Agregar nuevo registro de control diario
  Future<String?> addControlDiario(String condominioId, ControlDiario controlDiario) async {
    try {
      DocumentReference docRef = await _getControlDiarioRef(condominioId).add(controlDiario.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error al agregar control diario: $e');
      return null;
    }
  }

  /// Actualizar registro de control diario
  Future<bool> updateControlDiario(String condominioId, String registroId, ControlDiario controlDiario) async {
    try {
      await _getControlDiarioRef(condominioId).doc(registroId).update(controlDiario.toFirestore());
      return true;
    } catch (e) {
      print('Error al actualizar control diario: $e');
      return false;
    }
  }

  /// Eliminar registro de control diario
  Future<bool> deleteControlDiario(String condominioId, String registroId) async {
    try {
      await _getControlDiarioRef(condominioId).doc(registroId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar control diario: $e');
      return false;
    }
  }

  /// Obtener registros de control diario del día actual
  Stream<List<ControlDiario>> getControlDiarioHoy(String condominioId) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _getControlDiarioRef(condominioId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ControlDiario.fromFirestore(doc))
            .toList());
  }

  /// Obtener registros de control diario con filtros
  Future<List<ControlDiario>> getControlDiarioConFiltros(
    String condominioId,
    FiltroControlAcceso filtro, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _getControlDiarioRef(condominioId);

      // Aplicar filtros de fecha
      if (filtro.fechaInicio != null) {
        query = query.where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(filtro.fechaInicio!));
      }
      if (filtro.fechaFin != null) {
        DateTime endOfDay = DateTime(
          filtro.fechaFin!.year,
          filtro.fechaFin!.month,
          filtro.fechaFin!.day,
          23, 59, 59,
        );
        query = query.where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      // Aplicar otros filtros
      if (filtro.tipoIngreso != null && filtro.tipoIngreso!.isNotEmpty) {
        query = query.where('tipoIngreso', isEqualTo: filtro.tipoIngreso);
      }
      if (filtro.tipoTransporte != null && filtro.tipoTransporte!.isNotEmpty) {
        query = query.where('tipoTransporte', isEqualTo: filtro.tipoTransporte);
      }
      if (filtro.vivienda != null && filtro.vivienda!.isNotEmpty) {
        query = query.where('vivienda', isEqualTo: filtro.vivienda);
      }

      // Ordenar por fecha descendente
      query = query.orderBy('fecha', descending: true);

      // Paginación
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();
      List<ControlDiario> registros = snapshot.docs
          .map((doc) => ControlDiario.fromFirestore(doc))
          .toList();

      // Aplicar filtros que no se pueden hacer en Firestore
      if (filtro.nombre != null && filtro.nombre!.isNotEmpty) {
        registros = registros.where((registro) =>
            registro.nombre.toLowerCase().contains(filtro.nombre!.toLowerCase())).toList();
      }
      if (filtro.rut != null && filtro.rut!.isNotEmpty) {
        registros = registros.where((registro) =>
            registro.rut.contains(filtro.rut!)).toList();
      }

      return registros;
    } catch (e) {
      print('Error al obtener control diario con filtros: $e');
      return [];
    }
  }

  /// Obtener estadísticas del control de acceso
  Future<Map<String, dynamic>> getEstadisticasControlAcceso(String condominioId, DateTime fecha) async {
    try {
      DateTime startOfDay = DateTime(fecha.year, fecha.month, fecha.day);
      DateTime endOfDay = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      QuerySnapshot snapshot = await _getControlDiarioRef(condominioId)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      List<ControlDiario> registros = snapshot.docs
          .map((doc) => ControlDiario.fromFirestore(doc))
          .toList();

      Map<String, int> tiposIngreso = {};
      Map<String, int> tiposTransporte = {};
      int totalRegistros = registros.length;
      int usanEstacionamiento = 0;

      for (ControlDiario registro in registros) {
        // Contar tipos de ingreso
        tiposIngreso[registro.tipoIngreso] = (tiposIngreso[registro.tipoIngreso] ?? 0) + 1;
        
        // Contar tipos de transporte
        tiposTransporte[registro.tipoTransporte] = (tiposTransporte[registro.tipoTransporte] ?? 0) + 1;
        
        // Contar uso de estacionamiento
        if (registro.usaEstacionamiento.isNotEmpty) {
          usanEstacionamiento++;
        }
      }

      return {
        'totalRegistros': totalRegistros,
        'tiposIngreso': tiposIngreso,
        'tiposTransporte': tiposTransporte,
        'usanEstacionamiento': usanEstacionamiento,
        'porcentajeEstacionamiento': totalRegistros > 0 ? (usanEstacionamiento / totalRegistros * 100).round() : 0,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {
        'totalRegistros': 0,
        'tiposIngreso': <String, int>{},
        'tiposTransporte': <String, int>{},
        'usanEstacionamiento': 0,
        'porcentajeEstacionamiento': 0,
      };
    }
  }

  /// Buscar registros por RUT o nombre
  Future<List<ControlDiario>> buscarRegistros(String condominioId, String termino) async {
    try {
      // Buscar por RUT
      QuerySnapshot snapshotRut = await _getControlDiarioRef(condominioId)
          .where('rut', isGreaterThanOrEqualTo: termino)
          .where('rut', isLessThan: termino + 'z')
          .limit(20)
          .get();

      // Buscar por nombre (esto requiere filtrado local ya que Firestore no soporta búsqueda de texto completo)
      QuerySnapshot snapshotNombre = await _getControlDiarioRef(condominioId)
          .orderBy('nombre')
          .limit(100)
          .get();

      Set<String> idsEncontrados = {};
      List<ControlDiario> resultados = [];

      // Agregar resultados de búsqueda por RUT
      for (QueryDocumentSnapshot doc in snapshotRut.docs) {
        ControlDiario registro = ControlDiario.fromFirestore(doc);
        resultados.add(registro);
        idsEncontrados.add(registro.id);
      }

      // Agregar resultados de búsqueda por nombre (filtrado local)
      for (QueryDocumentSnapshot doc in snapshotNombre.docs) {
        ControlDiario registro = ControlDiario.fromFirestore(doc);
        if (!idsEncontrados.contains(registro.id) &&
            registro.nombre.toLowerCase().contains(termino.toLowerCase())) {
          resultados.add(registro);
        }
      }

      // Ordenar por fecha descendente
      resultados.sort((a, b) => b.fecha.compareTo(a.fecha));

      return resultados.take(20).toList();
    } catch (e) {
      print('Error al buscar registros: $e');
      return [];
    }
  }

  /// Exportar datos para un rango de fechas
  Future<List<ControlDiario>> exportarDatos(String condominioId, DateTime fechaInicio, DateTime fechaFin) async {
    try {
      DateTime endOfDay = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);

      QuerySnapshot snapshot = await _getControlDiarioRef(condominioId)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('fecha', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ControlDiario.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al exportar datos: $e');
      return [];
    }
  }

  /// Obtener registros históricos agrupados por fecha
  Future<Map<String, List<ControlDiario>>> getRegistrosHistoricosPorFecha(
    String condominioId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int limit = 100,
  }) async {
    try {
      Query query = _getControlDiarioRef(condominioId);

      // Si no se especifica fecha de inicio, obtener registros de los últimos 30 días
      DateTime startDate = fechaInicio ?? DateTime.now().subtract(const Duration(days: 30));
      DateTime endDate = fechaFin ?? DateTime.now();
      DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      query = query
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('fecha', descending: true)
          .limit(limit);

      QuerySnapshot snapshot = await query.get();
      List<ControlDiario> registros = snapshot.docs
          .map((doc) => ControlDiario.fromFirestore(doc))
          .toList();

      // Agrupar registros por fecha
      Map<String, List<ControlDiario>> registrosAgrupados = {};
      
      for (ControlDiario registro in registros) {
        String fechaKey = registro.fechaFormateada;
        
        if (!registrosAgrupados.containsKey(fechaKey)) {
          registrosAgrupados[fechaKey] = [];
        }
        
        registrosAgrupados[fechaKey]!.add(registro);
      }

      // Ordenar registros dentro de cada día por hora (más reciente primero)
      registrosAgrupados.forEach((fecha, listaRegistros) {
        listaRegistros.sort((a, b) {
          final horaA = _parseHora(a.hora);
          final horaB = _parseHora(b.hora);
          final dateTimeA = DateTime(2000, 1, 1, horaA.hour, horaA.minute);
          final dateTimeB = DateTime(2000, 1, 1, horaB.hour, horaB.minute);
          return dateTimeB.compareTo(dateTimeA);
        });
      });

      return registrosAgrupados;
    } catch (e) {
      print('Error al obtener registros históricos por fecha: $e');
      return {};
    }
  }

  /// Método auxiliar para parsear hora en formato HH:mm
  TimeOfDay _parseHora(String hora) {
    try {
      List<String> partes = hora.split(':');
      if (partes.length == 2) {
        int horas = int.parse(partes[0]);
        int minutos = int.parse(partes[1]);
        return TimeOfDay(hour: horas, minute: minutos);
      }
    } catch (e) {
      print('Error al parsear hora: $hora');
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }
}