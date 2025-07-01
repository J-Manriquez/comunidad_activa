import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/services/notification_service.dart';
import '../models/mensaje_model.dart';
import '../models/user_model.dart';
import '../models/residente_model.dart';
import '../models/administrador_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class MensajeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Crear o obtener chat entre dos usuarios
  Future<String> crearOObtenerChatPrivado({
    required String condominioId,
    required String usuario1Id,
    required String usuario2Id,
    required String tipo, // Nuevo parámetro para el tipo de mensaj
  }) async {
    try {
      // Ordenar los IDs para consistencia
      List<String> participantes = [usuario1Id, usuario2Id]..sort();

      // Buscar chat existente
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .where('participantes', isEqualTo: participantes)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Crear nuevo chat
      final docRef = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .add({
            'fechaRegistro': DateTime.now().toIso8601String(),
            'participantes': participantes,
            'tipo': tipo,
          });

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear/obtener chat privado: $e');
      throw Exception('Error al crear chat: $e');
    }
  }

  // Crear o obtener chat con conserjería - VERSIÓN CORREGIDA
  Future<String> crearOObtenerChatConserjeria({
    required String condominioId,
    required String residenteId,
  }) async {
    try {
      // Buscar chat con conserjería existente - SIN múltiples array-contains
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .where('tipo', isEqualTo: 'conserjeria')
          .get();

      // Filtrar en memoria para encontrar el chat específico
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final participantes = List<String>.from(data['participantes'] ?? []);
        if (participantes.contains('CONSERJERIA') &&
            participantes.contains(residenteId)) {
          return doc.id;
        }
      }

      // Crear chat con conserjería si no existe
      final docRef = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .add({
            'fechaRegistro': DateTime.now().toIso8601String(),
            'participantes': ['CONSERJERIA', residenteId],
            'tipo': 'conserjeria',
          });

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear/obtener chat conserjería: $e');
      throw Exception('Error al crear chat conserjería: $e');
    }
  }

  // Crear o obtener chat grupal del condominio - VERSIÓN CORREGIDA
  Future<String> crearOObtenerChatGrupal({required String condominioId}) async {
    try {
      // Buscar chat grupal existente
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .where('tipo', isEqualTo: 'grupal')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Obtener todos los residentes y administrador
      final residentes = await _firestoreService.obtenerResidentesCondominio(
        condominioId,
      );
      final administrador = await _firestoreService.getAdministradorData(
        condominioId,
      );

      List<String> participantes = ['GRUPO_CONDOMINIO'];
      participantes.addAll(residentes.map((r) => r.uid));
      if (administrador != null) {
        participantes.add(administrador.uid);
      }

      // Crear chat grupal
      final docRef = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .add({
            'fechaRegistro': DateTime.now().toIso8601String(),
            'participantes': participantes,
            'tipo': 'grupal',
          });

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear/obtener chat grupal: $e');
      throw Exception('Error al crear chat grupal: $e');
    }
  }

  // Agregar residente al chat grupal
  Future<void> agregarResidenteAChatGrupal({
    required String condominioId,
    required String residenteId,
  }) async {
    try {
      final chatId = await crearOObtenerChatGrupal(condominioId: condominioId);

      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .update({
            'participantes': FieldValue.arrayUnion([residenteId]),
          });
    } catch (e) {
      print('❌ Error al agregar residente al chat grupal: $e');
    }
  }

  // Enviar mensaje - VERSIÓN ACTUALIZADA CON NOTIFICACIONES
  Future<void> enviarMensaje({
    required String condominioId,
    required String chatId,
    required String texto,
    required String autorUid,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Enviar el mensaje
      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .add({
            'texto': texto,
            'additionalData': additionalData,
            'isRead': null,
            'fechaHoraCreacion': DateTime.now().toIso8601String(),
            'autorUid': autorUid,
          });

      // Obtener información del chat para enviar notificaciones
      final chatDoc = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        final chatData = chatDoc.data()!;
        final participantes = List<String>.from(
          chatData['participantes'] ?? [],
        );
        final tipoChat = chatData['tipo'] ?? 'privado';

        // Obtener información del remitente
        final autorInfo = await _obtenerInfoUsuario(condominioId, autorUid);
        final nombreAutor = autorInfo['nombre'] ?? 'Usuario';
        final tipoAutor = autorInfo['tipo'] ?? 'residente';

        // Enviar notificaciones a todos los participantes excepto al autor
        for (final participanteId in participantes) {
          if (participanteId != autorUid &&
              participanteId != 'GRUPO_CONDOMINIO') {
            await _enviarNotificacionMensaje(
              condominioId: condominioId,
              destinatarioId: participanteId,
              chatId: chatId,
              nombreRemitente: nombreAutor,
              tipoChat: tipoChat,
              texto: texto,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  // NUEVO: Método para obtener información del usuario
  // NUEVO: Método para obtener información del usuario
  Future<Map<String, String>> _obtenerInfoUsuario(
    String condominioId,
    String userId,
  ) async {
    try {
      // Intentar como residente
      final residenteDoc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(userId)
          .get();

      if (residenteDoc.exists) {
        final data = residenteDoc.data()!;
        return {'nombre': data['nombre'] ?? 'Residente', 'tipo': 'residente'};
      }

      // Intentar como administrador - RUTA CORREGIDA
      final adminDoc = await _firestore
          .collection(condominioId)
          .doc('administrador') // ✅ Ruta correcta según firebase-structure.txt
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data()!;
        // Verificar si el UID coincide con el administrador
        if (data['uid'] == userId) {
          return {
            'nombre': data['nombre'] ?? 'Administrador',
            'tipo': 'administrador',
          };
        }
      }

      // Si es conserjería
      if (userId == 'CONSERJERIA') {
        return {'nombre': 'Conserjería', 'tipo': 'conserjeria'};
      }

      return {'nombre': 'Usuario', 'tipo': 'desconocido'};
    } catch (e) {
      print('❌ Error al obtener info del usuario: $e');
      return {'nombre': 'Usuario', 'tipo': 'desconocido'};
    }
  }

  // NUEVO: Método para enviar notificación de mensaje
  Future<void> _enviarNotificacionMensaje({
    required String condominioId,
    required String destinatarioId,
    required String chatId,
    required String nombreRemitente,
    required String tipoChat,
    required String texto,
  }) async {
    try {
      final notificationService = NotificationService();

      // Determinar el tipo de usuario destinatario
      final infoDestinatario = await _obtenerInfoUsuario(
        condominioId,
        destinatarioId,
      );
      final tipoDestinatario = infoDestinatario['tipo'];

      // Crear contenido de la notificación
      String contenido;
      if (tipoChat == 'grupal') {
        contenido =
            '$nombreRemitente envió un mensaje al chat grupal: "${texto.length > 50 ? '${texto.substring(0, 50)}...' : texto}"';
      } else if (tipoChat == 'conserjeria') {
        contenido =
            '$nombreRemitente te envió un mensaje desde conserjería: "${texto.length > 50 ? '${texto.substring(0, 50)}...' : texto}"';
      } else {
        contenido =
            '$nombreRemitente te envió un mensaje: "${texto.length > 50 ? '${texto.substring(0, 50)}...' : texto}"';
      }

      // ✅ CORRECCIÓN: Enviar notificación según el tipo de destinatario
      if (tipoDestinatario == 'administrador') {
        // Para administradores: usar createCondominioNotification
        await notificationService.createCondominioNotification(
          condominioId: condominioId,
          tipoNotificacion: 'mensaje',
          contenido: contenido,
          additionalData: {
            'chatId': chatId,
            'senderName': nombreRemitente,
            'senderId': destinatarioId, // ID del remitente (residente)
            'tipoChat': tipoChat,
            'textoMensaje': texto,
          },
        );
      } else {
        // Para residentes: usar createUserNotification
        String userType = 'residentes';

        await notificationService.createUserNotification(
          condominioId: condominioId,
          userId: destinatarioId,
          userType: userType,
          tipoNotificacion: 'nuevo_mensaje',
          contenido: contenido,
          additionalData: {
            'chatId': chatId,
            'remitenteId': nombreRemitente,
            'tipoChat': tipoChat,
            'textoMensaje': texto,
          },
        );
      }
    } catch (e) {
      print('❌ Error al enviar notificación de mensaje: $e');
    }
  }

  // Marcar mensaje como leído
  Future<void> marcarMensajeComoLeido({
    required String condominioId,
    required String chatId,
    required String contenidoId,
    required String usuarioId,
    required String nombreUsuario,
  }) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .doc(contenidoId)
          .update({
            'isRead.$usuarioId': {
              'nombre': nombreUsuario,
              'fechaHora': DateTime.now().toIso8601String(),
            },
          });
    } catch (e) {
      print('❌ Error al marcar mensaje como leído: $e');
    }
  }

  // Marcar mensaje como leído y eliminar notificaciones
  Future<void> marcarMensajeComoLeidoYEliminarNotificaciones({
    required String condominioId,
    required String chatId,
    required String contenidoId,
    required String usuarioId,
    required String nombreUsuario,
    required String tipoUsuario, // 'residentes' o 'administrador'
  }) async {
    try {
      // Marcar mensaje como leído
      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .doc(contenidoId)
          .update({
            'isRead.$usuarioId': {
              'nombre': nombreUsuario,
              'fechaHora': DateTime.now().toIso8601String(),
            },
          });

      // Eliminar notificaciones de este chat para el usuario
      final notificationService = NotificationService();
      await notificationService.deleteMessageNotifications(
        condominioId: condominioId,
        chatId: chatId,
        userId: usuarioId,
        userType: tipoUsuario,
      );
    } catch (e) {
      print(
        '❌ Error al marcar mensaje como leído y eliminar notificaciones: $e',
      );
    }
  }

  // Marcar todos los mensajes del chat como leídos
  Future<void> marcarTodosMensajesComoLeidos({
    required String condominioId,
    required String chatId,
    required String usuarioId,
    required String nombreUsuario,
    required String tipoUsuario,
  }) async {
    try {
      // Obtener todos los mensajes del chat
      final mensajesSnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .get();

      // Marcar cada mensaje como leído si no lo está ya
      final batch = _firestore.batch();
      for (final doc in mensajesSnapshot.docs) {
        final data = doc.data();
        final isRead = data['isRead'] as Map<String, dynamic>?;

        // Solo marcar como leído si el usuario no lo ha leído ya
        if (isRead == null || !isRead.containsKey(usuarioId)) {
          batch.update(doc.reference, {
            'isRead.$usuarioId': {
              'nombre': nombreUsuario,
              'fechaHora': DateTime.now().toIso8601String(),
            },
          });
        }
      }

      await batch.commit();

      // Eliminar notificaciones de este chat para el usuario
      final notificationService = NotificationService();
      await notificationService.deleteMessageNotifications(
        condominioId: condominioId,
        chatId: chatId,
        userId: usuarioId,
        userType: tipoUsuario,
      );
    } catch (e) {
      print('❌ Error al marcar todos los mensajes como leídos: $e');
    }
  }

  // Obtener mensajes de un chat (últimos 20 mensajes)
  Stream<List<ContenidoMensajeModel>> obtenerMensajesChat({
    required String condominioId,
    required String chatId,
  }) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('mensajes')
        .doc(chatId)
        .collection('contenido')
        .orderBy('fechaHoraCreacion', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ContenidoMensajeModel.fromFirestore(doc.data(), doc.id),
              )
              .toList()
              .reversed
              .toList(), // Revertir para mostrar en orden cronológico
        );
  }

  // Obtener chats del usuario - VERSIÓN CORREGIDA
  Stream<List<MensajeModel>> obtenerChatsUsuario({
    required String condominioId,
    required String usuarioId,
  }) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('mensajes')
        .where('participantes', arrayContains: usuarioId)
        .snapshots()
        .map((snapshot) {
          // Filtrar y ordenar en memoria
          final docs = snapshot.docs
              .where(
                (doc) => doc.data()['tipo'] != null,
              ) // Filtrar documentos válidos
              .toList();

          docs.sort((a, b) {
            final fechaA = DateTime.parse(
              a.data()['fechaRegistro'] ?? DateTime.now().toIso8601String(),
            );
            final fechaB = DateTime.parse(
              b.data()['fechaRegistro'] ?? DateTime.now().toIso8601String(),
            );
            return fechaB.compareTo(fechaA); // Orden descendente
          });

          return docs
              .map((doc) => MensajeModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // Actualizar configuración de comunicación entre residentes a nivel de condominio
  Future<void> actualizarComunicacionEntreResidentes({
    required String condominioId,
    required bool permitir,
  }) async {
    try {
      await _firestore.collection(condominioId).doc('condominio').update({
        'comunicacionEntreResidentes': permitir,
      });
    } catch (e) {
      print(
        '❌ Error al actualizar configuración de comunicación entre residentes: $e',
      );
      throw Exception('Error al actualizar configuración: $e');
    }
  }

  // Verificar si la comunicación entre residentes está habilitada
  Future<bool> esComunicacionEntreResidentesHabilitada(
    String condominioId,
  ) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      return doc.data()?['comunicacionEntreResidentes'] ?? false;
    } catch (e) {
      print('❌ Error al verificar comunicación entre residentes: $e');
      return false;
    }
  }

  // Verificar si un residente permite mensajes de otros residentes
  Future<bool> residentePermiteMensajes({
    required String condominioId,
    required String residenteId,
  }) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .get();

      return doc.data()?['permitirMsjsResidentes'] ?? true;
    } catch (e) {
      print('❌ Error al verificar permisos de mensajes del residente: $e');
      return false;
    }
  }

  // Actualizar configuración de mensajes del residente
  Future<void> actualizarConfiguracionMensajes({
    required String condominioId,
    required String residenteId,
    required bool permitirMensajes,
  }) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteId)
          .update({'permitirMsjsResidentes': permitirMensajes});
    } catch (e) {
      print('❌ Error al actualizar configuración de mensajes: $e');
      throw Exception('Error al actualizar configuración: $e');
    }
  }

  // Buscar residentes por nombre - VERSIÓN CORREGIDA
  Future<List<ResidenteModel>> buscarResidentes({
    required String condominioId,
    required String query,
  }) async {
    try {
      final residentes = await _firestoreService.obtenerResidentesCondominio(
        condominioId,
      );

      if (query.isEmpty) {
        return residentes;
      }

      return residentes.where((residente) {
        return residente.nombre.toLowerCase().contains(query.toLowerCase()) ||
            residente.email.toLowerCase().contains(query.toLowerCase()) ||
            residente.descripcionVivienda.toLowerCase().contains(
              query.toLowerCase(),
            );
      }).toList();
    } catch (e) {
      print('❌ Error al buscar residentes: $e');
      return [];
    }
  }

  // ✅ CORREGIDO: Contar mensajes no leídos en un chat
  Future<int> contarMensajesNoLeidos({
    required String condominioId,
    required String chatId,
    required String usuarioId,
  }) async {
    try {
      final mensajesSnapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('mensajes')
          .doc(chatId)
          .collection('contenido')
          .get();

      int contador = 0;
      for (final doc in mensajesSnapshot.docs) {
        final data = doc.data();
        final autorUid = data['autorUid'] as String?;
        final isRead = data['isRead'] as Map<String, dynamic>?;

        // Contar solo mensajes que no son del usuario actual y que no ha leído
        if (autorUid != usuarioId) {
          // Si isRead es null o no contiene al usuario, o si contiene al usuario pero es false
          final usuarioHaLeido = isRead?[usuarioId] != null;
          if (!usuarioHaLeido) {
            contador++;
          }
        }
      }

      return contador;
    } catch (e) {
      print('❌ Error al contar mensajes no leídos: $e');
      return 0;
    }
  }
}
