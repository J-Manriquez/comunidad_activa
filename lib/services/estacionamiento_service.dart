import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estacionamiento_model.dart';
import '../models/historial_estacionamiento_visita_model.dart';
import '../models/residente_model.dart';

class EstacionamientoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener configuración de estacionamientos
  Future<Map<String, dynamic>> obtenerConfiguracion(String condominioId) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      throw Exception('Error al obtener configuración: $e');
    }
  }

  // Crear o actualizar la configuración de estacionamientos
  Future<void> actualizarConfiguracion(
    String condominioId,
    Map<String, dynamic> configuracion,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .set(configuracion, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al actualizar configuración: $e');
    }
  }

  // Activar/desactivar estacionamientos
  Future<bool> cambiarEstadoActivo(String condominioId, bool activo) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .set({'activo': activo}, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error al cambiar estado de estacionamientos: $e');
      return false;
    }
  }

  // Actualizar configuración de selección
  Future<bool> actualizarConfiguracionSeleccion(
    String condominioId,
    bool permitirSeleccion,
    bool autoAsignacion,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .set({
        'permitirSeleccion': permitirSeleccion,
        'autoAsignacion': autoAsignacion,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error al actualizar configuración de selección: $e');
      return false;
    }
  }

  // Crear/actualizar estacionamientos preservando datos existentes
  Future<bool> crearEstacionamientos(
    String condominioId,
    List<String> numeracion,
    {bool esVisita = false}
  ) async {
    try {
      print('🟡 [ESTACIONAMIENTO_SERVICE] Iniciando configuración de estacionamientos');
      print('   - Tipo: ${esVisita ? "Visitas" : "Normales"}');
      print('   - Nueva numeración: $numeracion');
      
      final estacionamientosRef = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos');

      // 1. Obtener estacionamientos existentes del tipo correspondiente
      final existingQuery = await estacionamientosRef
          .where('estVisita', isEqualTo: esVisita)
          .get();
      
      final existingEstacionamientos = <String, EstacionamientoModel>{};
      for (final doc in existingQuery.docs) {
        final estacionamiento = EstacionamientoModel.fromFirestore(
          doc.data(),
          doc.id,
        );
        existingEstacionamientos[estacionamiento.nroEstacionamiento] = estacionamiento;
      }
      
      print('🟡 [ESTACIONAMIENTO_SERVICE] Estacionamientos existentes: ${existingEstacionamientos.keys.toList()}');
      
      // 2. Determinar qué estacionamientos crear, mantener y eliminar
      final nuevosNumeros = Set<String>.from(numeracion);
      final existentesNumeros = Set<String>.from(existingEstacionamientos.keys);
      
      final paraCrear = nuevosNumeros.difference(existentesNumeros);
      final paraEliminar = existentesNumeros.difference(nuevosNumeros);
      final paraConservar = nuevosNumeros.intersection(existentesNumeros);
      
      print('🟡 [ESTACIONAMIENTO_SERVICE] Análisis de cambios:');
      print('   - Para crear: $paraCrear');
      print('   - Para eliminar: $paraEliminar');
      print('   - Para conservar: $paraConservar');
      
      final batch = _firestore.batch();
      
      // 3. Crear nuevos estacionamientos
      for (String numero in paraCrear) {
        final docId = esVisita ? 'visita-$numero' : numero;
        final docRef = estacionamientosRef.doc(docId);
        
        final estacionamiento = EstacionamientoModel(
          id: docId,
          estVisita: esVisita,
          nroEstacionamiento: numero,
        );

        batch.set(docRef, estacionamiento.toFirestore());
        print('🟢 [ESTACIONAMIENTO_SERVICE] Creando nuevo estacionamiento: $numero');
      }
      
      // 4. Eliminar estacionamientos que ya no están en la configuración
      for (String numero in paraEliminar) {
        final docId = esVisita ? 'visita-$numero' : numero;
        final docRef = estacionamientosRef.doc(docId);
        batch.delete(docRef);
        print('🔴 [ESTACIONAMIENTO_SERVICE] Eliminando estacionamiento: $numero');
      }
      
      // 5. Los estacionamientos en paraConservar se mantienen sin cambios
      for (String numero in paraConservar) {
        print('🔵 [ESTACIONAMIENTO_SERVICE] Conservando estacionamiento existente: $numero');
      }

      await batch.commit();
      
      // 6. Actualizar la configuración con la nueva numeración
      if (esVisita) {
        await _firestore
            .collection(condominioId)
            .doc('estacionamiento')
            .set({
          'numeracionestVisitas': numeracion,
          'cantidadEstVisitas': numeracion.length,
        }, SetOptions(merge: true));
      } else {
        await _firestore
            .collection(condominioId)
            .doc('estacionamiento')
            .set({
          'numeracion': numeracion,
          'cantidadDisponible': numeracion.length,
        }, SetOptions(merge: true));
      }
      
      print('🟢 [ESTACIONAMIENTO_SERVICE] Configuración completada exitosamente');
      print('   - Creados: ${paraCrear.length}');
      print('   - Eliminados: ${paraEliminar.length}');
      print('   - Conservados: ${paraConservar.length}');
      
      return true;
    } catch (e) {
      print('🔴 [ESTACIONAMIENTO_SERVICE] Error al configurar estacionamientos: $e');
      return false;
    }
  }

  // Obtener todos los estacionamientos
  Future<List<EstacionamientoModel>> obtenerEstacionamientos(
    String condominioId,
    {bool? soloVisitas}
  ) async {
    try {
      Query query = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos');

      if (soloVisitas != null) {
        query = query.where('estVisita', isEqualTo: soloVisitas);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EstacionamientoModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error al obtener estacionamientos: $e');
      return [];
    }
  }



  // Obtener un estacionamiento específico
  Future<EstacionamientoModel?> obtenerEstacionamiento(
    String condominioId,
    String numeroEstacionamiento,
  ) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(numeroEstacionamiento)
          .get();

      if (doc.exists) {
        return EstacionamientoModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener estacionamiento: $e');
    }
  }

  // Actualizar estacionamiento
  Future<bool> actualizarEstacionamiento(
    String condominioId,
    String estacionamientoId,
    Map<String, dynamic> datos,
  ) async {
    try {
      print('🔧 [SERVICIO] Actualizando estacionamiento:');
      print('  - Condominio ID: $condominioId');
      print('  - Estacionamiento ID: $estacionamientoId');
      print('  - Datos: $datos');
      
      final docRef = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(estacionamientoId);
      
      print('  - Ruta del documento: ${docRef.path}');
      
      await docRef.update(datos);
      
      print('  - ✅ Actualización completada exitosamente');
      
      // Verificar que se guardó correctamente
      final docActualizado = await docRef.get();
      if (docActualizado.exists) {
        print('  - 📋 Datos actualizados en Firestore: ${docActualizado.data()}');
      }
      
      return true;
    } catch (e) {
      print('❌ Error al actualizar estacionamiento: $e');
      return false;
    }
  }

  // Eliminar estacionamientos
  Future<bool> eliminarEstacionamientos(
    String condominioId,
    List<String> estacionamientoIds,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (String id in estacionamientoIds) {
        final docRef = _firestore
            .collection(condominioId)
            .doc('estacionamiento')
            .collection('estacionamientos')
            .doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error al eliminar estacionamientos: $e');
      return false;
    }
  }

  // Activar/desactivar estacionamientos de visitas
  Future<bool> cambiarEstadoEstacionamientosVisitas(
    String condominioId,
    bool estVisitas,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .set({'estVisitas': estVisitas}, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error al cambiar estado de estacionamientos de visitas: $e');
      return false;
    }
  }

  // Crear reserva de estacionamiento de visita
  Future<bool> crearReservaVisita(
    String condominioId,
    ReservaEstacionamientoVisitaModel reserva,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('visitas')
          .doc(reserva.id)
          .set(reserva.toFirestore());
      return true;
    } catch (e) {
      print('Error al crear reserva de visita: $e');
      return false;
    }
  }

  // Obtener reservas de estacionamientos de visitas
  Future<List<ReservaEstacionamientoVisitaModel>> obtenerReservasVisitas(
    String condominioId,
    {String? estado}
  ) async {
    try {
      Query query = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('visitas');

      if (estado != null) {
        query = query.where('estadoSolicitud', isEqualTo: estado);
      }

      final snapshot = await query.orderBy('fechaHoraSolicitud', descending: true).get();
      return snapshot.docs
          .map((doc) => ReservaEstacionamientoVisitaModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error al obtener reservas de visitas: $e');
      return [];
    }
  }

  // Actualizar estado de reserva de visita
  Future<bool> actualizarEstadoReservaVisita(
    String condominioId,
    String reservaId,
    String nuevoEstado,
    {String? respuesta}
  ) async {
    try {
      final datos = {
        'estadoSolicitud': nuevoEstado,
      };
      
      if (respuesta != null) {
        datos['respuestaSolicitud'] = respuesta;
      }
      
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('visitas')
          .doc(reservaId)
          .update(datos);
      return true;
    } catch (e) {
      print('Error al actualizar estado de reserva de visita: $e');
      return false;
    }
  }

  // Verificar si los estacionamientos están activos
  Future<bool> verificarEstacionamientosActivos(String condominioId) async {
    try {
      final configuracion = await obtenerConfiguracion(condominioId);
      return configuracion['activo'] ?? false;
    } catch (e) {
      print('Error al verificar estacionamientos activos: $e');
      return false;
    }
  }

  // Método para obtener todas las viviendas del condominio (basado en gastos comunes)
  Future<Map<String, List<String>>> obtenerTodasLasViviendas(String condominioId) async {
    try {
      print('🔍 [ESTACIONAMIENTOS] Iniciando obtención de viviendas para condominio: $condominioId');

      // Usar el mismo método que gastos comunes para obtener residentes
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      print('📊 [ESTACIONAMIENTOS] Documentos encontrados: ${querySnapshot.docs.length}');

      final Map<String, List<String>> viviendasPorTipo = {};
      final Set<String> viviendasUnicas = {};

      // Filtrar documentos igual que en gastos comunes
      final residentes = querySnapshot.docs
          .where((doc) => doc.id != '_placeholder') // Filtrar placeholder
          .map((doc) {
            try {
              return ResidenteModel.fromFirestore(doc);
            } catch (e) {
              print('❌ [ESTACIONAMIENTOS] Error al procesar residente ${doc.id}: $e');
              return null;
            }
          })
          .where((residente) => residente != null)
          .cast<ResidenteModel>()
          .toList();

      print('👥 [ESTACIONAMIENTOS] Residentes válidos procesados: ${residentes.length}');

      for (final residente in residentes) {
        print('👤 [ESTACIONAMIENTOS] Procesando residente: ${residente.nombre}');
        print('🏠 [ESTACIONAMIENTOS] Tipo vivienda: ${residente.tipoVivienda}');
        print('✅ [ESTACIONAMIENTOS] Estado vivienda: ${residente.viviendaSeleccionada}');

        final viviendaKey = residente.descripcionVivienda;
        print('🔑 [ESTACIONAMIENTOS] Clave de vivienda generada: "$viviendaKey"');

        // Solo procesar si tiene vivienda asignada y está seleccionada
        bool viviendaEstaSeleccionada =
            residente.viviendaSeleccionada == 'seleccionada' ||
            residente.viviendaSeleccionada == true;

        if (viviendaKey.isNotEmpty && viviendaEstaSeleccionada) {
          viviendasUnicas.add(viviendaKey);
          
          // Agrupar por tipo de vivienda
          String tipoVivienda;
          if (residente.tipoVivienda?.toLowerCase() == 'casa') {
            tipoVivienda = 'Casas';
          } else {
            tipoVivienda = 'Apartamentos';
          }
          
          if (!viviendasPorTipo.containsKey(tipoVivienda)) {
            viviendasPorTipo[tipoVivienda] = [];
          }
          
          if (!viviendasPorTipo[tipoVivienda]!.contains(viviendaKey)) {
            viviendasPorTipo[tipoVivienda]!.add(viviendaKey);
            print('✅ [ESTACIONAMIENTOS] Vivienda agregada: $tipoVivienda -> $viviendaKey');
          }
        } else {
          if (viviendaKey.isEmpty) {
            print('⚠️ [ESTACIONAMIENTOS] Residente ${residente.nombre} no tiene vivienda asignada válida');
          } else {
            print('⚠️ [ESTACIONAMIENTOS] Residente ${residente.nombre} tiene vivienda pero no está seleccionada');
          }
        }
      }

      print('📈 [ESTACIONAMIENTOS] Total de viviendas únicas: ${viviendasUnicas.length}');
      print('🏠 [ESTACIONAMIENTOS] Viviendas por tipo:');
      viviendasPorTipo.forEach((tipo, viviendas) {
        print('   - $tipo: ${viviendas.length} viviendas');
        viviendas.forEach((vivienda) => print('     * $vivienda'));
      });

      return viviendasPorTipo;
    } catch (e) {
      print('❌ [ESTACIONAMIENTOS] Error al obtener viviendas: $e');
      throw Exception('Error al obtener viviendas: $e');
    }
  }

  // Crear un nuevo estacionamiento
  Future<void> crearEstacionamiento(
    String condominioId,
    EstacionamientoModel estacionamiento,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(estacionamiento.nroEstacionamiento)
          .set(estacionamiento.toFirestore());
    } catch (e) {
      throw Exception('Error al crear estacionamiento: $e');
    }
  }

  // Método para asignar un estacionamiento a una vivienda
  Future<void> asignarEstacionamientoAVivienda(String condominioId, String numeroEstacionamiento, String viviendaAsignada) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(numeroEstacionamiento)
          .update({
        'viviendaAsignada': viviendaAsignada,
        'fechaAsignacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al asignar estacionamiento: $e');
    }
  }

  // Eliminar un estacionamiento
  Future<void> eliminarEstacionamiento(
    String condominioId,
    String numeroEstacionamiento,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(numeroEstacionamiento)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar estacionamiento: $e');
    }
  }

  // Limpiar datos de uso de estacionamiento de visita
  Future<bool> limpiarEstacionamientoVisita(
    String condominioId,
    String numeroEstacionamiento,
    {String creadoPor = 'Sistema', String motivoFinalizacion = 'Finalización manual'}
  ) async {
    try {
      // CORRECCIÓN: Los estacionamientos de visitas tienen ID 'visita-{numero}'
      final documentId = 'visita-$numeroEstacionamiento';
      print('🟡 [SERVICE] Limpiando estacionamiento de visita: $documentId');
      
      final docRef = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(documentId);
      
      // Obtener datos actuales antes de limpiar para el historial
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final datosActuales = docSnapshot.data()!;
        
        // Crear entrada en el historial antes de limpiar
        await _crearHistorialEstacionamientoVisita(
          condominioId,
          numeroEstacionamiento,
          datosActuales,
          creadoPor,
          motivoFinalizacion,
        );
      }
      
      await docRef.update({
        'estadoSolicitud': null,
        'fechaHoraFin': null,
        'fechaHoraInicio': null,
        'fechaHoraSolicitud': null,
        'idSolicitante': null,
        'nombreSolicitante': null,
        'prestado': false,
        'viviendaAsignada': null,
        'viviendaPrestamo': null,
        'viviendaSolicitante': null,
        'respuestaSolicitud': null,
      });
      
      print('🟢 [SERVICE] Estacionamiento de visita limpiado exitosamente: $documentId');
      return true;
    } catch (e) {
      print('🔴 [SERVICE ERROR] Error al limpiar estacionamiento de visita: $e');
      return false;
    }
  }

  // Crear entrada en el historial de estacionamiento de visita
  Future<void> _crearHistorialEstacionamientoVisita(
    String condominioId,
    String numeroEstacionamiento,
    Map<String, dynamic> datosEstacionamiento,
    String creadoPor,
    String motivoFinalizacion,
  ) async {
    try {
      final documentId = 'visita-$numeroEstacionamiento';
      final ahora = DateTime.now();
      
      // Formato: dd-mm-aaaa,hh-mm-ss
      final historialId = '${ahora.day.toString().padLeft(2, '0')}-${ahora.month.toString().padLeft(2, '0')}-${ahora.year},${ahora.hour.toString().padLeft(2, '0')}-${ahora.minute.toString().padLeft(2, '0')}-${ahora.second.toString().padLeft(2, '0')}';
      
      final historialData = {
        ...datosEstacionamiento,
        'fechaCreacionHistorial': ahora.toIso8601String(),
        'creadoPor': creadoPor,
        'motivoFinalizacion': motivoFinalizacion,
      };
      
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(documentId)
          .collection('historial')
          .doc(historialId)
          .set(historialData);
      
      print('🟢 [SERVICE] Historial creado: $historialId');
    } catch (e) {
      print('🔴 [SERVICE ERROR] Error al crear historial: $e');
    }
  }

  // Obtener historial de un estacionamiento de visita
  Future<List<HistorialEstacionamientoVisitaModel>> obtenerHistorialEstacionamientoVisita(
    String condominioId,
    String numeroEstacionamiento,
  ) async {
    try {
      final documentId = 'visita-$numeroEstacionamiento';
      
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(documentId)
          .collection('historial')
          .orderBy('fechaCreacionHistorial', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => HistorialEstacionamientoVisitaModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('🔴 [SERVICE ERROR] Error al obtener historial: $e');
      return [];
    }
  }

  // Contar solicitudes de estacionamientos de visitas pendientes
  Stream<int> contarSolicitudesVisitasPendientes(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('estacionamiento')
        .collection('estacionamientos')
        .where('estVisita', isEqualTo: true)
        .where('estadoSolicitud', isEqualTo: 'pendiente')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Contar solicitudes de estacionamientos regulares pendientes
  Stream<int> contarSolicitudesEstacionamientosPendientes(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('estacionamiento')
        .collection('estacionamientos')
        .where('estVisita', isEqualTo: false)
        .where('estadoSolicitud', isEqualTo: 'pendiente')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Crear uso de estacionamiento de visita por administrador
  Future<bool> crearUsoEstacionamientoVisita(
    String condominioId,
    String numeroEstacionamiento,
    String viviendaAsignada,
    DateTime fechaInicio,
    DateTime fechaFin,
    String idUsuario,
    String nombreUsuario,
  ) async {
    print('🟡 [SERVICE] Iniciando crearUsoEstacionamientoVisita');
    print('🟡 [SERVICE] Parámetros recibidos:');
    print('🟡 [SERVICE] - condominioId: $condominioId');
    print('🟡 [SERVICE] - numeroEstacionamiento: $numeroEstacionamiento');
    print('🟡 [SERVICE] - viviendaAsignada: $viviendaAsignada');
    print('🟡 [SERVICE] - fechaInicio: $fechaInicio');
    print('🟡 [SERVICE] - fechaFin: $fechaFin');
    print('🟡 [SERVICE] - idUsuario: $idUsuario');
    print('🟡 [SERVICE] - nombreUsuario: $nombreUsuario');
    
    try {
      // CORRECCIÓN: Los estacionamientos de visitas tienen ID 'visita-{numero}'
      final documentId = 'visita-$numeroEstacionamiento';
      final docPath = '$condominioId/estacionamiento/estacionamientos/$documentId';
      print('🟡 [SERVICE] ID del documento corregido: $documentId');
      print('🟡 [SERVICE] Ruta del documento: $docPath');
      
      final updateData = {
        'estadoSolicitud': null, // null indica que es por trabajador/admin
        'fechaHoraFin': fechaFin.toIso8601String(),
        'fechaHoraInicio': fechaInicio.toIso8601String(),
        'fechaHoraSolicitud': null,
        'idSolicitante': [idUsuario],
        'nombreSolicitante': [nombreUsuario],
        'prestado': true,
        'viviendaAsignada': viviendaAsignada,
        'viviendaPrestamo': null,
        'viviendaSolicitante': null,
      };
      
      print('🟡 [SERVICE] Datos a actualizar: $updateData');
      
      // Verificar si el documento existe antes de actualizar
      final docRef = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(documentId);
      
      final docSnapshot = await docRef.get();
      print('🟡 [SERVICE] Documento existe: ${docSnapshot.exists}');
      
      if (!docSnapshot.exists) {
        print('🔴 [SERVICE ERROR] El documento del estacionamiento de visita no existe: $documentId');
        return false;
      }
      
      print('🟡 [SERVICE] Datos actuales del documento: ${docSnapshot.data()}');
      
      print('🟡 [SERVICE] Ejecutando update...');
      await docRef.update(updateData);
      
      print('🟢 [SERVICE SUCCESS] Update ejecutado correctamente');
      
      // Verificar que los datos se guardaron correctamente
      final updatedDoc = await docRef.get();
      print('🟡 [SERVICE] Datos después del update: ${updatedDoc.data()}');
      
      return true;
    } catch (e) {
      print('🔴 [SERVICE ERROR] Error al crear uso de estacionamiento de visita: $e');
      print('🔴 [SERVICE ERROR] Tipo de error: ${e.runtimeType}');
      print('🔴 [SERVICE ERROR] Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}