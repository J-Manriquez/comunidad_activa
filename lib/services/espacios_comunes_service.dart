import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reserva_model.dart';
import '../models/espacio_comun_model.dart';
import '../models/revision_uso_model.dart';
import 'notification_service.dart';
import 'package:flutter/services.dart';

class EspaciosComunesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ==================== ESPACIOS COMUNES ====================

  /// Crear un nuevo espacio común
  Future<void> crearEspacioComun({
    required String condominioId,
    required String nombre,
    required int capacidad,
    int? precio,
    required String estado,
    required String tiempoUso,
    String? descripcion,
    String? horaApertura,
    String? horaCierre,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final docRef = _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('espaciosComunes')
          .doc();

      final espacioComun = EspacioComunModel(
        id: docRef.id,
        nombre: nombre,
        capacidad: capacidad,
        precio: precio,
        estado: estado,
        tiempoUso: tiempoUso,
        descripcion: descripcion,
        horaApertura: horaApertura,
        horaCierre: horaCierre,
        additionalData: additionalData,
      );

      await docRef.set(espacioComun.toFirestore());
    } catch (e) {
      print('❌ Error al crear espacio común: $e');
      throw Exception('Error al crear espacio común: $e');
    }
  }

  /// Obtener todos los espacios comunes
  Future<List<EspacioComunModel>> obtenerEspaciosComunes(String condominioId) async {
    try {
      print('🔍 [DEBUG] Iniciando obtenerEspaciosComunes con condominioId: $condominioId');
      
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('espaciosComunes')
          .orderBy('nombre')
          .get();

      print('📊 [DEBUG] Documentos encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ [DEBUG] No se encontraron espacios comunes para el condominioId: $condominioId');
        return [];
      }

      final espacios = snapshot.docs
          .map((doc) {
            print('📄 [DEBUG] Procesando documento: ${doc.id}');
            print('📄 [DEBUG] Datos del documento: ${doc.data()}');
            try {
              final espacio = EspacioComunModel.fromFirestore(doc.data(), doc.id);
              print('✅ [DEBUG] Espacio creado exitosamente: ${espacio.nombre} (ID: ${espacio.id})');
              return espacio;
            } catch (e) {
              print('❌ [DEBUG] Error al crear EspacioComunModel desde documento ${doc.id}: $e');
              rethrow;
            }
          })
          .toList();

      print('🎯 [DEBUG] Total de espacios procesados: ${espacios.length}');
      for (final espacio in espacios) {
        print('📋 [DEBUG] Espacio: ${espacio.nombre}, Estado: ${espacio.estado}, ID: ${espacio.id}');
      }
      
      return espacios;
    } catch (e) {
      print('💥 [DEBUG] Error en obtenerEspaciosComunes: $e');
      throw Exception('Error al obtener espacios comunes: $e');
    }
  }

  /// Obtener un espacio común por ID
  Future<EspacioComunModel?> obtenerEspacioComunPorId(String condominioId, String espacioId) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('espaciosComunes')
          .doc(espacioId)
          .get();

      if (doc.exists) {
        return EspacioComunModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener espacio común: $e');
      throw Exception('Error al obtener espacio común: $e');
    }
  }

  /// Actualizar un espacio común
  Future<void> actualizarEspacioComun({
    required String condominioId,
    required String espacioId,
    required String nombre,
    required int capacidad,
    int? precio,
    required String estado,
    required String tiempoUso,
    String? descripcion,
    String? horaApertura,
    String? horaCierre,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('espaciosComunes')
          .doc(espacioId)
          .update({
        'nombre': nombre,
        'capacidad': capacidad,
        'precio': precio,
        'estado': estado,
        'tiempoUso': tiempoUso,
        'descripcion': descripcion,
        'horaApertura': horaApertura,
        'horaCierre': horaCierre,
        'additionalData': additionalData,
      });
    } catch (e) {
      print('❌ Error al actualizar espacio común: $e');
      throw Exception('Error al actualizar espacio común: $e');
    }
  }

  /// Eliminar un espacio común
  Future<void> eliminarEspacioComun(String condominioId, String espacioId) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('espaciosComunes')
          .doc(espacioId)
          .delete();
    } catch (e) {
      print('❌ Error al eliminar espacio común: $e');
      throw Exception('Error al eliminar espacio común: $e');
    }
  }

  // ==================== RESERVAS ====================

  /// Crear una nueva reserva
  Future<void> crearReserva({
    required String condominioId,
    required String fechaHoraReserva,
    required List<String> participantes,
    required String espacioComunId,
    required String nombreEspacioComun,
    required List<String> idSolicitante,
    required String vivienda,
  }) async {
    try {
      final docRef = _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc();

      final reserva = ReservaModel(
        id: docRef.id,
        fechaHoraSolicitud: DateTime.now().toIso8601String(),
        fechaHoraReserva: fechaHoraReserva,
        participantes: participantes,
        espacioComunId: espacioComunId,
        nombreEspacioComun: nombreEspacioComun,
        estado: 'pendiente',
        idSolicitante: idSolicitante,
        vivienda: vivienda,
      );

      await docRef.set(reserva.toFirestore());
    } catch (e) {
      print('❌ Error al crear reserva: $e');
      throw Exception('Error al crear reserva: $e');
    }
  }

  /// Crear una nueva reserva (versión simplificada para residentes)
  Future<void> crearReservaResidente({
    required String condominioId,
    required String espacioId,
    required String residenteId,
    required String nombreResidente,
    required String nombreEspacio,
    required DateTime fechaUso,
    required String horaInicio,
    required String horaFin,
    required String motivo,
    required int cantidadPersonas,
    required String vivienda,
  }) async {
    try {
      // Crear fechas completas para validación
      final horaInicioSplit = horaInicio.split(':');
      final horaFinSplit = horaFin.split(':');
      
      final fechaInicio = DateTime(
        fechaUso.year,
        fechaUso.month,
        fechaUso.day,
        int.parse(horaInicioSplit[0]),
        int.parse(horaInicioSplit[1]),
      );
      
      final fechaFin = DateTime(
        fechaUso.year,
        fechaUso.month,
        fechaUso.day,
        int.parse(horaFinSplit[0]),
        int.parse(horaFinSplit[1]),
      );

      // Verificar disponibilidad de horario
      final disponible = await verificarDisponibilidadHorario(
        condominioId: condominioId,
        espacioId: espacioId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      if (!disponible) {
        throw Exception('El horario seleccionado no está disponible. Ya existe una reserva aceptada o pendiente para ese período.');
      }

      final docRef = _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc();

      final reserva = ReservaModel(
        id: docRef.id,
        // Campos originales para compatibilidad
        espacioComunId: espacioId,
        nombreEspacioComun: nombreEspacio,
        fechaHoraReserva: fechaInicio.toIso8601String(),
        fechaHoraSolicitud: DateTime.now().toIso8601String(),
        idSolicitante: [residenteId],
        vivienda: vivienda,
        participantes: List.generate(cantidadPersonas, (index) => index == 0 ? nombreResidente : 'Acompañante ${index + 1}'),
        estado: 'pendiente',
        nombreResidente: nombreResidente,
        // Nuevos campos para residentes
        espacioId: espacioId,
        residenteId: residenteId,
        nombreEspacio: nombreEspacio,
        fechaUso: fechaUso,
        horaInicio: horaInicio,
        horaFin: horaFin,
        motivo: motivo,
        fechaSolicitud: DateTime.now(),
      );

      await docRef.set(reserva.toFirestore());
    } catch (e) {
      print('❌ Error al crear reserva: $e');
      throw Exception('Error al crear reserva: $e');
    }
  }

  /// Obtener todas las reservas
  Future<List<ReservaModel>> obtenerReservas(String condominioId) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .orderBy('fechaHoraSolicitud', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener reservas: $e');
      throw Exception('Error al obtener reservas: $e');
    }
  }

  /// Obtener reservas pendientes
  Future<List<ReservaModel>> obtenerReservasPendientes(String condominioId) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fechaHoraSolicitud', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener reservas pendientes: $e');
      throw Exception('Error al obtener reservas pendientes: $e');
    }
  }

  /// Obtener reservas aceptadas sin revisión post-uso
  Future<List<ReservaModel>> obtenerReservasSinRevision(String condominioId) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('estado', isEqualTo: 'aprobada')
          .get();

      final reservas = snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .where((reserva) {
            // Si no tiene revisiones, debe aparecer
            if (reserva.revisionesUso == null || reserva.revisionesUso!.isEmpty) {
              return true;
            }
            
            // Si tiene revisiones, verificar si NO tiene revisión post_uso
            final tienePostUso = reserva.revisionesUso!.any(
              (revision) => revision.tipoRevision == 'post_uso'
            );
            
            // Solo mostrar si NO tiene revisión post_uso
            // (puede tener solo pre_uso o ninguna)
            return !tienePostUso;
          })
          .toList();
          
      print('🔍 [Admin] Reservas encontradas: ${snapshot.docs.length}');
      print('🔍 [Admin] Reservas filtradas (sin post_uso): ${reservas.length}');
      for (final reserva in reservas) {
        final numRevisiones = reserva.revisionesUso?.length ?? 0;
        final tiposRevisiones = reserva.revisionesUso?.map((r) => r.tipoRevision).join(', ') ?? 'ninguna';
        print('   - ${reserva.nombreEspacioComun}: $numRevisiones revisiones ($tiposRevisiones)');
      }

      return reservas;
    } catch (e) {
      print('❌ Error al obtener reservas sin revisión: $e');
      throw Exception('Error al obtener reservas sin revisión: $e');
    }
  }

  /// Obtener reservas rechazadas
  Future<List<ReservaModel>> obtenerReservasRechazadas(String condominioId) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('estado', isEqualTo: 'rechazado')
          .orderBy('fechaHoraSolicitud', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener reservas rechazadas: $e');
      throw Exception('Error al obtener reservas rechazadas: $e');
    }
  }

  /// Aprobar reserva
  Future<void> aprobarReserva(String condominioId, String reservaId) async {
    try {
      // Obtener los datos de la reserva antes de aprobarla
      final reservaDoc = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .get();

      if (!reservaDoc.exists) {
        throw Exception('La reserva no existe');
      }

      final reserva = ReservaModel.fromFirestore(reservaDoc.data()!, reservaDoc.id);
      
      // Verificar disponibilidad de horario (excluyendo esta reserva)
      final fechaInicio = DateTime.parse(reserva.fechaHoraReserva);
      
      // Obtener fecha de fin de la reserva
      DateTime fechaFin;
      if (reserva.fechaHoraFinReserva != null) {
        fechaFin = DateTime.parse(reserva.fechaHoraFinReserva!);
      } else if (reserva.horaFin != null) {
        // Si no hay fechaHoraFinReserva pero sí horaFin, construir la fecha
        final horaFinParts = reserva.horaFin!.split(':');
        fechaFin = DateTime(
          fechaInicio.year,
          fechaInicio.month,
          fechaInicio.day,
          int.parse(horaFinParts[0]),
          int.parse(horaFinParts[1]),
        );
      } else {
        // Si no hay información de fin, asumir 1 hora de duración
        fechaFin = fechaInicio.add(Duration(hours: 1));
      }
      
      final disponible = await verificarDisponibilidadHorario(
        condominioId: condominioId,
        espacioId: reserva.espacioComunId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        reservaIdExcluir: reservaId,
      );

      if (!disponible) {
        throw Exception('No se puede aprobar la reserva. Ya existe otra reserva aceptada para el mismo horario y fecha.');
      }

      await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .update({'estado': 'aprobada'});

      // Enviar notificación al residente
      await _notificationService.createUserNotification(
        condominioId: condominioId,
        userId: reserva.residenteId!,
        userType: 'residentes',
        tipoNotificacion: 'reserva_aprobada',
        contenido: 'Su solicitud de reserva para ${reserva.nombreEspacio} ha sido aprobada.',
        additionalData: {
          'reservaId': reservaId,
          'nombreEspacio': reserva.nombreEspacio,
          'fechaUso': reserva.fechaUso?.toIso8601String(),
          'horaInicio': reserva.horaInicio,
          'horaFin': reserva.horaFin,
          'fechaAprobacion': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Error al aprobar reserva: $e');
      throw Exception('Error al aprobar reserva: $e');
    }
  }

  /// Rechazar reserva
  Future<void> rechazarReserva(String condominioId, String reservaId, {String? motivoRechazo}) async {
    try {
      // Obtener los datos de la reserva antes de rechazarla
      final reservaDoc = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .get();

      if (!reservaDoc.exists) {
        throw Exception('La reserva no existe');
      }

      final reserva = ReservaModel.fromFirestore(reservaDoc.data()!, reservaDoc.id);
      
      await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .update({'estado': 'rechazado'});

      // Construir el contenido de la notificación
      String contenidoNotificacion = 'Su solicitud de reserva para ${reserva.nombreEspacio} ha sido rechazada.';
      if (motivoRechazo != null && motivoRechazo.isNotEmpty) {
        contenidoNotificacion += '\n\nMotivo: $motivoRechazo';
      }

      // Enviar notificación al residente
      await _notificationService.createUserNotification(
        condominioId: condominioId,
        userId: reserva.residenteId!,
        userType: 'residentes',
        tipoNotificacion: 'reserva_rechazada',
        contenido: contenidoNotificacion,
        additionalData: {
          'reservaId': reservaId,
          'nombreEspacio': reserva.nombreEspacio,
          'fechaUso': reserva.fechaUso?.toIso8601String(),
          'horaInicio': reserva.horaInicio,
          'horaFin': reserva.horaFin,
          'fechaRechazo': DateTime.now().toIso8601String(),
          'motivoRechazo': motivoRechazo,
        },
      );
    } catch (e) {
      print('❌ Error al rechazar reserva: $e');
      throw Exception('Error al rechazar reserva: $e');
    }
  }

  // ==================== REVISIONES POST-USO ====================

  /// Agregar revisión pre/post-uso a una reserva
  Future<void> agregarRevisionPostUso({
    required String condominioId,
    required String reservaId,
    required String descripcion,
    required String estado,
    required String tipoRevision, // 'pre_uso' o 'post_uso'
    int? costo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final revisionId = _firestore.collection('temp').doc().id;
      
      final revision = RevisionUsoModel(
        id: revisionId,
        fecha: DateTime.now().toIso8601String(),
        descripcion: descripcion,
        estado: estado,
        costo: costo,
        tipoRevision: tipoRevision,
        additionalData: additionalData,
      );

      // Obtener la reserva actual para agregar la nueva revisión
      final reservaDoc = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .get();
      
      final reservaData = reservaDoc.data();
      final revisionesExistentes = reservaData?['revisionesUso'] as Map<String, dynamic>? ?? {};
      
      // Agregar la nueva revisión
      revisionesExistentes[revisionId] = revision.toFirestore();

      await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .doc(reservaId)
          .update({
        'revisionesUso': revisionesExistentes,
      });
      
      print('✅ Revisión $tipoRevision agregada exitosamente a reserva $reservaId');
      print('📊 Total de revisiones en la reserva: ${revisionesExistentes.length}');
    } catch (e) {
      print('❌ Error al agregar revisión: $e');
      throw Exception('Error al agregar revisión: $e');
    }
  }

  /// Obtener reservas con revisiones (historial)
  Future<List<ReservaModel>> obtenerHistorialRevisiones(String condominioId) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('estado', isEqualTo: 'aprobada')
          .orderBy('fechaHoraSolicitud', descending: true)
          .get();

      final reservas = snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .where((reserva) => reserva.revisionesUso != null && reserva.revisionesUso!.isNotEmpty)
          .toList();

      return reservas;
    } catch (e) {
      print('❌ Error al obtener historial de revisiones: $e');
      throw Exception('Error al obtener historial de revisiones: $e');
    }
  }

  // ==================== MÉTODOS PARA RESIDENTES ====================

  /// Obtener reservas por residente
   Future<List<ReservaModel>> obtenerReservasPorResidente(
       String condominioId, String residenteId) async {
     try {
       final snapshot = await _firestore
           .collection(condominioId)
           .doc('espaciosComunes')
           .collection('reservas')
           .where('idSolicitante', arrayContains: residenteId)
           .get();
 
       final reservas = snapshot.docs
           .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
           .toList();
       
       // Ordenar manualmente por fecha de solicitud
       reservas.sort((a, b) {
         final fechaA = DateTime.tryParse(a.fechaHoraSolicitud) ?? DateTime.now();
         final fechaB = DateTime.tryParse(b.fechaHoraSolicitud) ?? DateTime.now();
         return fechaB.compareTo(fechaA);
       });
       
       return reservas;
     } catch (e) {
       print('❌ Error al obtener reservas por residente: $e');
       throw Exception('Error al obtener reservas por residente: $e');
     }
   }

  /// Obtener reservas por espacio y fecha
  Future<List<ReservaModel>> obtenerReservasPorEspacioYFecha(
      String condominioId, String espacioId, DateTime fecha) async {
    try {
      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('espacioComunId', isEqualTo: espacioId)
          .get();

      final reservas = snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .where((reserva) {
            final fechaReserva = DateTime.parse(reserva.fechaHoraReserva);
            return fechaReserva.isAfter(inicioDelDia.subtract(Duration(seconds: 1))) &&
                   fechaReserva.isBefore(finDelDia.add(Duration(seconds: 1)));
          })
          .toList();

      return reservas;
    } catch (e) {
      print('❌ Error al obtener reservas por espacio y fecha: $e');
      throw Exception('Error al obtener reservas por espacio y fecha: $e');
    }
  }

  /// Verificar disponibilidad de horario para un espacio común
  Future<bool> verificarDisponibilidadHorario({
    required String condominioId,
    required String espacioId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? reservaIdExcluir, // Para excluir una reserva específica (útil al editar)
  }) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('espacioComunId', isEqualTo: espacioId)
          .where('estado', whereIn: ['pendiente', 'aprobada'])
          .get();

      final reservasExistentes = snapshot.docs
          .map((doc) => ReservaModel.fromFirestore(doc.data(), doc.id))
          .where((reserva) => reservaIdExcluir == null || reserva.id != reservaIdExcluir)
          .toList();

      // Verificar si hay conflicto de horarios
      for (final reserva in reservasExistentes) {
        final fechaInicioExistente = DateTime.parse(reserva.fechaHoraReserva);
        
        // Obtener fecha de fin de la reserva existente
        DateTime fechaFinExistente;
        if (reserva.fechaHoraFinReserva != null) {
          fechaFinExistente = DateTime.parse(reserva.fechaHoraFinReserva!);
        } else if (reserva.horaFin != null) {
          // Si no hay fechaHoraFinReserva pero sí horaFin, construir la fecha
          final horaFinParts = reserva.horaFin!.split(':');
          fechaFinExistente = DateTime(
            fechaInicioExistente.year,
            fechaInicioExistente.month,
            fechaInicioExistente.day,
            int.parse(horaFinParts[0]),
            int.parse(horaFinParts[1]),
          );
        } else {
          // Si no hay información de fin, asumir 1 hora de duración
          fechaFinExistente = fechaInicioExistente.add(Duration(hours: 1));
        }

        // Verificar solapamiento de horarios
        if (fechaInicio.isBefore(fechaFinExistente) && fechaFin.isAfter(fechaInicioExistente)) {
          return false; // Hay conflicto
        }
      }

      return true; // No hay conflicto, horario disponible
    } catch (e) {
      print('❌ Error al verificar disponibilidad de horario: $e');
      throw Exception('Error al verificar disponibilidad de horario: $e');
    }
  }

  /// Obtener horarios ocupados para un espacio y fecha específica
  Future<List<Map<String, dynamic>>> obtenerHorariosOcupados({
    required String condominioId,
    required String espacioId,
    required DateTime fecha,
  }) async {
    try {
      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(condominioId)
          .doc('espaciosComunes')
          .collection('reservas')
          .where('espacioComunId', isEqualTo: espacioId)
          .where('estado', whereIn: ['pendiente', 'aprobada'])
          .get();

      final horariosOcupados = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final reserva = ReservaModel.fromFirestore(doc.data(), doc.id);
        final fechaInicioReserva = DateTime.parse(reserva.fechaHoraReserva);
        
        // Obtener fecha de fin de la reserva
        DateTime fechaFinReserva;
        if (reserva.fechaHoraFinReserva != null) {
          fechaFinReserva = DateTime.parse(reserva.fechaHoraFinReserva!);
        } else if (reserva.horaFin != null) {
          // Si no hay fechaHoraFinReserva pero sí horaFin, construir la fecha
          final horaFinParts = reserva.horaFin!.split(':');
          fechaFinReserva = DateTime(
            fechaInicioReserva.year,
            fechaInicioReserva.month,
            fechaInicioReserva.day,
            int.parse(horaFinParts[0]),
            int.parse(horaFinParts[1]),
          );
        } else {
          // Si no hay información de fin, asumir 1 hora de duración
          fechaFinReserva = fechaInicioReserva.add(Duration(hours: 1));
        }

        // Verificar si la reserva está en el día solicitado
        if (fechaInicioReserva.isAfter(inicioDelDia.subtract(Duration(seconds: 1))) &&
            fechaInicioReserva.isBefore(finDelDia.add(Duration(seconds: 1)))) {
          horariosOcupados.add({
            'horaInicio': '${fechaInicioReserva.hour.toString().padLeft(2, '0')}:${fechaInicioReserva.minute.toString().padLeft(2, '0')}',
            'horaFin': '${fechaFinReserva.hour.toString().padLeft(2, '0')}:${fechaFinReserva.minute.toString().padLeft(2, '0')}',
            'estado': reserva.estado,
            'nombreSolicitante': reserva.nombreSolicitante ?? reserva.nombreResidente ?? 'Usuario',
          });
        }
      }

      // Ordenar por hora de inicio
      horariosOcupados.sort((a, b) => a['horaInicio'].compareTo(b['horaInicio']));

      return horariosOcupados;
    } catch (e) {
      print('❌ Error al obtener horarios ocupados: $e');
      throw Exception('Error al obtener horarios ocupados: $e');
    }
  }
}