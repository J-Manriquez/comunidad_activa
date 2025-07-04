import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/multa_model.dart';
import '../models/condominio_model.dart';
import '../models/residente_model.dart';
import 'notification_service.dart';

class MultaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Función para obtener residentes por vivienda
  Future<List<String>> obtenerResidentesPorVivienda({
    required String condominioId,
    required String tipoVivienda,
    required String numeroVivienda,
    String? etiquetaEdificio,
    String? numeroDepartamento,
  }) async {
    // Normalizar tipoVivienda a minúsculas para consistencia con la base de datos
    String tipoViviendaNormalizado = tipoVivienda.toLowerCase();
    
    print('🔍 Búsqueda de residentes por vivienda:');
    print('   - Tipo vivienda original: $tipoVivienda');
    print('   - Tipo vivienda normalizado: $tipoViviendaNormalizado');
    print('   - Número vivienda: $numeroVivienda');
    print('   - Etiqueta edificio: $etiquetaEdificio');
    print('   - Número departamento: $numeroDepartamento');
    try {
      Query query = _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .where('tipoVivienda', isEqualTo: tipoViviendaNormalizado)
          .where('viviendaSeleccionada', isEqualTo: 'seleccionada');

      if (tipoViviendaNormalizado == 'casa') {
        query = query.where('numeroVivienda', isEqualTo: numeroVivienda);
      } else if (tipoViviendaNormalizado == 'departamento') {
        query = query
            .where('etiquetaEdificio', isEqualTo: etiquetaEdificio)
            .where('numeroDepartamento', isEqualTo: numeroDepartamento);
      }

      QuerySnapshot snapshot = await query.get();
      print('🔍 Resultado de búsqueda:');
      print('   - Residentes encontrados: ${snapshot.docs.length}');
      
      List<String> ids = snapshot.docs.map((doc) => doc.id).toList();
      print('   - IDs de residentes: $ids');
      
      return ids;
    } catch (e) {
      print('❌ Error al obtener residentes por vivienda: $e');
      return [];
    }
  }

  // Crear una nueva multa (modificado)
  Future<void> crearMulta({
    required String condominioId,
    required String tipoMulta,
    required String contenido,
    required String tipoVivienda,
    required String numeroVivienda,
    String? etiquetaEdificio,
    String? numeroDepartamento,
    required int valor,
    required String unidadMedida,
  }) async {
    try {
      String multaId = DateTime.now().millisecondsSinceEpoch.toString();
      String fechaActual = DateTime.now().toIso8601String();

      // Obtener los IDs de los residentes de la vivienda
      List<String> residentesIds = await obtenerResidentesPorVivienda(
        condominioId: condominioId,
        tipoVivienda: tipoVivienda,
        numeroVivienda: numeroVivienda,
        etiquetaEdificio: etiquetaEdificio,
        numeroDepartamento: numeroDepartamento,
      );

      Map<String, dynamic> additionalData = {
        'valor': valor,
        'unidadMedida': unidadMedida,
        'tipoVivienda': tipoVivienda,
        'numeroVivienda': numeroVivienda,
        'residentesIds': residentesIds, // Nuevo campo
      };

      if (etiquetaEdificio != null) {
        additionalData['etiquetaEdificio'] = etiquetaEdificio;
      }
      if (numeroDepartamento != null) {
        additionalData['numeroDepartamento'] = numeroDepartamento;
      }

      MultaModel multa = MultaModel(
        id: multaId,
        fechaRegistro: fechaActual,
        tipoMulta: tipoMulta,
        contenido: contenido,
        isRead: {},
        estado: 'pendiente',
        additionalData: additionalData,
      );

      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('multas')
          .doc(multaId)
          .set(multa.toMap());


      // Enviar notificaciones a todos los residentes de la vivienda
      await _enviarNotificacionesMulta(
        condominioId: condominioId,
        residentesIds: residentesIds,
        tipoMulta: tipoMulta,
        contenido: contenido,
        valor: valor,
        unidadMedida: unidadMedida,
        fechaCreacion: fechaActual, 
        multaId: multaId,
      );

      print('Multa creada exitosamente');
    } catch (e) {
      print('Error al crear multa: $e');
      throw e;
    }
  }

  // Método privado para enviar notificaciones
  Future<void> _enviarNotificacionesMulta({
    required String condominioId,
    required List<String> residentesIds,
    required String tipoMulta,
    required String contenido,
    required int valor,
    required String unidadMedida,
    required String fechaCreacion,
    required String multaId, // Agregar este parámetro
  }) async {
    try {
      final DateTime fechaHora = DateTime.parse(fechaCreacion);
      final String fechaFormateada = '${fechaHora.day.toString().padLeft(2, '0')}/${fechaHora.month.toString().padLeft(2, '0')}/${fechaHora.year}';
      final String horaFormateada = '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';
  
      final String mensajeNotificacion = 'Se le ha asignado una multa: $contenido. Tipo: $tipoMulta. Valor: $valor $unidadMedida. Fecha: $fechaFormateada a las $horaFormateada.';
  
      for (String residenteId in residentesIds) {
        await _notificationService.createUserNotification(
          condominioId: condominioId,
          userId: residenteId,
          userType: 'residentes',
          tipoNotificacion: 'multa',
          contenido: mensajeNotificacion,
          additionalData: {
            'tipoMulta': tipoMulta,
            'valor': valor,
            'unidadMedida': unidadMedida,
            'fechaCreacion': fechaCreacion,
            'multaId': multaId, // Agregar el ID de la multa
          },
        );
      }
    } catch (e) {
      print('Error al enviar notificaciones de multa: $e');
    }
  }

  // Obtener multas del condominio (para administrador)
  Stream<List<MultaModel>> obtenerMultasCondominio(String condominioId) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('multas')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != '_placeholder')
          .map((doc) => MultaModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Obtener multas de un residente específico (modificado)
  Stream<List<MultaModel>> obtenerMultasResidente(String condominioId, String uid) {
    return _firestore
        .collection(condominioId)
        .doc('comunicaciones')
        .collection('multas')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MultaModel.fromMap(doc.data()))
          .where((multa) {
            // Verificar que additionalData y residentesIds no sean null
            if (multa.additionalData == null || multa.additionalData!['residentesIds'] == null) {
              return false;
            }
            try {
              List<String> residentesIds = List<String>.from(multa.additionalData!['residentesIds']);
              return residentesIds.contains(uid);
            } catch (e) {
              print('Error al procesar residentesIds para multa ${multa.id}: $e');
              return false;
            }
          })
          .toList();
    });
  }

  // Marcar multa como leída (modificado)
  Future<void> marcarMultaComoLeida(String condominioId, String multaId, String uid) async {
    try {
      // prints
      print('🔔 Marcar multa como leída:');
      print('   - Condominio ID: $condominioId');
      print('   - Multa ID: $multaId');
      print('   - Usuario ID: $uid');
      // Obtener datos del usuario
      DocumentSnapshot userDoc = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String nombreUsuario = userData['nombre'] ?? 'Usuario';
      String fechaHoraLectura = DateTime.now().toIso8601String();

      // Actualizar el campo isRead con la información del usuario
      await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('multas')
          .doc(multaId)
          .update({
        'isRead.$uid': {
          'id': uid,
          'nombre': nombreUsuario,
          'fechaHora': fechaHoraLectura,
        }
      });
      print('Multa marcada como leída por $uid');
    } catch (e) {
      print('Error al marcar multa como leída: $e');
      throw e;
    }
  }

  // Agregar tipo de multa a la gestión del condominio
  Future<void> agregarTipoMulta({
    required String condominioId,
    required String tipoMulta,
    required int valor,
    required String unidadMedida,
  }) async {
    try {
      String gestionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      GestionMulta nuevaGestion = GestionMulta(
        id: gestionId,
        tipoMulta: tipoMulta,
        valor: valor,
        unidadMedida: unidadMedida,
      );

      await _firestore
          .collection(condominioId)
          .doc('condominio')
          .update({
        'gestionMultas': FieldValue.arrayUnion([nuevaGestion.toMap()])
      });

      print('Tipo de multa agregado exitosamente');
    } catch (e) {
      print('Error al agregar tipo de multa: $e');
      throw e;
    }
  }

  // Obtener tipos de multas del condominio
  Future<List<GestionMulta>> obtenerTiposMultas(String condominioId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['gestionMultas'] != null) {
          return (data['gestionMultas'] as List)
              .map((e) => GestionMulta.fromMap(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener tipos de multas: $e');
      return [];
    }
  }

  // Eliminar tipo de multa
  Future<void> eliminarTipoMulta(String condominioId, String gestionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> gestionMultas = data['gestionMultas'] ?? [];
        
        gestionMultas.removeWhere((item) => item['id'] == gestionId);
        
        await _firestore
            .collection(condominioId)
            .doc('condominio')
            .update({'gestionMultas': gestionMultas});
      }
    } catch (e) {
      print('Error al eliminar tipo de multa: $e');
      throw e;
    }
  }

  // Obtener multas de una vivienda específica
  Future<List<MultaModel>> obtenerMultasVivienda({
    required String condominioId,
    required String tipoVivienda,
    required String numeroVivienda,
    String? etiquetaEdificio,
    String? numeroDepartamento,
  }) async {
    try {
      print('🔍 Buscando multas para vivienda:');
      print('   - Condominio: $condominioId');
      print('   - Tipo: $tipoVivienda');
      print('   - Número: $numeroVivienda');
      print('   - Etiqueta edificio: $etiquetaEdificio');
      print('   - Número departamento: $numeroDepartamento');
      // print('   - Stack trace: ${StackTrace.current}');
      
      QuerySnapshot snapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('multas')
          .get();

      print('📋 Total de multas en el condominio: ${snapshot.docs.length}');
      
      List<MultaModel> multasVivienda = [];
      
      for (var doc in snapshot.docs) {
        MultaModel multa = MultaModel.fromMap(doc.data() as Map<String, dynamic>);
        print('🧾 Evaluando multa: ${multa.id}');
        
        if (multa.additionalData != null) {
          String? multaTipoVivienda = multa.additionalData!['tipoVivienda'];
          String? multaNumeroVivienda = multa.additionalData!['numeroVivienda'];
          String? multaEtiquetaEdificio = multa.additionalData!['etiquetaEdificio'];
          String? multaNumeroDepartamento = multa.additionalData!['numeroDepartamento'];
          
          print('🏠 Datos de vivienda en multa:');
          print('   - Tipo: $multaTipoVivienda');
          print('   - Número: $multaNumeroVivienda');
          print('   - Etiqueta edificio: $multaEtiquetaEdificio');
          print('   - Número departamento: $multaNumeroDepartamento');
          
          bool esLaMismaVivienda = false;
          
          if (tipoVivienda.toLowerCase() == 'casa') {
            esLaMismaVivienda = multaTipoVivienda?.toLowerCase() == 'casa' &&
                               multaNumeroVivienda == numeroVivienda;
            print('🔍 Comparando casa: ${multaTipoVivienda?.toLowerCase() == 'casa'} && ${multaNumeroVivienda == numeroVivienda}');
          } else if (tipoVivienda.toLowerCase() == 'departamento') {
            esLaMismaVivienda = multaTipoVivienda?.toLowerCase() == 'departamento' &&
                               multaEtiquetaEdificio == etiquetaEdificio &&
                               multaNumeroDepartamento == numeroDepartamento;
            print('🔍 Comparando departamento: ${multaTipoVivienda?.toLowerCase() == 'departamento'} && ${multaEtiquetaEdificio == etiquetaEdificio} && ${multaNumeroDepartamento == numeroDepartamento}');
          }
          
          print('🔍 ¿Es la misma vivienda? $esLaMismaVivienda');
          
          if (esLaMismaVivienda) {
            multasVivienda.add(multa);
            print('✅ Multa ${multa.id} añadida a la lista');
          } else {
            print('❌ Multa ${multa.id} no corresponde a esta vivienda');
          }
        } else {
          print('⚠️ Multa ${multa.id} no tiene additionalData');
        }
      }
      
      print('📊 Total de multas encontradas para esta vivienda: ${multasVivienda.length}');
      return multasVivienda;
    } catch (e) {
      print('❌ Error al obtener multas de vivienda: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Calcular total de multas de una vivienda
  Future<int> calcularTotalMultasVivienda({
    required String condominioId,
    required String tipoVivienda,
    required String numeroVivienda,
    String? etiquetaEdificio,
    String? numeroDepartamento,
  }) async {
    try {
      print('💰 Calculando total de multas para vivienda:');
      print('   - Condominio: $condominioId');
      print('   - Tipo: $tipoVivienda');
      print('   - Número: $numeroVivienda');
      print('   - Etiqueta edificio: $etiquetaEdificio');
      print('   - Número departamento: $numeroDepartamento');
      
      List<MultaModel> multas = await obtenerMultasVivienda(
        condominioId: condominioId,
        tipoVivienda: tipoVivienda,
        numeroVivienda: numeroVivienda,
        etiquetaEdificio: etiquetaEdificio,
        numeroDepartamento: numeroDepartamento,
      );
      
      print('📋 Procesando ${multas.length} multas para calcular total');
      
      int total = 0;
      for (MultaModel multa in multas) {
        print('🧾 Procesando multa: ${multa.id}');
        
        if (multa.additionalData != null && multa.additionalData!['valor'] != null) {
          // Manejar diferentes tipos de datos para el valor
          dynamic valorDynamic = multa.additionalData!['valor'];
          print('💲 Valor original: $valorDynamic (${valorDynamic.runtimeType})');
          
          int valorMulta;
          
          if (valorDynamic is int) {
            valorMulta = valorDynamic;
            print('💲 Valor es entero: $valorMulta');
          } else if (valorDynamic is double) {
            valorMulta = valorDynamic.round();
            print('💲 Valor es double, redondeado a: $valorMulta');
          } else if (valorDynamic is String) {
            valorMulta = int.tryParse(valorDynamic) ?? 0;
            print('💲 Valor es string, convertido a: $valorMulta');
          } else {
            print('⚠️ Valor de multa en formato no reconocido: $valorDynamic (${valorDynamic.runtimeType})');
            continue;
          }
          
          final totalAntes = total;
          total += valorMulta;
          print('💰 Total multas: $totalAntes → $total (+$valorMulta)');
        } else {
          print('⚠️ Multa ${multa.id} no tiene additionalData o valor válido');
          if (multa.additionalData == null) {
            print('⚠️ additionalData es null');
          } else {
            print('⚠️ valor en additionalData: ${multa.additionalData!['valor']}');
          }
        }
      }
      
      print('💰 Total final de multas: $total');
      return total;
    } catch (e) {
      print('❌ Error al calcular total de multas: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      return 0;
    }
  }

  // Calcular total de multas de un residente
  Future<int> calcularTotalMultasResidente(String condominioId, String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(condominioId)
          .doc('comunicaciones')
          .collection('multas')
          .get();

      int total = 0;
      
      for (var doc in snapshot.docs) {
        MultaModel multa = MultaModel.fromMap(doc.data() as Map<String, dynamic>);
        
        if (multa.additionalData != null && 
            multa.additionalData!['residentesIds'] != null &&
            multa.additionalData!['valor'] != null) {
          try {
            List<String> residentesIds = List<String>.from(multa.additionalData!['residentesIds']);
            if (residentesIds.contains(uid)) {
              total += (multa.additionalData!['valor'] as int);
            }
          } catch (e) {
            print('Error al procesar residentesIds para multa ${multa.id}: $e');
          }
        }
      }
      
      return total;
    } catch (e) {
      print('Error al calcular total de multas del residente: $e');
      return 0;
    }
  }
}