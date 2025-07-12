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
                .toList(),
          );
    } catch (e) {
      print('Error al escuchar notificaciones de usuario: $e');
      throw Exception('Error al escuchar notificaciones de usuario: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> markNotificationAsRead({
    required String condominioId,
    required String notificationId,
    required String userName,
    required String userId,
    required String userType,
    bool isCondominioNotification = false,
    String? targetUserId,
    String? targetUserType,
  }) async {
    try {
      final readData = {
        'nombre': userName,
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
        .map((snapshot) => snapshot.docs.length);
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
}
