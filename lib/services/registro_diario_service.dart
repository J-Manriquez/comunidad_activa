import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/registro_diario_model.dart';

class RegistroDiarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener la fecha actual en formato dd-mm-aaaa
  String _getCurrentDateString() {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Formatear fecha a string dd-mm-aaaa
  String _formatDateString(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Obtener la hora actual en formato HH:mm
  String _getCurrentTimeString() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  // Crear un nuevo registro diario
  Future<String> crearRegistro({
    required String condominioId,
    required String nombre,
    required String uidUsuario,
    required String tipoUsuario,
    required String comentario,
    Map<String, dynamic>? additionalData,
    DateTime? fecha,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      String fechaString = fecha != null ? _formatDateString(fecha) : _getCurrentDateString();
      String horaActual = _getCurrentTimeString();

      // Crear el documento de registro
      DocumentReference docRef = await _firestore
          .collection(condominioId)
          .doc('registros')
          .collection(fechaString)
          .add({
        'hora': horaActual,
        'nombre': nombre,
        'uidUsuario': uidUsuario,
        'tipoUsuario': tipoUsuario,
        'comentario': comentario,
        'additionalData': additionalData ?? {},
      });

      // Actualizar el documento con su propio ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear registro: $e');
    }
  }

  // Obtener registros de una fecha específica
  Future<List<RegistroDiario>> obtenerRegistrosPorFecha({
    required String condominioId,
    DateTime? fecha,
  }) async {
    try {
      String fechaString = fecha != null ? _formatDateString(fecha) : _getCurrentDateString();

      QuerySnapshot querySnapshot = await _firestore
          .collection(condominioId)
          .doc('registros')
          .collection(fechaString)
          .orderBy('hora', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RegistroDiario.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener registros: $e');
    }
  }

  // Obtener registros del día actual
  Future<List<RegistroDiario>> obtenerRegistrosDelDia({
    required String condominioId,
  }) async {
    return await obtenerRegistrosPorFecha(condominioId: condominioId);
  }

  // Obtener TODOS los registros históricos (sin límite de días)
  Future<Map<String, List<RegistroDiario>>> obtenerTodosLosRegistros({
    required String condominioId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      Map<String, List<RegistroDiario>> historial = {};
      
      // Si no se especifican fechas, obtener desde hace 1 año hasta hoy
      DateTime inicio = fechaInicio ?? DateTime.now().subtract(Duration(days: 365));
      DateTime fin = fechaFin ?? DateTime.now();
      
      // Iterar día por día desde la fecha de inicio hasta la fecha fin
      DateTime fechaActual = inicio;
      while (fechaActual.isBefore(fin.add(Duration(days: 1)))) {
        String fechaString = _formatDateString(fechaActual);

        try {
          List<RegistroDiario> registros = await obtenerRegistrosPorFecha(
            condominioId: condominioId,
            fecha: fechaActual,
          );

          if (registros.isNotEmpty) {
            historial[fechaString] = registros;
          }
        } catch (e) {
          // Si no hay registros para esa fecha, continuar
        }
        
        fechaActual = fechaActual.add(Duration(days: 1));
      }

      return historial;
    } catch (e) {
      throw Exception('Error al obtener todos los registros: $e');
    }
  }

  // Obtener historial de registros (últimos 30 días)
  Future<Map<String, List<RegistroDiario>>> obtenerHistorialRegistros({
    required String condominioId,
    int diasAtras = 30,
  }) async {
    try {
      Map<String, List<RegistroDiario>> historial = {};
      DateTime fechaInicio = DateTime.now().subtract(Duration(days: diasAtras));

      for (int i = 0; i <= diasAtras; i++) {
        DateTime fechaActual = fechaInicio.add(Duration(days: i));
        String fechaString = _formatDateString(fechaActual);

        try {
          List<RegistroDiario> registros = await obtenerRegistrosPorFecha(
            condominioId: condominioId,
            fecha: fechaActual,
          );

          if (registros.isNotEmpty) {
            historial[fechaString] = registros;
          }
        } catch (e) {
          // Si no hay registros para esa fecha, continuar
          continue;
        }
      }

      return historial;
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  // Obtener un registro específico por ID
  Future<RegistroDiario?> obtenerRegistroPorId({
    required String condominioId,
    required String registroId,
    required DateTime fecha,
  }) async {
    try {
      String fechaString = _formatDateString(fecha);

      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('registros')
          .collection(fechaString)
          .doc(registroId)
          .get();

      if (doc.exists) {
        return RegistroDiario.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener registro: $e');
    }
  }

  // Actualizar un registro existente
  Future<void> actualizarRegistro({
    required String condominioId,
    required String registroId,
    required DateTime fecha,
    String? nombre,
    String? tipoUsuario,
    String? comentario,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String fechaString = _formatDateString(fecha);
      Map<String, dynamic> updateData = {};

      if (nombre != null) updateData['nombre'] = nombre;
      if (tipoUsuario != null) updateData['tipoUsuario'] = tipoUsuario;
      if (comentario != null) updateData['comentario'] = comentario;
      if (additionalData != null) updateData['additionalData'] = additionalData;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(condominioId)
            .doc('registros')
            .collection(fechaString)
            .doc(registroId)
            .update(updateData);
      }
    } catch (e) {
      throw Exception('Error al actualizar registro: $e');
    }
  }

  // Eliminar un registro
  Future<void> eliminarRegistro({
    required String condominioId,
    required String registroId,
    required DateTime fecha,
  }) async {
    try {
      String fechaString = _formatDateString(fecha);

      await _firestore
          .collection(condominioId)
          .doc('registros')
          .collection(fechaString)
          .doc(registroId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar registro: $e');
    }
  }

  // Buscar registros por nombre o tipo de usuario
  Future<List<RegistroDiario>> buscarRegistros({
    required String condominioId,
    required DateTime fecha,
    String? nombre,
    String? tipoUsuario,
  }) async {
    try {
      String fechaString = _formatDateString(fecha);
      Query query = _firestore
          .collection(condominioId)
          .doc('registros')
          .collection(fechaString);

      if (nombre != null && nombre.isNotEmpty) {
        query = query.where('nombre', isGreaterThanOrEqualTo: nombre)
                    .where('nombre', isLessThan: nombre + 'z');
      }

      if (tipoUsuario != null && tipoUsuario.isNotEmpty) {
        query = query.where('tipoUsuario', isEqualTo: tipoUsuario);
      }

      QuerySnapshot querySnapshot = await query
          .orderBy('hora', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RegistroDiario.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar registros: $e');
    }
  }

  // Obtener estadísticas de registros por fecha
  Future<Map<String, int>> obtenerEstadisticasPorFecha({
    required String condominioId,
    required DateTime fecha,
  }) async {
    try {
      List<RegistroDiario> registros = await obtenerRegistrosPorFecha(
        condominioId: condominioId,
        fecha: fecha,
      );

      Map<String, int> estadisticas = {};
      
      for (RegistroDiario registro in registros) {
        estadisticas[registro.tipoUsuario] = 
            (estadisticas[registro.tipoUsuario] ?? 0) + 1;
      }

      return estadisticas;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}