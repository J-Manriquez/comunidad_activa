import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/condominio_model.dart';
import '../models/administrador_model.dart';
import '../models/residente_model.dart';
import '../models/comite_model.dart';
import '../models/trabajador_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generar ID único para el condominio
  String generateCondominioId(String nombreCondominio) {
    // Normalizar el nombre (quitar espacios, acentos, etc.)
    String normalizedName = nombreCondominio
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    // Generar 3 dígitos aleatorios
    String randomDigits = Random().nextInt(900).toString().padLeft(3, '0');

    // Crear el ID en el formato requerido
    return '${normalizedName}_$randomDigits';
  }

  // Crear un nuevo condominio con su administrador
  Future<String> createCondominio({
    required String nombre,
    required String direccion,
    required String adminNombre,
    required String adminEmail,
  }) async {
    try {
      // Obtener el usuario actual
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      // Generar ID del condominio
      String condominioId = generateCondominioId(nombre);
      String fechaActual = DateTime.now().toIso8601String();

      // Calcular fecha fin de prueba (14 días)
      String fechaFinPrueba = DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String();

      // Crear modelo del condominio
      CondominioModel condominio = CondominioModel(
        id: condominioId,
        nombre: nombre,
        direccion: direccion,
        fechaCreacion: fechaActual,
        pruebaActiva: true,
        fechaFinPrueba: fechaFinPrueba,
      );

      // Crear modelo del administrador
      AdministradorModel administrador = AdministradorModel(
        uid: currentUser.uid,
        nombre: adminNombre,
        email: adminEmail,
        condominioId: condominioId,
        fechaRegistro: fechaActual,
      );

      // Iniciar transacción para guardar todo
      await _firestore.runTransaction((transaction) async {
        // Registrar el ID del condominio en la colección 'condominios'
        transaction.set(
          _firestore.collection('condominios').doc(condominioId),
          {'nombre': nombre, 'created': fechaActual},
        );

        // Crear documento del condominio
        transaction.set(
          _firestore.collection(condominioId).doc('condominio'),
          condominio.toMap(),
        );

        // Crear documento del administrador
        transaction.set(
          _firestore.collection(condominioId).doc('administrador'),
          administrador.toMap(),
        );

        // Crear documento de usuarios con subcolecciones
        transaction.set(_firestore.collection(condominioId).doc('usuarios'), {
          'created': fechaActual,
        });

        // Crear documentos placeholder para las subcolecciones
        transaction.set(
          _firestore
              .collection(condominioId)
              .doc('usuarios')
              .collection('residentes')
              .doc('_placeholder'),
          {'created': fechaActual},
        );

        transaction.set(
          _firestore
              .collection(condominioId)
              .doc('usuarios')
              .collection('comite')
              .doc('_placeholder'),
          {'created': fechaActual},
        );

        transaction.set(
          _firestore
              .collection(condominioId)
              .doc('usuarios')
              .collection('trabajadores')
              .doc('_placeholder'),
          {'created': fechaActual},
        );
      });

      return condominioId;
    } catch (e) {
      debugPrint('Error al crear condominio: $e');
      throw Exception('Error al crear condominio: $e');
    }
  }

  // Obtener todos los residentes de un condominio - VERSIÓN CORREGIDA
  Future<List<ResidenteModel>> obtenerResidentesCondominio(
    String condominioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != '_placeholder') // Filtrar placeholder
          .map((doc) {
            try {
              return ResidenteModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error al procesar residente ${doc.id}: $e');
              print('Datos del documento: ${doc.data()}');
              return null;
            }
          })
          .where((residente) => residente != null)
          .cast<ResidenteModel>()
          .toList();
    } catch (e) {
      debugPrint('Error al obtener residentes del condominio: $e');
      throw Exception('Error al obtener residentes del condominio: $e');
    }
  }

  // Registrar un residente
  Future<void> registerResidente({
    required String nombre,
    required String email,
    required String codigo,
    required bool esComite,
  }) async {
    try {
      // Verificar que el código (condominioId) exista
      DocumentSnapshot condominioDoc = await _firestore
          .collection(codigo)
          .doc('condominio')
          .get();

      if (!condominioDoc.exists) {
        throw Exception('El código de condominio no es válido');
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      String fechaActual = DateTime.now().toIso8601String();

      // Crear modelo del residente
      ResidenteModel residente = ResidenteModel(
        uid: currentUser.uid,
        nombre: nombre,
        email: email,
        condominioId: codigo,
        codigo: codigo,
        esComite: esComite,
        fechaRegistro: fechaActual,
        permitirMsjsResidentes: true,
      );

      // Si es miembro del comité, guardar en ambas colecciones
      if (esComite) {
        ComiteModel comite = ComiteModel(
          uid: currentUser.uid,
          nombre: nombre,
          email: email,
          condominioId: codigo,
          codigo: codigo,
          esComite: true,
          fechaRegistro: fechaActual,
        );

        // Guardar en la colección de comité
        await _firestore
            .collection(codigo)
            .doc('usuarios')
            .collection('comite')
            .doc(currentUser.uid)
            .set(comite.toMap());
      }

      // Guardar en la colección de residentes
      await _firestore
          .collection(codigo)
          .doc('usuarios')
          .collection('residentes')
          .doc(currentUser.uid)
          .set(residente.toMap());
    } catch (e) {
      debugPrint('Error al registrar residente: $e');
      throw Exception('Error al registrar residente: $e');
    }
  }

  // Registrar un miembro del comité
  Future<void> registerComite({
    required String nombre,
    required String email,
    required String codigo,
  }) async {
    try {
      // Verificar que el código (condominioId) exista
      DocumentSnapshot condominioDoc = await _firestore
          .collection(codigo)
          .doc('condominio')
          .get();

      if (!condominioDoc.exists) {
        throw Exception('El código de condominio no es válido');
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      String fechaActual = DateTime.now().toIso8601String();

      // Crear modelo del miembro del comité
      ComiteModel comite = ComiteModel(
        uid: currentUser.uid,
        nombre: nombre,
        email: email,
        condominioId: codigo,
        codigo: codigo,
        esComite: true,
        fechaRegistro: fechaActual,
      );

      // Guardar en la colección de comité
      await _firestore
          .collection(codigo)
          .doc('usuarios')
          .collection('comite')
          .doc(currentUser.uid)
          .set(comite.toMap());
    } catch (e) {
      debugPrint('Error al registrar miembro del comité: $e');
      throw Exception('Error al registrar miembro del comité: $e');
    }
  }

  // Registrar un trabajador
  Future<void> registerTrabajador({
    required String nombre,
    required String email,
    required String codigo,
    required String tipoTrabajador,
    String? cargoEspecifico,
  }) async {
    try {
      // Verificar que el código (condominioId) exista
      DocumentSnapshot condominioDoc = await _firestore
          .collection(codigo)
          .doc('condominio')
          .get();

      if (!condominioDoc.exists) {
        throw Exception('El código de condominio no es válido');
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No hay usuario autenticado');

      String fechaActual = DateTime.now().toIso8601String();

      // Crear modelo del trabajador
      TrabajadorModel trabajador = TrabajadorModel(
        uid: currentUser.uid,
        nombre: nombre,
        email: email,
        condominioId: codigo,
        codigo: codigo,
        tipoTrabajador: tipoTrabajador,
        cargoEspecifico: cargoEspecifico,
        fechaRegistro: fechaActual,
      );

      // Guardar en la colección de trabajadores
      await _firestore
          .collection(codigo)
          .doc('usuarios')
          .collection('trabajadores')
          .doc(currentUser.uid)
          .set(trabajador.toMap());
    } catch (e) {
      debugPrint('Error al registrar trabajador: $e');
      throw Exception('Error al registrar trabajador: $e');
    }
  }

  // Verificar si un usuario ya está registrado en algún condominio
  Future<Map<String, dynamic>?> checkUserRegistration(String uid) async {
    try {
      // Buscar en la colección de condominios (que almacena los IDs)
      QuerySnapshot condominiosQuery = await _firestore
          .collection('condominios')
          .get();

      for (var condominioDoc in condominiosQuery.docs) {
        String condominioId = condominioDoc.id;

        // Verificar si es administrador
        DocumentSnapshot adminDoc = await _firestore
            .collection(condominioId)
            .doc('administrador')
            .get();
        if (adminDoc.exists && adminDoc.get('uid') == uid) {
          Map<String, dynamic> data = adminDoc.data() as Map<String, dynamic>;
          data['tipoUsuario'] = 'administrador';
          data['condominioId'] = condominioId;
          return data;
        }

        // Verificar si es residente
        DocumentSnapshot residenteDoc = await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection('residentes')
            .doc(uid)
            .get();

        if (residenteDoc.exists) {
          Map<String, dynamic> data =
              residenteDoc.data() as Map<String, dynamic>;
          data['tipoUsuario'] = 'residente';
          data['condominioId'] = condominioId;
          return data;
        }

        // Verificar si es del comité
        DocumentSnapshot comiteDoc = await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection('comite')
            .doc(uid)
            .get();

        if (comiteDoc.exists) {
          Map<String, dynamic> data = comiteDoc.data() as Map<String, dynamic>;
          data['tipoUsuario'] = 'residente';
          data['esComite'] = true;
          data['condominioId'] = condominioId;
          return data;
        }

        // Verificar si es trabajador
        DocumentSnapshot trabajadorDoc = await _firestore
            .collection(condominioId)
            .doc('usuarios')
            .collection('trabajadores')
            .doc(uid)
            .get();

        if (trabajadorDoc.exists) {
          Map<String, dynamic> data =
              trabajadorDoc.data() as Map<String, dynamic>;
          data['tipoUsuario'] = 'trabajador';
          data['condominioId'] = condominioId;
          return data;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error al verificar registro de usuario: $e');
      return null;
    }
  }

  // Obtener datos del condominio
  Future<CondominioModel> getCondominioData(String condominioId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      if (!doc.exists) {
        throw Exception('No se encontró información del condominio');
      }

      return CondominioModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error al obtener datos del condominio: $e');
      throw Exception('Error al obtener datos del condominio: $e');
    }
  }

  // Obtener cantidad de residentes
  Future<int> getResidentesCount(String condominioId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      // Restar 1 por el documento placeholder
      int count = query.docs.length;
      return count > 0 ? count - 1 : 0;
    } catch (e) {
      debugPrint('Error al obtener cantidad de residentes: $e');
      return 0;
    }
  }

  // Obtener cantidad de miembros del comité
  Future<int> getComiteCount(String condominioId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('comite')
          .get();

      // Restar 1 por el documento placeholder
      int count = query.docs.length;
      return count > 0 ? count - 1 : 0;
    } catch (e) {
      debugPrint('Error al obtener cantidad de miembros del comité: $e');
      return 0;
    }
  }

  // Obtener cantidad de trabajadores
  Future<int> getTrabajadoresCount(String condominioId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .get();

      // Restar 1 por el documento placeholder
      int count = query.docs.length;
      return count > 0 ? count - 1 : 0;
    } catch (e) {
      debugPrint('Error al obtener cantidad de trabajadores: $e');
      return 0;
    }
  }

  // Actualizar datos del condominio
  Future<void> updateCondominioData(CondominioModel condominio) async {
    try {
      await _firestore
          .collection(condominio.id)
          .doc('condominio')
          .update(condominio.toMap());

      // También actualizar el nombre en la colección principal de condominios
      await _firestore.collection('condominios').doc(condominio.id).update({
        'nombre': condominio.nombre,
      });
    } catch (e) {
      debugPrint('Error al actualizar datos del condominio: $e');
      throw Exception('Error al actualizar datos del condominio: $e');
    }
  }

  // Obtener datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Buscar el registro del usuario en la base de datos
      Map<String, dynamic>? userData = await checkUserRegistration(
        currentUser.uid,
      );
      if (userData == null) return null;

      // Determinar el tipo de usuario
      UserType tipoUsuario;
      switch (userData['tipoUsuario']) {
        case 'administrador':
          tipoUsuario = UserType.administrador;
          break;
        case 'trabajador':
          tipoUsuario = UserType.trabajador;
          break;
        default:
          tipoUsuario = UserType.residente;
          break;
      }

      // Crear y devolver el modelo de usuario
      return UserModel(
        uid: currentUser.uid,
        email: userData['email'] ?? currentUser.email ?? '',
        nombre: userData['nombre'] ?? '',
        tipoUsuario: tipoUsuario,
        condominioId: userData['condominioId'],
        esComite: userData['esComite'] ?? false,
      );
    } catch (e) {
      debugPrint('Error al obtener datos del usuario actual: $e');
      return null;
    }
  }

  // Obtener el condominioId del usuario actual
  Future<String?> getCondominioId() async {
    try {
      final userData = await getCurrentUserData();
      return userData?.condominioId;
    } catch (e) {
      debugPrint('Error al obtener condominioId: $e');
      return null;
    }
  }

  Future<ResidenteModel?> getResidenteData(String uid) async {
    try {
      // Primero obtener el condominioId del usuario actual
      final userData = await getCurrentUserData();
      if (userData?.condominioId == null) {
        throw Exception('No se encontró el condominio del usuario');
      }

      final doc = await _firestore
          .collection(userData!.condominioId!)
          .doc('usuarios')
          .collection('residentes')
          .doc(uid)
          .get();

      if (doc.exists) {
        return ResidenteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener datos del residente: $e');
    }
  }

  Future<void> updateResidenteData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      // Primero obtener el condominioId del usuario actual
      final userData = await getCurrentUserData();
      if (userData?.condominioId == null) {
        throw Exception('No se encontró el condominio del usuario');
      }

      await _firestore
          .collection(userData!.condominioId!)
          .doc('usuarios')
          .collection('residentes')
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Error al actualizar datos del residente: $e');
    }
  }

  // Obtener datos del administrador
  Future<AdministradorModel?> getAdministradorData(String condominioId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('administrador')
          .get();

      if (doc.exists && doc.data() != null) {
        return AdministradorModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del administrador: $e');
      return null;
    }
  }

  // Agregar este método a la clase FirestoreService
  Stream<ResidenteModel?> getResidenteStream(String uid) {
    try {
      final userData = getCurrentUserData();
      return userData
          .then((user) {
            if (user?.condominioId == null) {
              return Stream.value(null);
            }

            return FirebaseFirestore.instance
                .collection(user!.condominioId.toString())
                .doc('usuarios')
                .collection('residentes')
                .doc(uid)
                .snapshots()
                .map((doc) {
                  if (doc.exists) {
                    return ResidenteModel.fromFirestore(doc);
                  }
                  return null;
                });
          })
          .asStream()
          .asyncExpand((stream) => stream);
    } catch (e) {
      return Stream.error('Error al obtener stream del residente: $e');
    }
  }

  Future<bool> actualizarEstadoViviendaResidente(
    String condominioId,
    String residenteUid,
    String nuevoEstado,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(residenteUid)
          .update({'viviendaSeleccionada': nuevoEstado});
      return true;
    } catch (e) {
      print('Error al actualizar estado de vivienda: $e');
      return false;
    }
  }

  // Obtener residentes con vivienda seleccionada
  Future<List<Map<String, dynamic>>> obtenerResidentesConVivienda(
    String condominioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      final residentes = querySnapshot.docs
          .where((doc) => doc.id != '_placeholder') // Filtrar placeholder
          .map((doc) {
            try {
              final data = doc.data();
              final residente = ResidenteModel.fromFirestore(doc);
              
              // Solo incluir residentes que tengan vivienda seleccionada
              if (residente.descripcionVivienda != null && 
                  residente.descripcionVivienda!.isNotEmpty) {
                return {
                  'uid': residente.uid,
                  'nombre': residente.nombre,
                  'email': residente.email,
                  'vivienda': residente.descripcionVivienda,
                };
              }
              return null;
            } catch (e) {
              print('❌ Error al procesar residente ${doc.id}: $e');
              return null;
            }
          })
          .where((residente) => residente != null)
          .cast<Map<String, dynamic>>()
          .toList();

      return residentes;
    } catch (e) {
      debugPrint('Error al obtener residentes con vivienda: $e');
      throw Exception('Error al obtener residentes con vivienda: $e');
    }
  }

  // Obtener residentes por vivienda específica
  Future<List<ResidenteModel>> getResidentesPorVivienda(
    String condominioId,
    String tipoVivienda,
    String numeroVivienda,
  ) async {
    try {
      // Normalizar tipoVivienda para la búsqueda
      String tipoViviendaNormalizado = tipoVivienda.toLowerCase();
      
      Query query = _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .where('viviendaSeleccionada', isEqualTo: 'seleccionada');

      if (tipoViviendaNormalizado.contains('casa')) {
        query = query
            .where('tipoVivienda', isEqualTo: 'casa')
            .where('numeroVivienda', isEqualTo: numeroVivienda);
      } else if (tipoViviendaNormalizado.contains('depto') || tipoViviendaNormalizado.contains('edificio')) {
        // Extraer etiqueta del edificio del tipo (ej: "Depto A" -> "A")
        String etiquetaEdificio = tipoVivienda.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').replaceAll('Depto', '').replaceAll('Edificio', '').trim();
        
        query = query
            .where('tipoVivienda', isEqualTo: 'departamento')
            .where('etiquetaEdificio', isEqualTo: etiquetaEdificio)
            .where('numeroDepartamento', isEqualTo: numeroVivienda);
      }

      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .where((doc) => doc.id != '_placeholder')
          .map((doc) => ResidenteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener residentes por vivienda: $e');
      return [];
    }
  }

  //updateCobrarMultasConGastos
   Future<bool> updateCampoCondominio(
    String condominioId,
    String campo,
    bool valor,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('condominio')
          .update({campo: valor});
      return true;
    } catch (e) {
      print('Error al actualizar estado de vivienda: $e');
      return false;
    }
  }

  // Actualizar gestión de funciones del condominio
  Future<bool> updateGestionFunciones(
    String condominioId,
    Map<String, bool> gestionFunciones,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('condominio')
          .update({'gestionFunciones': gestionFunciones});
      return true;
    } catch (e) {
      print('Error al actualizar gestión de funciones: $e');
      return false;
    }
  }

  // Actualizar una función específica de la gestión
  Future<bool> updateFuncionEspecifica(
    String condominioId,
    String nombreFuncion,
    bool valor,
  ) async {
    try {
      await _firestore
          .collection(condominioId)
          .doc('condominio')
          .update({'gestionFunciones.$nombreFuncion': valor});
      return true;
    } catch (e) {
      print('Error al actualizar función específica: $e');
      return false;
    }
  }

  // Obtener residentes por descripción completa de vivienda (para notificaciones de bloqueo)
  Future<List<ResidenteModel>> getResidentesByViviendaDescripcion(
    String condominioId,
    String descripcionVivienda,
  ) async {
    try {
      print('🔍 Buscando residentes para vivienda: $descripcionVivienda');
      
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      List<ResidenteModel> residentesEncontrados = [];

      for (var doc in querySnapshot.docs) {
        if (doc.id == '_placeholder') continue;
        
        try {
          final residente = ResidenteModel.fromFirestore(doc);
          
          // Obtener la descripción de vivienda del residente
          String descripcionResidente = '';
          
          if (residente.descripcionVivienda != null && 
              residente.descripcionVivienda!.isNotEmpty) {
            descripcionResidente = residente.descripcionVivienda!;
          } else {
            // Construir descripción desde campos individuales
            if (residente.tipoVivienda?.isNotEmpty == true) {
              descripcionResidente += residente.tipoVivienda!;
            }
            
            if (residente.numeroVivienda?.isNotEmpty == true) {
              if (descripcionResidente.isNotEmpty) descripcionResidente += ' ';
              descripcionResidente += residente.numeroVivienda!;
            }
            
            if (residente.etiquetaEdificio?.isNotEmpty == true) {
              if (descripcionResidente.isNotEmpty) descripcionResidente += ', ';
              descripcionResidente += residente.etiquetaEdificio!;
            }
            
            if (residente.numeroDepartamento?.isNotEmpty == true) {
              if (descripcionResidente.isNotEmpty) descripcionResidente += ' ';
              descripcionResidente += residente.numeroDepartamento!;
            }
          }
          
          // Comparar descripciones (normalizar para comparación)
          String descripcionNormalizada = descripcionVivienda.toLowerCase().trim();
          String residenteNormalizada = descripcionResidente.toLowerCase().trim();
          
          if (residenteNormalizada == descripcionNormalizada) {
            residentesEncontrados.add(residente);
            print('✅ Residente encontrado: ${residente.nombre} - ${descripcionResidente}');
          }
        } catch (e) {
          print('❌ Error al procesar residente ${doc.id}: $e');
        }
      }
      
      print('📊 Total de residentes encontrados: ${residentesEncontrados.length}');
      return residentesEncontrados;
    } catch (e) {
      print('❌ Error al obtener residentes por descripción de vivienda: $e');
      return [];
    }
  }

  // Obtener datos del trabajador
  Future<TrabajadorModel?> getTrabajadorData(String condominioId, String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return TrabajadorModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del trabajador: $e');
      return null;
    }
  }

  // Obtener datos del comité
  Future<ComiteModel?> getComiteData(String condominioId, String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('comite')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return ComiteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del comité: $e');
      return null;
    }
  }

  // Obtener todos los trabajadores de un condominio
  Future<List<TrabajadorModel>> obtenerTrabajadoresCondominio(
    String condominioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('trabajadores')
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != '_placeholder') // Filtrar placeholder
          .map((doc) {
            try {
              return TrabajadorModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error al procesar trabajador ${doc.id}: $e');
              print('Datos del documento: ${doc.data()}');
              return null;
            }
          })
          .where((trabajador) => trabajador != null)
          .cast<TrabajadorModel>()
          .toList();
    } catch (e) {
      debugPrint('Error al obtener trabajadores del condominio: $e');
      throw Exception('Error al obtener trabajadores del condominio: $e');
    }
  }

  // Obtener todos los miembros del comité de un condominio
  Future<List<ComiteModel>> obtenerMiembrosComite(
    String condominioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('comite')
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != '_placeholder') // Filtrar placeholder
          .map((doc) {
            try {
              return ComiteModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error al procesar miembro del comité ${doc.id}: $e');
              print('Datos del documento: ${doc.data()}');
              return null;
            }
          })
          .where((comite) => comite != null)
          .cast<ComiteModel>()
          .toList();
    } catch (e) {
      debugPrint('Error al obtener miembros del comité: $e');
      throw Exception('Error al obtener miembros del comité: $e');
    }
  }

}