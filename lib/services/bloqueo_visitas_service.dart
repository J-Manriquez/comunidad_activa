import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/visita_bloqueada_model.dart';

class BloqueoVisitasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todas las visitas bloqueadas de un condominio
  Future<List<VisitaBloqueadaModel>> obtenerVisitasBloqueadas(String condominioId) async {
    try {
      print('🔍 Obteniendo visitas bloqueadas para condominio: $condominioId');
      
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('visitasBloqueadas')
          .collection('ListaVisitasBloqueadas')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('📄 Colección ListaVisitasBloqueadas está vacía');
        return [];
      }

      final List<VisitaBloqueadaModel> visitasBloqueadas = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final visita = VisitaBloqueadaModel.fromMap(data);
          visitasBloqueadas.add(visita);
        } catch (e) {
          print('❌ Error al parsear visita bloqueada ${doc.id}: $e');
        }
      }

      print('✅ Se obtuvieron ${visitasBloqueadas.length} visitas bloqueadas');
      return visitasBloqueadas;
    } catch (e) {
      print('❌ Error al obtener visitas bloqueadas: $e');
      return [];
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<VisitaBloqueadaModel>> streamVisitasBloqueadas(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('visitasBloqueadas')
        .collection('ListaVisitasBloqueadas')
        .snapshots()
        .map((snapshot) {
      final List<VisitaBloqueadaModel> visitasBloqueadas = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final visita = VisitaBloqueadaModel.fromMap(data);
          visitasBloqueadas.add(visita);
        } catch (e) {
          print('❌ Error al parsear visita bloqueada ${doc.id}: $e');
        }
      }

      return visitasBloqueadas;
    });
  }

  // Crear una nueva visita bloqueada
  Future<bool> crearVisitaBloqueada(String condominioId, VisitaBloqueadaModel visita) async {
    try {
      print('📝 Creando nueva visita bloqueada para: ${visita.nombreVisitante}');
      
      // Usar el ID de la visita como ID del documento
      await _firestore
          .collection(condominioId)
          .doc('visitasBloqueadas')
          .collection('ListaVisitasBloqueadas')
          .doc(visita.id)
          .set(visita.toMap());

      print('✅ Visita bloqueada creada exitosamente con ID: ${visita.id}');
      return true;
    } catch (e) {
      print('❌ Error al crear visita bloqueada: $e');
      return false;
    }
  }

  // Actualizar una visita bloqueada existente
  Future<bool> actualizarVisitaBloqueada(String condominioId, VisitaBloqueadaModel visita) async {
    try {
      print('🔄 Actualizando visita bloqueada: ${visita.id}');
      
      await _firestore
          .collection(condominioId)
          .doc('visitasBloqueadas')
          .collection('ListaVisitasBloqueadas')
          .doc(visita.id)
          .update(visita.toMap());

      print('✅ Visita bloqueada actualizada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al actualizar visita bloqueada: $e');
      return false;
    }
  }

  // Cambiar estado de una visita bloqueada
  Future<bool> cambiarEstadoVisita({
    required String condominioId,
    required String visitaId,
    required String nuevoEstado,
  }) async {
    try {
      print('🔄 Cambiando estado de visita $visitaId a: $nuevoEstado');

      await _firestore
          .collection(condominioId)
          .doc('visitasBloqueadas')
          .collection('ListaVisitasBloqueadas')
          .doc(visitaId)
          .update({
        'estado': nuevoEstado,
      });

      print('✅ Estado de visita bloqueada actualizado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al cambiar estado de visita bloqueada: $e');
      return false;
    }
  }

  // Eliminar una visita bloqueada
  Future<bool> eliminarVisitaBloqueada({
    required String condominioId,
    required String visitaId,
  }) async {
    try {
      print('🗑️ Eliminando visita bloqueada: $visitaId');

      await _firestore
          .collection(condominioId)
          .doc('visitasBloqueadas')
          .collection('ListaVisitasBloqueadas')
          .doc(visitaId)
          .delete();

      print('✅ Visita bloqueada eliminada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al eliminar visita bloqueada: $e');
      return false;
    }
  }

  // Verificar si una visita está bloqueada por RUT
  Future<VisitaBloqueadaModel?> verificarVisitaBloqueada({
    required String condominioId,
    required String rutVisitante,
  }) async {
    try {
      print('🔍 Verificando si el RUT $rutVisitante está bloqueado');

      final visitasBloqueadas = await obtenerVisitasBloqueadas(condominioId);
      
      for (final visita in visitasBloqueadas) {
        if (visita.rutVisitante == rutVisitante && visita.estado == 'activo') {
          print('🚫 Visita bloqueada encontrada');
          return visita;
        }
      }

      print('✅ Visita no está bloqueada');
      return null;
    } catch (e) {
      print('❌ Error al verificar visita bloqueada: $e');
      return null;
    }
  }

  // Obtener visitas bloqueadas por estado
  Future<List<VisitaBloqueadaModel>> obtenerVisitasPorEstado({
    required String condominioId,
    required String estado,
  }) async {
    try {
      final todasLasVisitas = await obtenerVisitasBloqueadas(condominioId);
      return todasLasVisitas.where((visita) => visita.estado == estado).toList();
    } catch (e) {
      print('❌ Error al obtener visitas por estado: $e');
      return [];
    }
  }

  // Stream para escuchar cambios en tiempo real de visitas bloqueadas por vivienda
  Stream<int> streamVisitasBloqueadasCountPorVivienda({
    required String condominioId,
    required String descripcionVivienda,
  }) {
    return _firestore
        .collection(condominioId)
        .doc('visitasBloqueadas')
        .collection('ListaVisitasBloqueadas')
        .snapshots()
        .map((snapshot) {
      int count = 0;
      final descripcionNormalizada = descripcionVivienda.toLowerCase().trim();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final viviendaVisitaNormalizada = (data['viviendaBloqueo'] ?? '').toString().toLowerCase().trim();
          if (viviendaVisitaNormalizada == descripcionNormalizada) {
            count++;
          }
        } catch (e) {
          print('❌ Error al parsear visita bloqueada ${doc.id}: $e');
        }
      }

      return count;
    });
  }

  // Obtener visitas bloqueadas para una vivienda específica
  Future<List<VisitaBloqueadaModel>> obtenerVisitasBloqueadasPorVivienda({
    required String condominioId,
    required String descripcionVivienda,
  }) async {
    try {
      print('🔍 Obteniendo visitas bloqueadas para vivienda: $descripcionVivienda');
      
      final todasLasVisitas = await obtenerVisitasBloqueadas(condominioId);
      
      // Normalizar la descripción de vivienda para comparación
      final descripcionNormalizada = descripcionVivienda.toLowerCase().trim();
      
      final visitasFiltradas = todasLasVisitas.where((visita) {
        final viviendaVisitaNormalizada = visita.viviendaBloqueo.toLowerCase().trim();
        return viviendaVisitaNormalizada == descripcionNormalizada;
      }).toList();
      
      print('✅ Encontradas ${visitasFiltradas.length} visitas bloqueadas para la vivienda');
      return visitasFiltradas;
    } catch (e) {
      print('❌ Error al obtener visitas bloqueadas por vivienda: $e');
      return [];
    }
  }

  // Obtener información del usuario que realizó el bloqueo
  Future<Map<String, String>?> obtenerInfoUsuarioBloqueo({
    required String condominioId,
    required String usuarioId,
  }) async {
    try {
      print('🔍 Obteniendo información del usuario: $usuarioId');

      // Primero verificar si es el administrador
      final adminDoc = await _firestore
          .collection(condominioId)
          .doc('administrador')
          .get();

      if (adminDoc.exists) {
        final adminData = adminDoc.data() as Map<String, dynamic>;
        if (adminData['uid'] == usuarioId) {
          return {
            'nombre': adminData['nombre'] ?? 'Administrador',
            'cargo': 'Administrador',
          };
        }
      }

      // Verificar si es un trabajador
      final trabajadoresSnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .where('uid', isEqualTo: usuarioId)
          .get();

      if (trabajadoresSnapshot.docs.isNotEmpty) {
        final trabajadorData = trabajadoresSnapshot.docs.first.data();
        return {
          'nombre': trabajadorData['nombre'] ?? 'Trabajador',
          'cargo': 'Trabajador',
        };
      }

      // Si no es admin ni trabajador, podría ser un residente con permisos especiales
      final residentesSnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .where('uid', isEqualTo: usuarioId)
          .get();

      if (residentesSnapshot.docs.isNotEmpty) {
        final residenteData = residentesSnapshot.docs.first.data();
        final esComite = residenteData['esComite'] ?? false;
        return {
          'nombre': residenteData['nombre'] ?? 'Usuario',
          'cargo': esComite ? 'Comité' : 'Residente',
        };
      }

      print('⚠️ Usuario no encontrado: $usuarioId');
      return {
        'nombre': 'Usuario no encontrado',
        'cargo': 'Desconocido',
      };
    } catch (e) {
      print('❌ Error al obtener información del usuario: $e');
      return {
        'nombre': 'Error al cargar',
        'cargo': 'Desconocido',
      };
    }
  }
}