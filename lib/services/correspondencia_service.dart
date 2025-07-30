import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/correspondencia_config_model.dart';
import 'notification_service.dart';

class CorrespondenciaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Obtener configuración de correspondencia
  Future<CorrespondenciaConfigModel> getCorrespondenciaConfig(String condominioId) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .get();

      if (doc.exists) {
        return CorrespondenciaConfigModel.fromFirestore(doc);
      } else {
        // Si no existe, crear configuración por defecto
        final defaultConfig = CorrespondenciaConfigModel.defaultConfig;
        await saveCorrespondenciaConfig(condominioId, defaultConfig);
        return defaultConfig;
      }
    } catch (e) {
      throw Exception('Error al obtener configuración de correspondencia: $e');
    }
  }

  // Obtener configuración de correspondencia en tiempo real
  Stream<CorrespondenciaConfigModel> getCorrespondenciaConfigStream(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('correspondencia')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return CorrespondenciaConfigModel.fromFirestore(snapshot);
      } else {
        return CorrespondenciaConfigModel.defaultConfig;
      }
    });
  }

  // Guardar configuración de correspondencia
  Future<void> saveCorrespondenciaConfig(
    String condominioId,
    CorrespondenciaConfigModel config,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .set(config.toMap());
    } catch (e) {
      throw Exception('Error al guardar configuración de correspondencia: $e');
    }
  }

  /// Crea una nueva correspondencia
  Future<String> createCorrespondencia(
    String condominioId,
    CorrespondenciaModel correspondencia,
  ) async {
    try {
      final docRef = _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc();

      final correspondenciaData = correspondencia.toMap();
      correspondenciaData['id'] = docRef.id;

      await docRef.set(correspondenciaData);
      
      // Enviar notificación al residente si no es "residente a un tercero"
      if (correspondencia.tipoEntrega != 'residente a un tercero' && 
          correspondencia.residenteIdEntrega != null && 
          correspondencia.residenteIdEntrega!.isNotEmpty) {
        await _enviarNotificacionRecepcionCorrespondencia(
          condominioId,
          correspondencia.residenteIdEntrega!,
          docRef.id,
          correspondencia,
        );
      }
      
      return docRef.id;
    } catch (e) {
      print('Error al crear correspondencia: $e');
      throw Exception('Error al crear correspondencia: $e');
    }
  }

  // Obtener correspondencias
  Stream<List<CorrespondenciaModel>> getCorrespondencias(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('correspondencia')
        .collection('correspondencias')
        .orderBy('fechaHoraRecepcion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CorrespondenciaModel.fromFirestore(doc))
            .toList());
  }

  // Actualizar correspondencia
  Future<void> updateCorrespondencia(
    String condominioId,
    String correspondenciaId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .update(updates);
    } catch (e) {
      print('Error al actualizar correspondencia: $e');
      throw Exception('Error al actualizar correspondencia: $e');
    }
  }

  // Marcar correspondencia como entregada
  Future<void> marcarComoEntregada(
    String condominioId,
    String correspondenciaId,
    String fechaHoraEntrega,
    String? firma,
  ) async {
    try {
      final updates = {
        'fechaHoraEntrega': fechaHoraEntrega,
        if (firma != null) 'firma': firma,
      };
      
      await updateCorrespondencia(condominioId, correspondenciaId, updates);
    } catch (e) {
      throw Exception('Error al marcar correspondencia como entregada: $e');
    }
  }

  // Eliminar correspondencia
  Future<void> deleteCorrespondencia(
    String condominioId,
    String correspondenciaId,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar correspondencia: $e');
    }
  }

  // Obtener correspondencia por ID
  Future<CorrespondenciaModel?> getCorrespondenciaById(
    String condominioId,
    String correspondenciaId,
  ) async {
    try {
      final doc = await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .get();

      if (doc.exists) {
        return CorrespondenciaModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener correspondencia: $e');
    }
  }

  /// Envía notificación de recepción de correspondencia al residente
  Future<void> _enviarNotificacionRecepcionCorrespondencia(
    String condominioId,
    String residenteId,
    String correspondenciaId,
    CorrespondenciaModel correspondencia,
  ) async {
    try {
      final fechaRecepcion = DateTime.tryParse(correspondencia.fechaHoraRecepcion);
      final fechaFormateada = fechaRecepcion != null
          ? '${fechaRecepcion.day.toString().padLeft(2, '0')}/${fechaRecepcion.month.toString().padLeft(2, '0')}/${fechaRecepcion.year} a las ${fechaRecepcion.hour.toString().padLeft(2, '0')}:${fechaRecepcion.minute.toString().padLeft(2, '0')}'
          : correspondencia.fechaHoraRecepcion;

      final contenido = 'Se ha recibido una correspondencia de tipo ${correspondencia.tipoCorrespondencia} el $fechaFormateada';
      
      final additionalData = {
        'correspondenciaId': correspondenciaId,
        'tipoCorrespondencia': correspondencia.tipoCorrespondencia,
        'fechaHoraRecepcion': correspondencia.fechaHoraRecepcion,
        'viviendaRecepcion': correspondencia.viviendaRecepcion,
        'datosEntrega': correspondencia.datosEntrega,
        'tipoEntrega': correspondencia.tipoEntrega,
        'tieneAdjuntos': correspondencia.adjuntos.isNotEmpty,
        'adjuntos': correspondencia.adjuntos,
      };

      await _notificationService.createUserNotification(
        condominioId: condominioId,
        userId: residenteId,
        userType: 'residentes',
        tipoNotificacion: 'correspondencia_recibida',
        contenido: contenido,
        additionalData: additionalData,
      );

      print('Notificación de correspondencia enviada al residente $residenteId');
    } catch (e) {
      print('Error al enviar notificación de correspondencia: $e');
      // No lanzamos excepción para no afectar el guardado de la correspondencia
    }
  }

  /// Envía notificación de mensaje adicional al residente
  Future<void> enviarNotificacionMensajeAdicional(
    String condominioId,
    String residenteId,
    String correspondenciaId,
    String mensaje,
    CorrespondenciaModel correspondencia,
  ) async {
    try {
      final contenido = 'Se ha agregado un nuevo mensaje a su correspondencia de tipo ${correspondencia.tipoCorrespondencia}: "$mensaje"';
      
      final additionalData = {
        'correspondenciaId': correspondenciaId,
        'tipoCorrespondencia': correspondencia.tipoCorrespondencia,
        'mensaje': mensaje,
        'fechaHoraRecepcion': correspondencia.fechaHoraRecepcion,
        'viviendaRecepcion': correspondencia.viviendaRecepcion,
        'datosEntrega': correspondencia.datosEntrega,
        'tipoEntrega': correspondencia.tipoEntrega,
      };

      await _notificationService.createUserNotification(
        condominioId: condominioId,
        userId: residenteId,
        userType: 'residentes',
        tipoNotificacion: 'mensaje_adicional_correspondencia',
        contenido: contenido,
        additionalData: additionalData,
      );

      print('Notificación de mensaje adicional enviada al residente $residenteId');
    } catch (e) {
      print('Error al enviar notificación de mensaje adicional: $e');
      // No lanzamos excepción para no afectar el guardado del mensaje
    }
  }

  /// Registra una notificación de entrega en el campo notificacionEntrega
  Future<void> registrarNotificacionEntrega(
    String condominioId,
    String correspondenciaId,
    String timestampEnvio,
  ) async {
    try {
      final notificacionData = {
        'fechaEnvio': timestampEnvio,
        'respuesta': 'pendiente',
        'fechaRespuesta': null,
      };

      await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .update({
        'notificacionEntrega.$timestampEnvio': notificacionData,
      });

      print('Notificación de entrega registrada: $timestampEnvio');
    } catch (e) {
      print('Error al registrar notificación de entrega: $e');
      throw Exception('Error al registrar notificación de entrega: $e');
    }
  }

  /// Actualiza la respuesta de una notificación de entrega
  Future<void> actualizarRespuestaNotificacionEntrega(
    String condominioId,
    String correspondenciaId,
    String timestampEnvio,
    String respuesta,
    String timestampRespuesta,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('correspondencia')
          .collection('correspondencias')
          .doc(correspondenciaId)
          .update({
        'notificacionEntrega.$timestampEnvio.respuesta': respuesta,
        'notificacionEntrega.$timestampEnvio.fechaRespuesta': timestampRespuesta,
      });

      print('Respuesta de notificación actualizada: $respuesta en $timestampRespuesta');
    } catch (e) {
      print('Error al actualizar respuesta de notificación: $e');
      throw Exception('Error al actualizar respuesta de notificación: $e');
    }
  }

  /// Escucha cambios en el campo notificacionEntrega de una correspondencia específica
  Stream<Map<String, Map<String, dynamic>>> escucharNotificacionesEntrega(
    String condominioId,
    String correspondenciaId,
  ) {
    return _firestore
        .collection(condominioId)
        .doc('correspondencia')
        .collection('correspondencias')
        .doc(correspondenciaId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final notificaciones = data['notificacionEntrega'] as Map<String, dynamic>?;
        if (notificaciones != null) {
          return notificaciones.map((key, value) => 
            MapEntry(key, Map<String, dynamic>.from(value as Map)));
        }
      }
      return <String, Map<String, dynamic>>{};
    });
  }

}