import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reclamo_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';

class ReclamoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  // Crear un nuevo reclamo
  // Actualizar el método crearReclamo
  Future<void> crearReclamo({
    required String condominioId,
    required String residenteId,
    required String tipoReclamo,
    required String contenido,
  }) async {
    try {
      print('🔄 Iniciando creación de reclamo para residente: $residenteId');
      print('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
      
      final now = DateTime.now();
      final reclamoId = _firestore.collection('temp').doc().id;
      print('📝 ID del reclamo generado: $reclamoId');
  
      // Obtener datos del residente ANTES de crear el reclamo
      print('🔍 Obteniendo datos del residente...');
      final residente = await _firestoreService.getResidenteData(residenteId);
      final nombreResidente = residente?.nombre ?? 'Residente Desconocido';
      print('👤 Nombre del residente obtenido: $nombreResidente');
      print('🏠 Datos del residente: ${residente?.toMap()}');
  
      final reclamoData = {
        'id': reclamoId,
        'fechaRegistro': now.toIso8601String(),
        'tipoReclamo': tipoReclamo,
        'contenido': contenido,
        'residenteId': residenteId, // ✅ Campo directo para consultas eficientes
        'estado': {
          'resuelto': false,
          'fechaResolucion': null,
          'mensajeRespuesta': null,
          'resolvidoPor': null,
        },
        'isRead': [],
        // Mantener additionalData para compatibilidad
        'additionalData': {
          'residenteId': residenteId,
          'nombreResidente': nombreResidente,
          'fechaCreacion': now.toIso8601String(),
          'version': '2.0', // Para identificar nuevos documentos
        },
      };
  
      print('💾 Datos del reclamo a guardar:');
      print(reclamoData);
  
      // Guardar el reclamo en Firestore
      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('reclamos')
          .doc(reclamoId)
          .set(reclamoData);
  
      print('✅ Reclamo guardado exitosamente en Firestore');
  
      // Enviar notificación a administradores
      print('📧 Enviando notificación a administradores...');
      await _enviarNotificacionNuevoReclamo(condominioId:  condominioId,
        reclamoId: reclamoId,
        tipoReclamo: tipoReclamo, residenteId: residenteId,
        // nombreResidente,
       
      );
      
      print('✅ Proceso de creación de reclamo completado exitosamente');
      
    } catch (e, stackTrace) {
      print('❌ Error al crear reclamo: $e');
      //print('📍 Stack trace: $stackTrace');
      print('🔧 Tipo de error: ${e.runtimeType}');
      rethrow;
    }
  }

  // Obtener reclamos de un residente específico
  // Método optimizado para obtener reclamos del residente
  // ✅ MÉTODO OPTIMIZADO sin índice compuesto
  Stream<List<ReclamoModel>> obtenerReclamosResidente(
    String condominioId,
    String residenteId,
  ) {
    print('🔍 Obteniendo reclamos para residente: $residenteId en condominio: $condominioId');
    print('⏰ Timestamp de consulta: ${DateTime.now().toIso8601String()}');
    
    try {
      // ✅ SOLUCIÓN: Usar solo el campo directo residenteId (sin orderBy)
      return _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('reclamos')
          .where('residenteId', isEqualTo: residenteId)
          .snapshots()
          .map((snapshot) {
            print('📊 Documentos obtenidos: ${snapshot.docs.length}');
            print('🔄 Metadata - isFromCache: ${snapshot.metadata.isFromCache}');
            print('🔄 Metadata - hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');
            
            final reclamos = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    print('📄 Procesando documento: ${doc.id}');
                    print('📋 Datos del documento: $data');
                    return ReclamoModel.fromMap(data);
                  } catch (e) {
                    print('❌ Error al procesar documento ${doc.id}: $e');
                    return null;
                  }
                })
                .where((reclamo) => reclamo != null)
                .cast<ReclamoModel>()
                .toList();
            
            // ✅ Ordenar en memoria por fecha (más reciente primero)
            reclamos.sort((a, b) {
              try {
                final dateA = DateTime.parse(a.fechaRegistro);
                final dateB = DateTime.parse(b.fechaRegistro);
                return dateB.compareTo(dateA);
              } catch (e) {
                print('❌ Error al ordenar reclamos: $e');
                return 0;
              }
            });
            
            print('✅ Reclamos procesados y ordenados: ${reclamos.length}');
            
            // Debug: Mostrar estado de cada reclamo
            for (final reclamo in reclamos) {
              print('🔍 Reclamo ${reclamo.id}: resuelto=${reclamo.isResuelto}, estado=${reclamo.estado}');
            }
            
            return reclamos;
          })
          .handleError((error) {
            print('❌ Error en stream de reclamos: $error');
            if (error.toString().contains('index')) {
              print('💡 SOLUCIÓN: Crear índice en Firebase Console o cambiar consulta');
              print('🔗 URL sugerida en el error para crear índice');
            }
            //print('📍 Stack trace completo: ${StackTrace.current}');
            print('🔧 Tipo de error: ${error.runtimeType}');
            throw error;
          });
    } catch (e) {
      print('❌ Error general en obtenerReclamosResidente: $e');
      rethrow;
    }
  }

  // OPCIÓN 2: Método alternativo sin orderBy para evitar índice compuesto
  Stream<List<ReclamoModel>> obtenerReclamosResidenteAlternativo(
    String condominioId,
    String residenteId,
  ) {
    print('🔍 [ALTERNATIVO] Obteniendo reclamos para residente: $residenteId');
    
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('reclamos')
        .where('additionalData.residenteId', isEqualTo: residenteId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          print('📊 [ALT] Documentos encontrados: ${snapshot.docs.length}');
          
          final reclamos = snapshot.docs.map((doc) {
            try {
              return ReclamoModel.fromMap(doc.data());
            } catch (e) {
              print('❌ [ALT] Error al procesar documento ${doc.id}: $e');
              return null;
            }
          }).where((reclamo) => reclamo != null).cast<ReclamoModel>().toList();
          
          // Ordenar en memoria en lugar de en Firestore
          reclamos.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.fechaRegistro);
              final dateB = DateTime.parse(b.fechaRegistro);
              return dateB.compareTo(dateA); // Más reciente primero
            } catch (e) {
              print('❌ Error al ordenar reclamos: $e');
              return 0;
            }
          });
          
          print('✅ [ALT] Reclamos ordenados: ${reclamos.length}');
          return reclamos;
        });
  }

  // Obtener todos los reclamos del condominio (para administradores)
  Stream<List<ReclamoModel>> obtenerReclamosCondominio(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('reclamos')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReclamoModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Marcar reclamo como leído
  Future<void> marcarReclamoComoLeido(
    String condominioId,
    String reclamoId,
    String userId,
    String userName,
    String userType,
  ) async {
    try {
      final now = DateTime.now();
      final readData = {
        userId: {
          'userId': userId,
          'userName': userName,
          'userType': userType,
          'fechaLectura': now.toIso8601String(),
        },
      };

      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('reclamos')
          .doc(reclamoId)
          .update({
            'isRead': FieldValue.arrayUnion([readData]),
          });

      print('✅ Reclamo marcado como leído');
    } catch (e) {
      print('❌ Error al marcar reclamo como leído: $e');
      throw Exception('Error al marcar reclamo como leído: $e');
    }
  }

  // Resolver reclamo (solo administradores)
  Future<void> resolverReclamo(
    String condominioId,
    String reclamoId,
    String adminId,
    String adminName,
    String? mensajeRespuesta,
  ) async {
    try {
      final now = DateTime.now();
      final estadoData = {
        'userId': adminId,
        'userName': adminName,
        'userType': 'administrador',
        'fechaResolucion': now.toIso8601String(),
        'mensajeRespuesta': mensajeRespuesta ?? '',
        'resuelto': true,
      };

      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('reclamos')
          .doc(reclamoId)
          .update({'estado': estadoData});

      // Enviar notificación al residente sobre la resolución
      await _enviarNotificacionReclamoResuelto(
        condominioId: condominioId,
        reclamoId: reclamoId,
        mensajeRespuesta: mensajeRespuesta,
      );

      print('✅ Reclamo resuelto exitosamente');
    } catch (e) {
      print('❌ Error al resolver reclamo: $e');
      throw Exception('Error al resolver reclamo: $e');
    }
  }

  // Enviar notificación de nuevo reclamo a administradores
  Future<void> _enviarNotificacionNuevoReclamo({
    required String condominioId,
    required String reclamoId,
    required String tipoReclamo,
    required String residenteId,
  }) async {
    try {
      // Obtener datos del residente
      final residente = await _firestoreService.getResidenteData(residenteId);
      final nombreResidente = residente?.nombre ?? 'Residente';

      await _notificationService.createCondominioNotification(
        condominioId: condominioId,
        tipoNotificacion: 'nuevo_reclamo',
        contenido: 'Nuevo reclamo de $nombreResidente: $tipoReclamo',
        additionalData: {
          'reclamoId': reclamoId,
          'tipoReclamo': tipoReclamo,
          'residenteId': residenteId,
          'nombreResidente': nombreResidente,
        },
      );
    } catch (e) {
      print('❌ Error al enviar notificación de nuevo reclamo: $e');
    }
  }

  // Enviar notificación de reclamo resuelto al residente
  Future<void> _enviarNotificacionReclamoResuelto({
    required String condominioId,
    required String reclamoId,
    String? mensajeRespuesta,
  }) async {
    try {
      // Obtener el reclamo para obtener el ID del residente
      final reclamoDoc = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('reclamos')
          .doc(reclamoId)
          .get();

      if (reclamoDoc.exists) {
        final reclamo = ReclamoModel.fromMap(reclamoDoc.data()!);
        final residenteId = reclamo.additionalData?['residenteId'];

        if (residenteId != null) {
          await _notificationService.createUserNotification(
            condominioId: condominioId,
            userId: residenteId,
            userType: 'residentes',
            tipoNotificacion: 'reclamo_resuelto',
            contenido: mensajeRespuesta != null && mensajeRespuesta.isNotEmpty
                ? 'Su reclamo ha sido resuelto. Respuesta: $mensajeRespuesta'
                : 'Su reclamo ha sido resuelto.',
            additionalData: {
              'reclamoId': reclamoId,
              'mensajeRespuesta': mensajeRespuesta ?? '',
            },
          );
        }
      }
    } catch (e) {
      print('❌ Error al enviar notificación de reclamo resuelto: $e');
    }
  }

  // Obtener tipos de reclamo predefinidos
  List<String> getTiposReclamoDisponibles() {
    return ['Ruidos molestos', 'Auto mal estacionado', 'Otro'];
  }
}
