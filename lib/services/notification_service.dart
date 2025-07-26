import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear notificación en la colección del condominio
  Future<void> createCondominioNotification({
    required String condominioId,
    required String tipoNotificacion,
    required String contenido,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final now = DateTime.now();
      final notificationId = _firestore.collection('temp').doc().id;

      final notification = NotificationModel(
        id: notificationId,
        fechaRegistro: now.toIso8601String(),
        notificationType: tipoNotificacion,
        content: contenido,
        isRead: null,
        status: 'pendiente',
        additionalData: additionalData,
      );

      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('notificaciones')
          .doc(notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }

  // Crear notificación para un usuario específico
  Future<void> createUserNotification({
    required String condominioId,
    required String userId,
    required String userType, // 'residentes', 'comite', 'trabajadores'
    required String tipoNotificacion,
    required String contenido,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final now = DateTime.now();
      final notificationId = _firestore.collection('temp').doc().id;

      final notification = NotificationModel(
        id: notificationId,
        fechaRegistro: now.toIso8601String(),
        notificationType: tipoNotificacion,
        content: contenido,
        isRead: null,
        status: 'no_leida',
        additionalData: additionalData,
      );

      await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection(userType)
          .doc(userId)
          .collection('notificaciones')
          .doc(notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Error al crear notificación de usuario: $e');
    }
  }

  // Escuchar notificaciones del condominio
  Stream<List<NotificationModel>> getCondominioNotifications(
    String condominioId,
  ) {
    print('Obteniendo notificaciones para condominio: $condominioId');
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('notificaciones')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            print('Snapshot recibido: ${snapshot.docs.length} documentos');
            try {
              final result = snapshot.docs
                  .map((doc) {
                    print('Procesando documento: ${doc.id}');
                    try {
                      return NotificationModel.fromMap(doc.data());
                    } catch (e) {
                      print('Error al convertir documento ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((notification) => notification != null)
                  .cast<NotificationModel>()
                  .toList();
              print('Notificaciones procesadas: ${result.length}');
              return result;
            } catch (e) {
              print('Error al procesar snapshot: $e');
              return <NotificationModel>[];
            }
          },
        );
  }

  // Escuchar notificaciones de un usuario
  Stream<List<NotificationModel>> getUserNotifications({
    required String condominioId,
    required String userId,
    required String userType,
  }) {
    try {
      return _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection(userType)
          .doc(userId)
          .collection('notificaciones')
          .orderBy('fechaRegistro', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data()))
                .where((notification) => notification.notificationType != 'confirmacion_entrega') // Filtrar notificaciones de entrega
                .toList(),
          );
    } catch (e) {
      print('Error al escuchar notificaciones de usuario: $e');
      throw Exception('Error al escuchar notificaciones de usuario: $e');
    }
  }

  // Obtener notificaciones de confirmación de entrega para un usuario
  Future<List<NotificationModel>> getNotificationsForUser(
    String userId,
    String condominioId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(userId)
          .collection('notificaciones')
          .where('tipoNotificacion', isEqualTo: 'confirmacion_entrega')
          .get();
      
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      
      // Ordenar en memoria para evitar el índice compuesto
      notifications.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      
      return notifications;
    } catch (e) {
      print('Error al obtener notificaciones de entrega: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead({
    required String condominioId,
    required String notificationId,
    required String userId,
    required String userType,
    bool isCondominioNotification = false,
    String? targetUserId,
    String? targetUserType,
  }) async {
    try {
      final readData = {
        'id': userId,
        'tipo': userType,
        'fechaLectura': DateTime.now().toIso8601String(),
      };

      if (isCondominioNotification) {
        await _firestore
            .collection(condominioId)
            .doc('comunicaciones')
            .collection('notificaciones')
            .doc(notificationId)
            .update({'isRead': readData});
      } else {
        await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection(targetUserType ?? userType)
            .doc(targetUserId ?? userId)
            .collection('notificaciones')
            .doc(notificationId)
            .update({'isRead': readData});
      }
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Actualizar estado de notificación
  Future<void> updateNotificationStatus({
    required String condominioId,
    required String notificationId,
    required String newStatus,
    bool isCondominioNotification = false,
    String? userId,
    String? userType,
  }) async {
    try {
      if (isCondominioNotification) {
        await _firestore
            .collection(condominioId)
            .doc('comunicaciones')
            .collection('notificaciones')
            .doc(notificationId)
            .update({'estado': newStatus});
      } else {
        await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection(userType!)
            .doc(userId!)
            .collection('notificaciones')
            .doc(notificationId)
            .update({'estado': newStatus});
      }
    } catch (e) {
      throw Exception('Error al actualizar estado de notificación: $e');
    }
  }

  // Contar notificaciones no leídas del condominio
  Stream<int> getUnreadCondominioNotificationsCount(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('notificaciones')
        .where('isRead', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Contar notificaciones no leídas de un usuario
  Stream<int> getUnreadUserNotificationsCount({
    required String condominioId,
    required String userId,
    required String userType,
  }) {
    return _firestore
        .collection(condominioId)
        .doc('usuarios')
        .collection(userType)
        .doc(userId)
        .collection('notificaciones')
        .where('isRead', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['tipoNotificacion'] != 'confirmacion_entrega')
            .length);
  }

  // Eliminar notificación específica
  Future<void> deleteNotification({
    required String condominioId,
    required String notificationId,
    required String userId,
    required String userType,
    bool isCondominioNotification = false,
  }) async {
    try {
      if (isCondominioNotification) {
        await _firestore
            .collection(condominioId)
            .doc('comunicaciones')
            .collection('notificaciones')
            .doc(notificationId)
            .delete();
      } else {
        await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection(userType)
            .doc(userId)
            .collection('notificaciones')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('❌ Error al eliminar notificación: $e');
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // ✅ CORREGIDO: Método para borrar notificaciones de mensajes del condominio
  Future<void> borrarNotificacionesMensajeCondominio({
    required String condominioId,
    required String chatId,
  }) async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('notificaciones')
          .where('tipoNotificacion', isEqualTo: 'mensaje')
          .get();

      // Filtrar y eliminar notificaciones del chat específico
      for (final doc in notificationsSnapshot.docs) {
        final data = doc.data();
        final additionalData = data['additionalData'] as Map<String, dynamic>?;
        if (additionalData?['chatId'] == chatId) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('❌ Error al eliminar notificaciones de mensaje del condominio: $e');
    }
  }

  // Eliminar notificaciones de mensaje específico
  Future<void> deleteMessageNotifications({
    required String condominioId,
    required String chatId,
    required String userId,
    required String userType,
  }) async {
    try {
      // Obtener notificaciones del usuario relacionadas con el chat
      final notificationsSnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection(userType)
          .doc(userId)
          .collection('notificaciones')
          .where('tipoNotificacion', isEqualTo: 'nuevo_mensaje')
          .get();

      // Filtrar y eliminar notificaciones del chat específico
      for (final doc in notificationsSnapshot.docs) {
        final data = doc.data();
        final additionalData = data['additionalData'] as Map<String, dynamic>?;
        if (additionalData?['chatId'] == chatId) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('❌ Error al eliminar notificaciones de mensaje: $e');
    }
  }

  // Método enviarNotificacion (alias para createUserNotification)
  Future<void> enviarNotificacion({
    required String condominioId,
    required String userId,
    required String userType,
    required String tipoNotificacion,
    required String contenido,
    Map<String, dynamic>? additionalData,
  }) async {
    await createUserNotification(
      condominioId: condominioId,
      userId: userId,
      userType: userType,
      tipoNotificacion: tipoNotificacion,
      contenido: contenido,
      additionalData: additionalData,
    );
  }

  // MÉTODOS ESPECÍFICOS PARA CONFIRMACIÓN DE ENTREGA DE CORRESPONDENCIA
  
  /// Envía una notificación de confirmación de entrega al residente
  Future<void> enviarNotificacionConfirmacionEntrega(
    String condominioId,
    String residenteId,
    String correspondenciaId,
    String tipoCorrespondencia,
  ) async {
    try {
      // Usar la estructura estándar de notificaciones
      await createUserNotification(
        condominioId: condominioId,
        userId: residenteId,
        userType: 'residentes',
        tipoNotificacion: 'confirmacion_entrega',
        contenido: 'Se requiere confirmar la entrega de $tipoCorrespondencia',
        additionalData: {
          'correspondenciaId': correspondenciaId,
          'tipoCorrespondencia': tipoCorrespondencia,
          'estado': 'pendiente', // pendiente, aceptada, rechazada
          'mostrarHasta': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'prioridad': 'alta',
        },
      );

      print('Notificación de confirmación enviada exitosamente al residente $residenteId');
    } catch (e) {
      print('Error al enviar notificación de confirmación: $e');
      rethrow;
    }
  }

  /// Obtiene las notificaciones de un residente
  Stream<QuerySnapshot> getNotificacionesResidente(
    String condominioId,
    String residenteId,
  ) {
    return _firestore
        .collection(condominioId)
        .doc('usuarios')
        .collection('residentes')
        .doc(residenteId)
        .collection('notificaciones')
        .orderBy('fechaRegistro', descending: true)
        .snapshots();
  }

  /// Marca una notificación como leída
  Future<void> marcarComoLeida(
    String condominioId,
    String residenteId,
    String notificacionId,
  ) async {
    try {
      final fechaLectura = DateTime.now().toIso8601String();
      await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .collection('notificaciones')
          .doc(notificacionId)
          .update({
        'isRead': {
          'id': residenteId,
          'tipo': 'residentes',
          'fechaLectura': fechaLectura,
        }
      });
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      rethrow;
    }
  }

  /// Responde a una notificación de confirmación de entrega
  Future<void> responderConfirmacionEntrega(
    String condominioId,
    String residenteId,
    String notificacionId,
    bool aceptada,
  ) async {
    try {
      final estado = aceptada ? 'aceptada' : 'rechazada';
      final fechaRespuesta = DateTime.now().toIso8601String();
      
      // Primero obtener la notificación para extraer el correspondenciaId
      final notifDoc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .collection('notificaciones')
          .doc(notificacionId)
          .get();
      
      if (!notifDoc.exists) {
        throw Exception('Notificación no encontrada');
      }
      
      final notifData = notifDoc.data()!;
      final correspondenciaId = notifData['additionalData']?['correspondenciaId'];
      
      if (correspondenciaId == null) {
        throw Exception('ID de correspondencia no encontrado en la notificación');
      }
      
      // Actualizar la notificación
      await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .collection('notificaciones')
          .doc(notificacionId)
          .update({
        'estado': estado,
        'fechaRespuesta': fechaRespuesta,
        'isRead': {
          'id': residenteId,
          'tipo': 'residentes',
          'fechaLectura': fechaRespuesta,
        },
      });
      
      // Actualizar el campo notificacionEntrega en la correspondencia
      // Buscar la notificación más reciente sin respuesta para este correspondenciaId
      final correspondenciaDoc = await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .get();
      
      if (correspondenciaDoc.exists) {
        final correspondenciaData = correspondenciaDoc.data()!;
        final notificacionEntrega = correspondenciaData['notificacionEntrega'] as Map<String, dynamic>? ?? {};
        
        // Buscar la notificación más reciente pendiente
        String? timestampToUpdate;
        for (var entry in notificacionEntrega.entries) {
          final notifData = entry.value as Map<String, dynamic>;
          if (notifData['respuesta'] == 'pendiente') {
            timestampToUpdate = entry.key;
            break;
          }
        }
        
        if (timestampToUpdate != null) {
          // Generar timestamp de respuesta
          final now = DateTime.now();
          final timestampRespuesta = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
          
          await _firestore
              .collection(condominioId)
              .doc('correspondencia')
              .collection('correspondencias')
              .doc(correspondenciaId)
              .update({
            'notificacionEntrega.$timestampToUpdate.respuesta': estado,
            'notificacionEntrega.$timestampToUpdate.fechaRespuesta': timestampRespuesta,
          });
          
          print('Campo notificacionEntrega actualizado: $estado en $timestampRespuesta');
        }
      }

      print('Respuesta de confirmación guardada: $estado');
    } catch (e) {
      print('Error al responder confirmación: $e');
      rethrow;
    }
  }

  /// Elimina notificaciones expiradas
  Future<void> limpiarNotificacionesExpiradas(
    String condominioId,
    String residenteId,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('notificaciones')
          .collection('residentes')
          .doc(residenteId)
          .collection('notificaciones')
          .where('mostrarHasta', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Notificaciones expiradas eliminadas: ${querySnapshot.docs.length}');
    } catch (e) {
      print('Error al limpiar notificaciones expiradas: $e');
    }
  }

  /// Obtiene el estado de una notificación específica
  Future<Map<String, dynamic>?> getEstadoNotificacion(
    String condominioId,
    String residenteId,
    String notificacionId,
  ) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .collection('notificaciones')
          .doc(notificacionId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error al obtener estado de notificación: $e');
      return null;
    }
  }

  /// Stream para escuchar cambios en una notificación específica
  Stream<DocumentSnapshot> escucharNotificacion(
    String condominioId,
    String residenteId,
    String notificacionId,
  ) {
    return _firestore
        .collection(condominioId)
        .doc('usuarios')
        .collection('residentes')
        .doc(residenteId)
        .collection('notificaciones')
        .doc(notificacionId)
        .snapshots();
  }
}
