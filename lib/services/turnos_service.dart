import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turno_trabajador_model.dart';
import '../models/turno_definido_model.dart';
import 'package:intl/intl.dart';

class TurnosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener referencia al documento turnosTrabajadores de un condominio
  DocumentReference _getTurnosDocumentRef(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('turnosTrabajadores');
  }

  // Obtener referencia a la colección de turnos registrados por fecha
  CollectionReference _getTurnosRegistradosRef(String condominioId, String fecha) {
    return _getTurnosDocumentRef(condominioId)
        .collection('turnosRegistrados')
        .doc(fecha)
        .collection('registros');
  }

  // MÉTODOS PARA TURNOS REGISTRADOS

  /// Registrar un turno de trabajador
  Future<void> registrarTurno(String condominioId, TurnoTrabajador turno) async {
    try {
      final fecha = turno.fecha;
      final turnosRef = _getTurnosRegistradosRef(condominioId, fecha);
      
      await turnosRef.doc(turno.id).set(turno.toMap());
    } catch (e) {
      throw Exception('Error al registrar turno: $e');
    }
  }

  /// Obtener turnos registrados por fecha
  Future<List<TurnoTrabajador>> obtenerTurnosRegistradosPorFecha(
      String condominioId, String fecha) async {
    try {
      final turnosRef = _getTurnosRegistradosRef(condominioId, fecha);
      final querySnapshot = await turnosRef.get();
      
      return querySnapshot.docs
          .map((doc) => TurnoTrabajador.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener turnos registrados: $e');
    }
  }

  /// Obtener turnos registrados por trabajador en un rango de fechas
  Future<List<TurnoTrabajador>> obtenerTurnosPorTrabajador(
      String condominioId, String uidUsuario, DateTime fechaInicio, DateTime fechaFin) async {
    try {
      List<TurnoTrabajador> todosTurnos = [];
      
      // Iterar por cada día en el rango de fechas
      DateTime fechaActual = fechaInicio;
      while (fechaActual.isBefore(fechaFin) || fechaActual.isAtSameMomentAs(fechaFin)) {
        String fechaStr = DateFormat('dd-MM-yyyy').format(fechaActual);
        
        final turnosRef = _getTurnosRegistradosRef(condominioId, fechaStr);
        final querySnapshot = await turnosRef
            .where('uidUsuario', isEqualTo: uidUsuario)
            .get();
        
        final turnosDia = querySnapshot.docs
            .map((doc) => TurnoTrabajador.fromFirestore(doc))
            .toList();
        
        todosTurnos.addAll(turnosDia);
        fechaActual = fechaActual.add(const Duration(days: 1));
      }
      
      return todosTurnos;
    } catch (e) {
      throw Exception('Error al obtener turnos por trabajador: $e');
    }
  }

  /// Eliminar un turno registrado
  Future<void> eliminarTurnoRegistrado(String condominioId, String fecha, String turnoId) async {
    try {
      final turnosRef = _getTurnosRegistradosRef(condominioId, fecha);
      await turnosRef.doc(turnoId).delete();
    } catch (e) {
      throw Exception('Error al eliminar turno registrado: $e');
    }
  }

  // MÉTODOS PARA TURNOS DEFINIDOS (CONFIGURACIÓN)

  /// Crear o actualizar un turno definido
  Future<void> guardarTurnoDefinido(String condominioId, TurnoDefinido turno) async {
    try {
      print('TurnosService: Guardando turno para condominioId: $condominioId');
      print('TurnosService: Datos del turno: ${turno.toMap()}');
      
      final turnosDocRef = _getTurnosDocumentRef(condominioId);
      
      await turnosDocRef.set({
        'turnos.${turno.id}': turno.toMap()
      }, SetOptions(merge: true));
      
      print('TurnosService: Turno guardado exitosamente con ID: ${turno.id}');
    } catch (e) {
      print('TurnosService: Error al guardar turno definido: $e');
      throw Exception('Error al guardar turno definido: $e');
    }
  }

  /// Obtener todos los turnos definidos
  Future<List<TurnoDefinido>> obtenerTurnosDefinidos(String condominioId) async {
    try {
      print('TurnosService: Obteniendo turnos para condominioId: $condominioId');
      final turnosDoc = await _getTurnosDocumentRef(condominioId).get();
      
      if (!turnosDoc.exists) {
        print('TurnosService: El documento turnosTrabajadores no existe');
        return [];
      }
      
      final data = turnosDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('TurnosService: El documento no tiene datos');
        return [];
      }
      
      print('TurnosService: Datos del documento: $data');
      
      // Filtrar las claves que empiecen con 'turnos.'
      final turnosEntries = data.entries
          .where((entry) => entry.key.startsWith('turnos.'))
          .toList();
      
      if (turnosEntries.isEmpty) {
        print('TurnosService: No se encontraron turnos definidos');
        return [];
      }
      
      print('TurnosService: Encontradas ${turnosEntries.length} entradas de turnos');
      
      final turnos = <TurnoDefinido>[];
      for (final entry in turnosEntries) {
        try {
          print('TurnosService: Procesando turno con clave: ${entry.key}');
          print('TurnosService: Datos del turno: ${entry.value}');
          
          final turnoData = entry.value as Map<String, dynamic>;
          final turno = TurnoDefinido.fromMap(turnoData);
          turnos.add(turno);
          
          print('TurnosService: Turno procesado exitosamente: ${turno.id}');
        } catch (e) {
          print('TurnosService: Error al procesar turno ${entry.key}: $e');
          // Continuar con el siguiente turno en caso de error
        }
      }
      
      print('TurnosService: Turnos procesados: ${turnos.length}');
      return turnos;
    } catch (e) {
      print('TurnosService: Error al obtener turnos definidos: $e');
      throw Exception('Error al obtener turnos definidos: $e');
    }
  }

  /// Obtener turnos definidos por tipo de trabajador
  Future<List<TurnoDefinido>> obtenerTurnosDefinidosPorTipo(
      String condominioId, String tipoTrabajador) async {
    try {
      final todosTurnos = await obtenerTurnosDefinidos(condominioId);
      return todosTurnos
          .where((turno) => turno.tipoTrabajador == tipoTrabajador)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener turnos por tipo: $e');
    }
  }

  /// Eliminar un turno definido
  Future<void> eliminarTurnoDefinido(String condominioId, String turnoId) async {
    try {
      final turnosDocRef = _getTurnosDocumentRef(condominioId);
      
      await turnosDocRef.update({
        'turnos.$turnoId': FieldValue.delete()
      });
    } catch (e) {
      throw Exception('Error al eliminar turno definido: $e');
    }
  }

  // MÉTODOS AUXILIARES

  /// Generar ID único para turno
  String generarIdTurno() {
    return _firestore.collection('temp').doc().id;
  }

  /// Obtener fecha actual en formato dd-MM-yyyy
  String obtenerFechaActual() {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  /// Obtener hora actual en formato HH:mm
  String obtenerHoraActual() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// Validar si un trabajador ya registró turno en una fecha específica
  Future<bool> yaRegistroTurno(String condominioId, String uidUsuario, String fecha) async {
    try {
      final turnosRef = _getTurnosRegistradosRef(condominioId, fecha);
      final querySnapshot = await turnosRef
          .where('uidUsuario', isEqualTo: uidUsuario)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al validar registro de turno: $e');
    }
  }

  /// Obtener estadísticas de turnos por trabajador en un mes
  Future<Map<String, int>> obtenerEstadisticasTurnosMes(
      String condominioId, String uidUsuario, int mes, int anio) async {
    try {
      final fechaInicio = DateTime(anio, mes, 1);
      final fechaFin = DateTime(anio, mes + 1, 0);
      
      final turnos = await obtenerTurnosPorTrabajador(condominioId, uidUsuario, fechaInicio, fechaFin);
      
      Map<String, int> estadisticas = {};
      for (var turno in turnos) {
        estadisticas[turno.tipoTrabajador] = (estadisticas[turno.tipoTrabajador] ?? 0) + 1;
      }
      
      return estadisticas;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // MÉTODOS PARA GESTIÓN DE TURNOS EN TIEMPO REAL

  /// Obtener el último turno registrado de un trabajador
  Future<TurnoTrabajador?> obtenerUltimoTurnoTrabajador(
      String condominioId, String uidUsuario) async {
    try {
      print('TurnosService: Obteniendo último turno para trabajador: $uidUsuario');
      
      // Buscar en los últimos 30 días para encontrar el último turno
      final fechaFin = DateTime.now();
      final fechaInicio = fechaFin.subtract(const Duration(days: 30));
      
      final turnos = await obtenerTurnosPorTrabajador(condominioId, uidUsuario, fechaInicio, fechaFin);
      
      if (turnos.isEmpty) {
        print('TurnosService: No se encontraron turnos para el trabajador');
        return null;
      }
      
      // Ordenar por fecha y hora para obtener el más reciente
      turnos.sort((a, b) {
        final fechaA = DateFormat('dd-MM-yyyy').parse(a.fecha);
        final fechaB = DateFormat('dd-MM-yyyy').parse(b.fecha);
        final comparacionFecha = fechaB.compareTo(fechaA);
        
        if (comparacionFecha != 0) return comparacionFecha;
        
        // Si las fechas son iguales, comparar por hora
        final horaA = DateFormat('HH:mm').parse(a.hora);
        final horaB = DateFormat('HH:mm').parse(b.hora);
        return horaB.compareTo(horaA);
      });
      
      final ultimoTurno = turnos.first;
      print('TurnosService: Último turno encontrado - Estado: ${ultimoTurno.estado}, Fecha: ${ultimoTurno.fecha}, Hora: ${ultimoTurno.hora}');
      
      return ultimoTurno;
    } catch (e) {
      print('TurnosService: Error al obtener último turno: $e');
      throw Exception('Error al obtener último turno: $e');
    }
  }

  /// Iniciar un nuevo turno para un trabajador
  Future<void> iniciarTurno(String condominioId, String uidUsuario, 
      String nombreTrabajador, String tipoTrabajador) async {
    try {
      print('TurnosService: Iniciando turno para trabajador: $nombreTrabajador');
      
      final fechaActual = obtenerFechaActual();
      final horaActual = obtenerHoraActual();
      final turnoId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final nuevoTurno = TurnoTrabajador(
        id: turnoId,
        hora: horaActual,
        fecha: fechaActual,
        estado: 'inicio',
        nombre: nombreTrabajador,
        uidUsuario: uidUsuario,
        tipoTrabajador: tipoTrabajador,
      );
      
      await registrarTurno(condominioId, nuevoTurno);
      
      print('TurnosService: Turno iniciado exitosamente - ID: $turnoId');
    } catch (e) {
      print('TurnosService: Error al iniciar turno: $e');
      throw Exception('Error al iniciar turno: $e');
    }
  }

  /// Terminar el turno activo de un trabajador
  Future<void> terminarTurno(String condominioId, String uidUsuario, 
      String nombreTrabajador, String tipoTrabajador) async {
    try {
      print('TurnosService: Terminando turno para trabajador: $nombreTrabajador');
      
      final fechaActual = obtenerFechaActual();
      final horaActual = obtenerHoraActual();
      final turnoId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final turnoTermino = TurnoTrabajador(
        id: turnoId,
        hora: horaActual,
        fecha: fechaActual,
        estado: 'termino',
        nombre: nombreTrabajador,
        uidUsuario: uidUsuario,
        tipoTrabajador: tipoTrabajador,
      );
      
      await registrarTurno(condominioId, turnoTermino);
      
      print('TurnosService: Turno terminado exitosamente - ID: $turnoId');
    } catch (e) {
      print('TurnosService: Error al terminar turno: $e');
      throw Exception('Error al terminar turno: $e');
    }
  }

  /// Determinar si el trabajador debe iniciar o terminar turno
  Future<String> obtenerAccionTurno(String condominioId, String uidUsuario) async {
    try {
      final ultimoTurno = await obtenerUltimoTurnoTrabajador(condominioId, uidUsuario);
      
      if (ultimoTurno == null || ultimoTurno.estado == 'termino') {
        return 'inicio';
      } else {
        return 'termino';
      }
    } catch (e) {
      print('TurnosService: Error al determinar acción de turno: $e');
      // En caso de error, asumir que debe iniciar turno
      return 'inicio';
    }
  }
}