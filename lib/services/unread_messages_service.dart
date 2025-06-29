import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UnreadMessagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, StreamController<int>> _controllers = {};

  // Obtener stream de mensajes no leídos para un chat específico
  Stream<int> getUnreadMessagesStream({
    required String condominioId,
    required String chatId,
    required String usuarioId,
  }) {
    final key = '${condominioId}_${chatId}_$usuarioId';
    
    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<int>.broadcast();
    _controllers[key] = controller;

    // Escuchar cambios en la subcolección de contenido del chat
    final subscription = _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('mensajes')
        .doc(chatId)
        .collection('contenido')
        .snapshots()
        .listen((snapshot) {
      _calculateUnreadCount(
        snapshot: snapshot,
        usuarioId: usuarioId,
        controller: controller,
      );
    }, onError: (error) {
      print('❌ Error en stream de mensajes no leídos: $error');
      controller.addError(error);
    });

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  // Calcular cantidad de mensajes no leídos
  void _calculateUnreadCount({
    required QuerySnapshot snapshot,
    required String usuarioId,
    required StreamController<int> controller,
  }) {
    int unreadCount = 0;
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final autorUid = data['autorUid'] as String?;
      final isRead = data['isRead'] as Map<String, dynamic>?;

      // Contar solo mensajes que no son del usuario actual
      if (autorUid != null && autorUid != usuarioId) {
        // Si isRead es null o no contiene al usuario, el mensaje no está leído
        final usuarioHaLeido = isRead?[usuarioId] == true;
        if (!usuarioHaLeido) {
          unreadCount++;
        }
      }
    }

    controller.add(unreadCount);
  }

  // Obtener mapa de contadores para múltiples chats
  Stream<Map<String, int>> getMultipleUnreadCountsStream({
    required String condominioId,
    required List<String> chatIds,
    required String usuarioId,
  }) {
    final controller = StreamController<Map<String, int>>.broadcast();
    final Map<String, int> currentCounts = {};
    final List<StreamSubscription> subscriptions = [];

    for (final chatId in chatIds) {
      final subscription = getUnreadMessagesStream(
        condominioId: condominioId,
        chatId: chatId,
        usuarioId: usuarioId,
      ).listen((count) {
        currentCounts[chatId] = count;
        controller.add(Map.from(currentCounts));
      });
      subscriptions.add(subscription);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  // Marcar mensajes como leídos cuando se entra a un chat
  Future<void> markMessagesAsRead({
    required String condominioId,
    required String chatId,
    required String usuarioId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Obtener todos los mensajes del chat que no son del usuario actual
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .where('autorUid', isNotEqualTo: usuarioId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isRead = Map<String, dynamic>.from(data['isRead'] ?? {});
        
        // Marcar como leído para este usuario
        isRead[usuarioId] = true;
        
        batch.update(doc.reference, {'isRead': isRead});
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error al marcar mensajes como leídos: $e');
    }
  }

  // Obtener lista de chats del usuario con sus tipos
  Future<List<Map<String, String>>> getUserChats({
    required String condominioId,
    required String usuarioId,
    required bool isAdmin,
  }) async {
    try {
      final List<Map<String, String>> chats = [];
      
      // Obtener todos los chats donde el usuario participa
      final snapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .where('participantes', arrayContains: usuarioId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'] as String? ?? 'privado';
        
        chats.add({
          'id': doc.id,
          'tipo': tipo,
        });
      }

      // Agregar chat grupal si existe
      final grupalSnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .where('tipo', isEqualTo: 'grupal')
          .limit(1)
          .get();

      if (grupalSnapshot.docs.isNotEmpty) {
        final grupalDoc = grupalSnapshot.docs.first;
        final participantes = List<String>.from(
          grupalDoc.data()['participantes'] ?? [],
        );
        
        if (participantes.contains(usuarioId) || 
            participantes.contains('GRUPO_CONDOMINIO')) {
          chats.add({
            'id': grupalDoc.id,
            'tipo': 'grupal',
          });
        }
      }

      return chats;
    } catch (e) {
      print('❌ Error al obtener chats del usuario: $e');
      return [];
    }
  }

  // Limpiar subscripciones
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _controllers.clear();
  }

  // Limpiar subscripción específica
  void disposeChat({
    required String condominioId,
    required String chatId,
    required String usuarioId,
  }) {
    final key = '${condominioId}_${chatId}_$usuarioId';
    
    _subscriptions[key]?.cancel();
    _controllers[key]?.close();
    
    _subscriptions.remove(key);
    _controllers.remove(key);
  }
}