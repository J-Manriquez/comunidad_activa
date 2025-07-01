import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gasto_comun_model.dart';

class GastosComunesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener referencia al documento de gastos comunes
  DocumentReference _getGastosComunesRef(String condominioId) {
    return _firestore.collection(condominioId).doc('gastosComunes');
  }

  // Obtener referencia a una subcolección específica
  CollectionReference _getSubcoleccionRef(String condominioId, TipoGasto tipo) {
    return _getGastosComunesRef(condominioId).collection(tipo.coleccion);
  }

  // Crear gasto común
  Future<String> crearGasto({
    required String condominioId,
    required GastoComunModel gasto,
  }) async {
    try {
      // Primero, asegurar que el documento principal existe
      await _getGastosComunesRef(condominioId).set({
        'condominioId': condominioId,
      }, SetOptions(merge: true));

      // Crear el gasto en la subcolección correspondiente
      final docRef = await _getSubcoleccionRef(condominioId, gasto.tipo)
          .add(gasto.toFirestore());

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear gasto: $e');
      throw Exception('Error al crear gasto: $e');
    }
  }

  // Obtener todos los gastos de un tipo específico
  Future<List<GastoComunModel>> obtenerGastosPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) async {
    try {
      final snapshot = await _getSubcoleccionRef(condominioId, tipo)
          .orderBy('descripcion')
          .get();

      return snapshot.docs
          .map((doc) => GastoComunModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
                tipo,
              ))
          .toList();
    } catch (e) {
      print('❌ Error al obtener gastos: $e');
      return [];
    }
  }

  // Obtener todos los gastos (todos los tipos)
  Future<Map<TipoGasto, List<GastoComunModel>>> obtenerTodosLosGastos({
    required String condominioId,
  }) async {
    try {
      final Map<TipoGasto, List<GastoComunModel>> gastos = {};

      for (final tipo in TipoGasto.values) {
        gastos[tipo] = await obtenerGastosPorTipo(
          condominioId: condominioId,
          tipo: tipo,
        );
      }

      return gastos;
    } catch (e) {
      print('❌ Error al obtener todos los gastos: $e');
      return {};
    }
  }

  // Actualizar gasto
  Future<void> actualizarGasto({
    required String condominioId,
    required GastoComunModel gasto,
  }) async {
    try {
      await _getSubcoleccionRef(condominioId, gasto.tipo)
          .doc(gasto.id)
          .update(gasto.toFirestore());
    } catch (e) {
      print('❌ Error al actualizar gasto: $e');
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> eliminarGasto({
    required String condominioId,
    required String gastoId,
    required TipoGasto tipo,
  }) async {
    try {
      await _getSubcoleccionRef(condominioId, tipo)
          .doc(gastoId)
          .delete();
    } catch (e) {
      print('❌ Error al eliminar gasto: $e');
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener un gasto específico
  Future<GastoComunModel?> obtenerGasto({
    required String condominioId,
    required String gastoId,
    required TipoGasto tipo,
  }) async {
    try {
      final doc = await _getSubcoleccionRef(condominioId, tipo)
          .doc(gastoId)
          .get();

      if (doc.exists) {
        return GastoComunModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
          tipo,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener gasto: $e');
      return null;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<GastoComunModel>> streamGastosPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) {
    return _getSubcoleccionRef(condominioId, tipo)
        .orderBy('descripcion')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GastoComunModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                  tipo,
                ))
            .toList());
  }

  // Calcular total de gastos por tipo
  Future<int> calcularTotalPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) async {
    try {
      final gastos = await obtenerGastosPorTipo(
        condominioId: condominioId,
        tipo: tipo,
      );

      return gastos.fold<int>(0, (total, gasto) => total + gasto.monto);
    } catch (e) {
      print('❌ Error al calcular total: $e');
      return 0;
    }
  }

  // Calcular total general de todos los gastos
  Future<int> calcularTotalGeneral({
    required String condominioId,
  }) async {
    try {
      int total = 0;
      for (final tipo in TipoGasto.values) {
        total += await calcularTotalPorTipo(
          condominioId: condominioId,
          tipo: tipo,
        );
      }
      return total;
    } catch (e) {
      print('❌ Error al calcular total general: $e');
      return 0;
    }
  }
}