import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/residente_bloqueado_model.dart';
import '../models/residente_model.dart';

class BloqueoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verificar si un correo está bloqueado
  Future<ResidenteBloqueadoModel?> verificarCorreoBloqueado(
      String condominioId, String correo) async {
    try {
      print('🔍 Verificando si el correo $correo está bloqueado en $condominioId');
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('usuarios_bloqueados')
          .where('correo', isEqualTo: correo)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('🚫 Usuario bloqueado encontrado');
        return ResidenteBloqueadoModel.fromFirestore(querySnapshot.docs.first);
      }
      print('✅ Usuario no está bloqueado');
      return null;
    } catch (e) {
      print('❌ Error al verificar correo bloqueado: $e');
      return null;
    }
  }

  // Bloquear residente
  Future<bool> bloquearResidente(
      {required String condominioId, required ResidenteModel residente, required String motivo, }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Crear documento de residente bloqueado
      final bloqueadoId = _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('usuarios_bloqueados')
          .doc()
          .id;
      
      final residenteBloqueado = ResidenteBloqueadoModel(
        id: bloqueadoId,
        nombre: residente.nombre,
        correo: residente.email,
        motivo: motivo,
        fechaHora: DateTime.now(),
      );
      
      // Agregar a usuarios bloqueados
      final bloqueadoRef = _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('usuarios_bloqueados')
          .doc(bloqueadoId);
      
      batch.set(bloqueadoRef, residenteBloqueado.toMap());
      print('✅ Documento de usuario bloqueado preparado');
      
      // 2. Eliminar documento del residente
      final residenteRef = _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residente.uid);
      
      batch.delete(residenteRef);
      print('✅ Eliminación de documento residente preparada');
      
      // 3. Eliminar subcolección de notificaciones del residente
      print('🗑️  Preparando eliminación de notificaciones para el residente: $residente.uid');
      final notificacionesSnapshot = await _firestore
          .collection(condominioId) // Colección principal de condominios
          .doc('usuarios')       // Documento específico del condominio
          .collection('residentes')  // Subcolección de residentes dentro del condominio
          .doc(residente.uid)        // Documento específico del residente
          .collection('notificaciones') // Subcolección de notificaciones del residente
          .get();
      
      if (notificacionesSnapshot.docs.isNotEmpty) {
        print('📄 Encontradas ${notificacionesSnapshot.docs.length} notificaciones para eliminar.');
        for (var doc in notificacionesSnapshot.docs) {
          batch.delete(doc.reference);
          print('🔥 Notificación ${doc.id} marcada para eliminación.');
        }
      } else {
        print('ℹ️ No se encontraron notificaciones para eliminar para el residente $residente.uid.');
      }
      print('✅ Eliminación de ${notificacionesSnapshot.docs.length} notificaciones preparada');
      
      // 4. Ejecutar todas las operaciones en Firestore
      await batch.commit();
      print('✅ Operaciones de Firestore completadas');
      
      // 5. Intentar eliminar de Firebase Authentication
      try {
        // Nota: Para eliminar un usuario de Firebase Auth desde el backend,
        // necesitarías usar Firebase Admin SDK. Como estamos en el cliente,
        // solo podemos eliminar el usuario actual.
        // En un entorno de producción, esto debería hacerse desde el backend.
        
        print('⚠️ Eliminación de Firebase Auth debe hacerse desde el backend');
        print('📧 Se recomienda enviar notificación al administrador del sistema');
        
        // Aquí podrías enviar una notificación al super administrador
        // para que elimine manualmente la cuenta de Firebase Auth
        
      } catch (authError) {
        print('⚠️ No se pudo eliminar de Firebase Auth: $authError');
        // No fallar el proceso completo por esto
      }
      
      print('✅ Proceso de bloqueo completado exitosamente');
      return true;
      
    } catch (e) {
      print('❌ Error en el proceso de bloqueo: $e');
      return false;
    }
  }

  // Obtener lista de usuarios bloqueados
  Stream<List<ResidenteBloqueadoModel>> getUsuariosBloqueados(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('usuarios')
        .collection('usuarios_bloqueados')
        .orderBy('fecha-hora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResidenteBloqueadoModel.fromFirestore(doc))
            .toList());
  }
  
  // Desbloquear usuario (opcional)
  Future<bool> desbloquearUsuario(String condominioId, String bloqueadoId) async {
    try {
      await _firestore
          .collection('condominios')
          .doc(condominioId)
          .collection('usuarios_bloqueados')
          .doc(bloqueadoId)
          .delete();
      
      print('✅ Usuario desbloqueado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al desbloquear usuario: $e');
      return false;
    }
  }
}