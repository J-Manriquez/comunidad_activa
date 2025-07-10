import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estacionamiento_model.dart';

class EstacionamientoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener la configuración de estacionamientos
  Future<EstacionamientoConfigModel?> obtenerConfiguracion(String condominioId) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .get();

      if (doc.exists && doc.data() != null) {
        return EstacionamientoConfigModel.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener configuración de estacionamientos: $e');
      return null;
    }
  }

  // Crear o actualizar la configuración de estacionamientos
  Future<bool> actualizarConfiguracion(
    String condominioId,
    EstacionamientoConfigModel configuracion,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .set(configuracion.toFirestore(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error al actualizar configuración de estacionamientos: $e');
      return false;
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

  // Crear estacionamientos individuales
  Future<bool> crearEstacionamientos(
    String condominioId,
    List<String> numeracion,
    {bool esVisita = false}
  ) async {
    try {
      final batch = _firestore.batch();
      final estacionamientosRef = _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos');

      for (String numero in numeracion) {
        final docId = esVisita ? 'visita-$numero' : numero;
        final docRef = estacionamientosRef.doc(docId);
        
        final estacionamiento = EstacionamientoModel(
          id: docId,
          estVisita: esVisita,
          nroEstacionamiento: numero,
        );

        batch.set(docRef, estacionamiento.toFirestore());
      }

      await batch.commit();
      
      // Actualizar la configuración con la nueva numeración
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
      
      return true;
    } catch (e) {
      print('Error al crear estacionamientos: $e');
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
    String estacionamientoId,
  ) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(estacionamientoId)
          .get();

      if (doc.exists && doc.data() != null) {
        return EstacionamientoModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener estacionamiento: $e');
      return null;
    }
  }

  // Actualizar estacionamiento
  Future<bool> actualizarEstacionamiento(
    String condominioId,
    String estacionamientoId,
    Map<String, dynamic> datos,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('estacionamiento')
          .collection('estacionamientos')
          .doc(estacionamientoId)
          .update(datos);
      return true;
    } catch (e) {
      print('Error al actualizar estacionamiento: $e');
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
      return configuracion?.activo ?? false;
    } catch (e) {
      print('Error al verificar estacionamientos activos: $e');
      return false;
    }
  }

  // Función auxiliar para expandir rangos (similar a la de viviendas)
  List<String> expandirRangos(String input) {
    if (input.trim().isEmpty) return [];
    
    List<String> resultado = [];
    List<String> partes = input.split(',');
    
    for (String parte in partes) {
      parte = parte.trim();
      if (parte.isEmpty) continue;
      
      if (parte.contains('-')) {
        List<String> rango = parte.split('-');
        if (rango.length == 2) {
          String inicio = rango[0].trim();
          String fin = rango[1].trim();
          
          // Verificar si son números
          if (RegExp(r'^[0-9]+$').hasMatch(inicio) && RegExp(r'^[0-9]+$').hasMatch(fin)) {
            int inicioNum = int.parse(inicio);
            int finNum = int.parse(fin);
            
            for (int i = inicioNum; i <= finNum; i++) {
              resultado.add(i.toString());
            }
          }
          // Verificar si son letras
          else if (RegExp(r'^[A-Za-z]+$').hasMatch(inicio) && RegExp(r'^[A-Za-z]+$').hasMatch(fin)) {
            int inicioCode = inicio.toUpperCase().codeUnitAt(0);
            int finCode = fin.toUpperCase().codeUnitAt(0);
            
            for (int i = inicioCode; i <= finCode; i++) {
              resultado.add(String.fromCharCode(i));
            }
          }
        }
      } else {
        resultado.add(parte);
      }
    }
    
    return resultado;
  }
}