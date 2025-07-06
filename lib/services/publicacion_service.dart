import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/publicacion_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'firestore_service.dart';

class PublicacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  // Crear una nueva publicación
  Future<void> crearPublicacion({
    required String condominioId,
    required String tipoPublicacion,
    required String contenido,
    required String titulo,
    required String estado,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final String publicacionId = _firestore.collection('temp').doc().id;
      final String fechaPublicacion = DateTime.now().toIso8601String();

      final publicacion = PublicacionModel(
        id: publicacionId,
        tipoPublicacion: tipoPublicacion,
        contenido: contenido,
        titulo: titulo,
        fechaPublicacion: fechaPublicacion,
        estado: estado,
        additionalData: additionalData,
      );

      // Guardar en la estructura: {condominioId}/comunicaciones/publicaciones/{publicacionId}
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .set(publicacion.toMap());

      // Generar notificaciones según el tipo de publicación
      await _generarNotificaciones(condominioId, publicacion);
    } catch (e) {
      print('Error al crear publicación: $e');
      throw Exception('Error al crear la publicación: $e');
    }
  }

  // Obtener todas las publicaciones de un condominio
  Future<List<PublicacionModel>> obtenerPublicaciones(String condominioId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .get();

      final publicaciones = snapshot.docs
          .map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .cast<PublicacionModel>()
          .toList();
      
      // Ordenar por fecha en el cliente
      publicaciones.sort((a, b) => DateTime.parse(b.fechaPublicacion).compareTo(DateTime.parse(a.fechaPublicacion)));
      
      return publicaciones;
    } catch (e) {
      print('Error al obtener publicaciones: $e');
      return [];
    }
  }

  // Obtener publicaciones por tipo (residentes/trabajadores)
  Future<List<PublicacionModel>> obtenerPublicacionesPorTipo(
    String condominioId,
    String tipoPublicacion,
  ) async {
    try {
      print('🔍 Buscando publicaciones en: condominios/$condominioId/comunicaciones/publicaciones/publicaciones');
      print('🔍 Filtro tipoPublicacion: $tipoPublicacion');
      
      // Obtener TODAS las publicaciones sin filtros para evitar índices
      final QuerySnapshot snapshot = await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .get();

      print('📊 Documentos encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          print('📄 Doc ID: ${doc.id}');
          print('📄 Data: ${doc.data()}');
        }
      }

      // Filtrar TODO en el cliente para evitar índices compuestos
      final publicaciones = snapshot.docs
          .map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .cast<PublicacionModel>()
          .where((publicacion) => 
              publicacion.tipoPublicacion == tipoPublicacion && 
              (publicacion.estado == 'activa' || publicacion.estado == 'inactiva'))
          .toList();
      
      print('✅ Publicaciones filtradas encontradas: ${publicaciones.length}');
      
      // Debug: mostrar estados de las publicaciones
      for (var pub in snapshot.docs.map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))) {
        print('📋 Publicación ${pub.id}: tipo=${pub.tipoPublicacion}, estado=${pub.estado}');
      }
      
      // Ordenar por fecha en el cliente
      publicaciones.sort((a, b) => DateTime.parse(b.fechaPublicacion).compareTo(DateTime.parse(a.fechaPublicacion)));
      
      return publicaciones;
    } catch (e) {
      print('❌ Error al obtener publicaciones por tipo: $e');
      return [];
    }
  }

  // Stream de publicaciones para tiempo real
  Stream<List<PublicacionModel>> obtenerPublicacionesStream(
    String condominioId,
    String tipoPublicacion,
  ) {
    return _firestore
        .collection('condominios')
        .doc(condominioId)
        .collection('comunicaciones')
        .doc('publicaciones')
        .collection('publicaciones')
        .snapshots()
        .map((snapshot) {
          // Filtrar TODO en el cliente para evitar índices compuestos
          final publicaciones = snapshot.docs
              .map((doc) => PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .cast<PublicacionModel>()
              .where((publicacion) => 
                  publicacion.tipoPublicacion == tipoPublicacion && 
                  (publicacion.estado == 'activa' || publicacion.estado == 'inactiva'))
              .toList();
          
          // Ordenar por fecha en el cliente
          publicaciones.sort((a, b) => DateTime.parse(b.fechaPublicacion).compareTo(DateTime.parse(a.fechaPublicacion)));
          
          return publicaciones;
        });
  }

  // Marcar publicación como leída
  Future<void> marcarComoLeida(
    String condominioId,
    String publicacionId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .update({
        'isRead.$userId': true,
      });
    } catch (e) {
      print('Error al marcar publicación como leída: $e');
    }
  }

  // Actualizar estado de publicación
  Future<void> actualizarEstadoPublicacion(
    String condominioId,
    String publicacionId,
    String nuevoEstado,
  ) async {
    try {
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .update({'estado': nuevoEstado});
    } catch (e) {
      print('Error al actualizar estado de publicación: $e');
      throw Exception('Error al actualizar el estado de la publicación');
    }
  }

  // Generar notificaciones según el tipo de publicación
  Future<void> _generarNotificaciones(
    String condominioId,
    PublicacionModel publicacion,
  ) async {
    try {
      if (publicacion.tipoPublicacion == 'residentes') {
        // Obtener todos los residentes del condominio
        final residentes = await _firestoreService.obtenerResidentesCondominio(condominioId);
        
        for (final residente in residentes) {
          await _notificationService.createUserNotification(
            condominioId: condominioId,
            userId: residente.uid,
            userType: 'residentes',
            tipoNotificacion: 'publicacion',
            contenido: 'Nueva publicación: ${publicacion.titulo}',
            additionalData: {
              'publicacionId': publicacion.id,
              'tipoPublicacion': publicacion.tipoPublicacion,
            },
          );
        }
      } else if (publicacion.tipoPublicacion == 'trabajadores') {
        // TODO: Implementar cuando se agreguen los trabajadores
        // Por ahora, solo preparamos la estructura
        print('Notificación para trabajadores preparada para: ${publicacion.titulo}');
      }
    } catch (e) {
      print('Error al generar notificaciones: $e');
    }
  }

  // Obtener una publicación específica por ID
  Future<PublicacionModel?> obtenerPublicacionPorId(
    String condominioId,
    String publicacionId,
  ) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .get();

      if (doc.exists) {
        return PublicacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener publicación: $e');
      return null;
    }
  }

  // Actualizar publicación existente
  Future<void> actualizarPublicacion({
    required String condominioId,
    required String publicacionId,
    required String tipoPublicacion,
    required String contenido,
    required String titulo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .update({
        'tipoPublicacion': tipoPublicacion,
        'contenido': contenido,
        'titulo': titulo,
        'additionalData': additionalData,
      });
    } catch (e) {
      print('Error al actualizar publicación: $e');
      throw Exception('Error al actualizar la publicación: $e');
    }
  }

  // Eliminar publicación
  Future<void> eliminarPublicacion(
    String condominioId,
    String publicacionId,
  ) async {
    try {
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('comunicaciones')
          .doc('publicaciones')
          .collection('publicaciones')
          .doc(publicacionId)
          .delete();
    } catch (e) {
      print('Error al eliminar publicación: $e');
      throw Exception('Error al eliminar la publicación');
    }
  }

  // Método para corregir publicaciones con estado incorrecto
  Future<void> corregirEstadoPublicaciones(String condominioId) async {
    try {
      print('🔧 Iniciando corrección de estado de publicaciones');
      
      // Actualizar directamente los documentos específicos que vemos en los logs
      final docIds = ['TAN1hojXJAGAkN8FpVha', 'VyJQnxieP592RMHLFNs5'];
      
      for (String docId in docIds) {
        try {
          print('🔄 Actualizando documento $docId a estado activa');
          await _firestore
              .collection('condominios')
              .doc(condominioId)
              .collection('comunicaciones')
              .doc('publicaciones')
              .collection('publicaciones')
              .doc(docId)
              .update({'estado': 'activa'});
          print('✅ Documento $docId actualizado exitosamente');
        } catch (e) {
          print('❌ Error actualizando documento $docId: $e');
        }
      }
      
      print('✅ Corrección de estado completada');
    } catch (e) {
      print('❌ Error en corrección de estado: $e');
      rethrow;
    }
  }
}