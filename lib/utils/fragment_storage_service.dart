import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:comunidad_activa/utils/storage_service.dart';

/// Servicio para manejar fragmentos externos en Firestore
class FragmentStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _fragmentsCollection = 'image_fragments';
  
  /// Almacena fragmentos externos en Firestore
  static Future<void> almacenarFragmentosExternos(
    Map<String, dynamic> imageData,
    Function(double)? onProgress,
  ) async {
    if (imageData['type'] != 'external_fragmented') {
      throw Exception('Solo se pueden almacenar imágenes fragmentadas externamente');
    }
    
    final fragmentId = imageData['fragment_id'] as String;
    final fragments = List<String>.from(imageData['fragments']);
    final totalFragments = fragments.length;
    final originalType = imageData['original_type'] as String;
    
    try {
      // Crear documento principal con metadatos
      await _firestore.collection(_fragmentsCollection).doc(fragmentId).set({
        'fragment_id': fragmentId,
        'total_fragments': totalFragments,
        'original_type': originalType,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'uploading',
      });
      
      // Almacenar cada fragmento
      for (int i = 0; i < fragments.length; i++) {
        await _firestore.collection(_fragmentsCollection).doc('${fragmentId}_$i').set({
          'fragment_id': fragmentId,
          'fragment_index': i,
          'fragment': fragments[i],
          'created_at': FieldValue.serverTimestamp(),
        });
        
        // Reportar progreso
        onProgress?.call((i + 1) / fragments.length);
      }
      
      // Marcar como completado
      await _firestore.collection(_fragmentsCollection).doc(fragmentId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      // En caso de error, marcar como fallido
      try {
        await _firestore.collection(_fragmentsCollection).doc(fragmentId).update({
          'status': 'failed',
          'error': e.toString(),
          'failed_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      
      throw Exception('Error al almacenar fragmentos: $e');
    }
  }
  
  /// Recupera fragmentos externos desde Firestore
  static Future<String> recuperarFragmentosExternos(
    String fragmentId,
    int totalFragments,
    String originalType,
  ) async {
    try {
      // Verificar estado del documento principal
      final mainDoc = await _firestore.collection(_fragmentsCollection).doc(fragmentId).get();
      
      if (!mainDoc.exists) {
        throw Exception('Fragmentos no encontrados');
      }
      
      final mainData = mainDoc.data()!;
      final status = mainData['status'] as String?;
      
      if (status != 'completed') {
        throw Exception('Los fragmentos no están completamente cargados. Estado: $status');
      }
      
      // Recuperar todos los fragmentos
      final fragments = <String>[];
      
      for (int i = 0; i < totalFragments; i++) {
        final fragmentDoc = await _firestore
            .collection(_fragmentsCollection)
            .doc('${fragmentId}_$i')
            .get();
        
        if (!fragmentDoc.exists) {
          throw Exception('Fragmento $i no encontrado');
        }
        
        final fragmentData = fragmentDoc.data()!;
        fragments.add(fragmentData['fragment'] as String);
      }
      
      // Reconstruir la imagen
      return StorageService.reconstruirImagenBase64(fragments, originalType);
      
    } catch (e) {
      throw Exception('Error al recuperar fragmentos: $e');
    }
  }
  
  /// Elimina fragmentos externos de Firestore
  static Future<void> eliminarFragmentosExternos(String fragmentId, int totalFragments) async {
    try {
      // Eliminar documento principal
      await _firestore.collection(_fragmentsCollection).doc(fragmentId).delete();
      
      // Eliminar todos los fragmentos
      final batch = _firestore.batch();
      
      for (int i = 0; i < totalFragments; i++) {
        final fragmentRef = _firestore.collection(_fragmentsCollection).doc('${fragmentId}_$i');
        batch.delete(fragmentRef);
      }
      
      await batch.commit();
      
    } catch (e) {
      throw Exception('Error al eliminar fragmentos: $e');
    }
  }
  
  /// Verifica si los fragmentos externos existen
  static Future<bool> existenFragmentosExternos(String fragmentId) async {
    try {
      final doc = await _firestore.collection(_fragmentsCollection).doc(fragmentId).get();
      return doc.exists && (doc.data()?['status'] == 'completed');
    } catch (e) {
      return false;
    }
  }
  
  /// Obtiene información de fragmentos externos
  static Future<Map<String, dynamic>?> obtenerInfoFragmentos(String fragmentId) async {
    try {
      final doc = await _firestore.collection(_fragmentsCollection).doc(fragmentId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return doc.data();
    } catch (e) {
      return null;
    }
  }
  
  /// Limpia fragmentos antiguos (más de 30 días)
  static Future<void> limpiarFragmentosAntiguos() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final query = await _firestore
          .collection(_fragmentsCollection)
          .where('created_at', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        final data = doc.data();
        final fragmentId = data['fragment_id'] as String?;
        final totalFragments = data['total_fragments'] as int? ?? 0;
        
        if (fragmentId != null) {
          // Eliminar documento principal
          batch.delete(doc.reference);
          
          // Eliminar fragmentos asociados
          for (int i = 0; i < totalFragments; i++) {
            final fragmentRef = _firestore.collection(_fragmentsCollection).doc('${fragmentId}_$i');
            batch.delete(fragmentRef);
          }
        }
      }
      
      await batch.commit();
      
    } catch (e) {
      print('Error al limpiar fragmentos antiguos: $e');
    }
  }
  
  /// Obtiene estadísticas de uso de fragmentos
  static Future<Map<String, int>> obtenerEstadisticasFragmentos() async {
    try {
      final query = await _firestore.collection(_fragmentsCollection).get();
      
      int completed = 0;
      int uploading = 0;
      int failed = 0;
      int total = 0;
      
      for (final doc in query.docs) {
        final data = doc.data();
        
        // Solo contar documentos principales (no fragmentos individuales)
        if (!doc.id.contains('_')) {
          total++;
          final status = data['status'] as String?;
          
          switch (status) {
            case 'completed':
              completed++;
              break;
            case 'uploading':
              uploading++;
              break;
            case 'failed':
              failed++;
              break;
          }
        }
      }
      
      return {
        'total': total,
        'completed': completed,
        'uploading': uploading,
        'failed': failed,
      };
      
    } catch (e) {
      return {
        'total': 0,
        'completed': 0,
        'uploading': 0,
        'failed': 0,
      };
    }
  }
}