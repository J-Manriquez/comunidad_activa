import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/codigo_registro_model.dart';

class CodigoRegistroService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los códigos de un condominio
  Stream<List<CodigoRegistroModel>> obtenerCodigosCondominio(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('codigosRegistro')
        .collection('codigosCreados')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CodigoRegistroModel.fromFirestore(doc))
            .toList());
  }

  // Crear un nuevo código de registro
  Future<bool> crearCodigoRegistro({
    required String condominioId,
    required String codigo,
    required String tipoUsuario,
    required String cantUsuarios,
  }) async {
    try {
      // Validar que el código no exista globalmente
      bool codigoExiste = await _validarCodigoGlobal(codigo);
      if (codigoExiste) {
        throw Exception('El código ya existe en otro condominio');
      }

      String id = _firestore.collection('temp').doc().id;
      String fechaActual = DateTime.now().toIso8601String();

      CodigoRegistroModel nuevoCodigo = CodigoRegistroModel(
        id: id,
        codigo: codigo,
        tipoUsuario: tipoUsuario,
        cantUsuarios: cantUsuarios,
        fechaIngreso: fechaActual,
        estado: 'activo',
        usuariosRegistrados: [],
      );

      // Guardar en la colección del condominio
      await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(id)
          .set(nuevoCodigo.toMap());

      // Guardar en la colección global de códigos
      await _guardarCodigoGlobal(id, codigo, condominioId, fechaActual);

      return true;
    } catch (e) {
      print('Error al crear código de registro: $e');
      return false;
    }
  }

  // Actualizar un código de registro existente
  Future<bool> actualizarCodigoRegistro({
    required String condominioId,
    required String codigoId,
    required String codigo,
    required String tipoUsuario,
    required String cantUsuarios,
  }) async {
    try {
      // Obtener el código actual para verificar si cambió
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(codigoId)
          .get();

      if (!doc.exists) {
        throw Exception('El código no existe');
      }

      CodigoRegistroModel codigoActual = CodigoRegistroModel.fromFirestore(doc);

      // Si el código cambió, validar que no exista globalmente
      if (codigoActual.codigo != codigo) {
        bool codigoExiste = await _validarCodigoGlobal(codigo);
        if (codigoExiste) {
          throw Exception('El código ya existe en otro condominio');
        }

        // Eliminar el código anterior de la colección global
        await _eliminarCodigoGlobal(codigoActual.codigo);
        
        // Guardar el nuevo código en la colección global
        await _guardarCodigoGlobal(codigoId, codigo, condominioId, DateTime.now().toIso8601String());
      }

      // Actualizar el código en la colección del condominio
      CodigoRegistroModel codigoActualizado = codigoActual.copyWith(
        codigo: codigo,
        tipoUsuario: tipoUsuario,
        cantUsuarios: cantUsuarios,
      );

      await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(codigoId)
          .update(codigoActualizado.toMap());

      return true;
    } catch (e) {
      print('Error al actualizar código de registro: $e');
      return false;
    }
  }

  // Cambiar estado de un código (activar/desactivar)
  Future<bool> cambiarEstadoCodigo({
    required String condominioId,
    required String codigoId,
    required String nuevoEstado,
  }) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(codigoId)
          .update({'estado': nuevoEstado});

      return true;
    } catch (e) {
      print('Error al cambiar estado del código: $e');
      return false;
    }
  }

  // Eliminar un código de registro
  Future<bool> eliminarCodigoRegistro({
    required String condominioId,
    required String codigoId,
  }) async {
    try {
      // Obtener el código para eliminar de la colección global
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(codigoId)
          .get();

      if (doc.exists) {
        CodigoRegistroModel codigo = CodigoRegistroModel.fromFirestore(doc);
        
        // Eliminar de la colección global
        await _eliminarCodigoGlobal(codigo.codigo);
        
        // Eliminar de la colección del condominio
        await _firestore
            .collection(condominioId)
            .doc('codigosRegistro')
            .collection('codigosCreados')
            .doc(codigoId)
            .delete();
      }

      return true;
    } catch (e) {
      print('Error al eliminar código de registro: $e');
      return false;
    }
  }

  // Generar código aleatorio
  Future<String> generarCodigoAleatorio() async {
    String codigo;
    bool codigoValido = false;
    int intentos = 0;
    const int maxIntentos = 100;

    do {
      codigo = _generarCodigoFormato();
      codigoValido = !(await _validarCodigoGlobal(codigo));
      intentos++;
    } while (!codigoValido && intentos < maxIntentos);

    if (!codigoValido) {
      throw Exception('No se pudo generar un código único después de $maxIntentos intentos');
    }

    return codigo;
  }

  // Validar código para registro de usuario
  Future<CodigoRegistroModel?> validarCodigoParaRegistro({
    required String codigo,
    required String condominioId,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .where('codigo', isEqualTo: codigo)
          .where('estado', isEqualTo: 'activo')
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      CodigoRegistroModel codigoModel = CodigoRegistroModel.fromFirestore(query.docs.first);
      
      // Verificar si el código no está lleno
      if (codigoModel.isLleno) {
        return null;
      }

      return codigoModel;
    } catch (e) {
      print('Error al validar código para registro: $e');
      return null;
    }
  }

  // Registrar usuario con código
  Future<bool> registrarUsuarioConCodigo({
    required String condominioId,
    required String codigoId,
    required String usuarioId,
    required String nombreUsuario,
    required String uidUsuario,
  }) async {
    try {
      DocumentReference codigoRef = _firestore
          .collection(condominioId)
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .doc(codigoId);

      DocumentSnapshot doc = await codigoRef.get();
      if (!doc.exists) {
        return false;
      }

      CodigoRegistroModel codigo = CodigoRegistroModel.fromFirestore(doc);
      
      // Verificar que no esté lleno
      if (codigo.isLleno) {
        return false;
      }

      // Crear nuevo usuario registrado
      UsuarioRegistrado nuevoUsuario = UsuarioRegistrado(
        id: usuarioId,
        nombre: nombreUsuario,
        uidUsuario: uidUsuario,
        fecha: DateTime.now().toIso8601String(),
      );

      // Agregar usuario a la lista
      List<UsuarioRegistrado> usuariosActualizados = List.from(codigo.usuariosRegistrados);
      usuariosActualizados.add(nuevoUsuario);

      // Actualizar el documento
      await codigoRef.update({
        'usuariosRegistrados': usuariosActualizados.map((u) => u.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Error al registrar usuario con código: $e');
      return false;
    }
  }

  // Validar código global y obtener información del condominio
  Future<Map<String, String>?> validarCodigoGlobalConCondominio(String codigo) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('codigos')
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .where('codigo', isEqualTo: codigo)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      CodigoGlobalModel codigoGlobal = CodigoGlobalModel.fromFirestore(query.docs.first);
      
      // Ahora validar que el código esté activo en el condominio específico
      CodigoRegistroModel? codigoLocal = await validarCodigoParaRegistro(
        codigo: codigo,
        condominioId: codigoGlobal.idCondominio,
      );

      if (codigoLocal == null) {
        return null;
      }

      return {
        'condominioId': codigoGlobal.idCondominio,
        'codigoId': codigoLocal.id,
        'tipoUsuario': codigoLocal.tipoUsuario,
      };
    } catch (e) {
      print('Error al validar código global con condominio: $e');
      return null;
    }
  }

  // Métodos privados

  // Validar si un código existe globalmente
  Future<bool> _validarCodigoGlobal(String codigo) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('codigos')
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .where('codigo', isEqualTo: codigo)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error al validar código global: $e');
      return true; // En caso de error, asumir que existe para evitar duplicados
    }
  }

  // Guardar código en la colección global
  Future<void> _guardarCodigoGlobal(String id, String codigo, String condominioId, String fecha) async {
    CodigoGlobalModel codigoGlobal = CodigoGlobalModel(
      id: id,
      codigo: codigo,
      idCondominio: condominioId,
      fecha: fecha,
    );

    await _firestore
        .collection('codigos')
        .doc('codigosRegistro')
        .collection('codigosCreados')
        .doc(id)
        .set(codigoGlobal.toMap());
  }

  // Eliminar código de la colección global
  Future<void> _eliminarCodigoGlobal(String codigo) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('codigos')
          .doc('codigosRegistro')
          .collection('codigosCreados')
          .where('codigo', isEqualTo: codigo)
          .get();

      for (DocumentSnapshot doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error al eliminar código global: $e');
    }
  }

  // Generar código con formato específico
  String _generarCodigoFormato() {
    Random random = Random();
    
    // Generar 4 números aleatorios
    String numeros = '';
    for (int i = 0; i < 4; i++) {
      numeros += random.nextInt(10).toString();
    }
    
    // Lista de símbolos permitidos
    List<String> simbolos = ['!', '@', '#', '\$', '%', '&', '*', '+', '-', '=', '?'];
    
    // Generar 2 símbolos aleatorios
    String simbolosGenerados = '';
    for (int i = 0; i < 2; i++) {
      simbolosGenerados += simbolos[random.nextInt(simbolos.length)];
    }
    
    // Mezclar números y símbolos aleatoriamente
    List<String> caracteres = (numeros + simbolosGenerados).split('');
    caracteres.shuffle(random);
    
    return 'cod-registro-${caracteres.join('')}';
  }
}