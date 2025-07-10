import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gasto_comun_model.dart';
import '../models/lista_porcentajes_model.dart';
import '../models/residente_model.dart';
import '../models/condominio_model.dart';
import '../models/multa_model.dart';
import 'multa_service.dart';

class GastosComunesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MultaService _multaService = MultaService();

  // Obtener referencia al documento de gastos comunes
  DocumentReference _getGastosComunesRef(String condominioId) {
    return _firestore.collection(condominioId).doc('gastosComunes');
  }

  // Obtener referencia a una subcolección específica
  CollectionReference _getSubcoleccionRef(String condominioId, TipoGasto tipo) {
    return _getGastosComunesRef(condominioId).collection(tipo.coleccion);
  }

  // Crear gasto común
  Future<String> crearGasto({
    required String condominioId,
    required GastoComunModel gasto,
  }) async {
    try {
      // Primero, asegurar que el documento principal existe
      await _getGastosComunesRef(
        condominioId,
      ).set({'condominioId': condominioId}, SetOptions(merge: true));

      // Crear el gasto en la subcolección correspondiente
      final docRef = await _getSubcoleccionRef(
        condominioId,
        gasto.tipo,
      ).add(gasto.toFirestore());

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear gasto: $e');
      throw Exception('Error al crear gasto: $e');
    }
  }

  // Obtener todos los gastos de un tipo específico
  Future<List<GastoComunModel>> obtenerGastosPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) async {
    try {
      final snapshot = await _getSubcoleccionRef(
        condominioId,
        tipo,
      ).orderBy('descripcion').get();

      return snapshot.docs
          .map(
            (doc) => GastoComunModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
              tipo,
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Error al obtener gastos: $e');
      return [];
    }
  }

  // Obtener todos los gastos (todos los tipos)
  Future<Map<TipoGasto, List<GastoComunModel>>> obtenerTodosLosGastos({
    required String condominioId,
  }) async {
    try {
      final Map<TipoGasto, List<GastoComunModel>> gastos = {};

      for (final tipo in TipoGasto.values) {
        gastos[tipo] = await obtenerGastosPorTipo(
          condominioId: condominioId,
          tipo: tipo,
        );
      }

      return gastos;
    } catch (e) {
      print('❌ Error al obtener todos los gastos: $e');
      return {};
    }
  }

  // Actualizar gasto
  Future<void> actualizarGasto({
    required String condominioId,
    required GastoComunModel gasto,
  }) async {
    try {
      await _getSubcoleccionRef(
        condominioId,
        gasto.tipo,
      ).doc(gasto.id).update(gasto.toFirestore());
    } catch (e) {
      print('❌ Error al actualizar gasto: $e');
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> eliminarGasto({
    required String condominioId,
    required String gastoId,
    required TipoGasto tipo,
  }) async {
    try {
      await _getSubcoleccionRef(condominioId, tipo).doc(gastoId).delete();
    } catch (e) {
      print('❌ Error al eliminar gasto: $e');
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener un gasto específico
  Future<GastoComunModel?> obtenerGasto({
    required String condominioId,
    required String gastoId,
    required TipoGasto tipo,
  }) async {
    try {
      final doc = await _getSubcoleccionRef(
        condominioId,
        tipo,
      ).doc(gastoId).get();

      if (doc.exists) {
        return GastoComunModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
          tipo,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener gasto: $e');
      return null;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<GastoComunModel>> streamGastosPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) {
    return _getSubcoleccionRef(condominioId, tipo)
        .orderBy('descripcion')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => GastoComunModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                  tipo,
                ),
              )
              .toList(),
        );
  }

  // Calcular total de gastos por tipo
  Future<int> calcularTotalPorTipo({
    required String condominioId,
    required TipoGasto tipo,
  }) async {
    try {
      final gastos = await obtenerGastosPorTipo(
        condominioId: condominioId,
        tipo: tipo,
      );

      return gastos.fold<int>(0, (total, gasto) => total + gasto.monto);
    } catch (e) {
      print('❌ Error al calcular total: $e');
      return 0;
    }
  }

  // Calcular total general de todos los gastos
  Future<int> calcularTotalGeneral({required String condominioId}) async {
    try {
      int total = 0;
      for (final tipo in TipoGasto.values) {
        total += await calcularTotalPorTipo(
          condominioId: condominioId,
          tipo: tipo,
        );
      }
      return total;
    } catch (e) {
      print('❌ Error al calcular total general: $e');
      return 0;
    }
  }

  // ==================== MÉTODOS PARA LISTAS DE PORCENTAJES ====================

  // Obtener referencia a la subcolección de listas de porcentajes
  CollectionReference _getListasPorcentajesRef(String condominioId) {
    return _getGastosComunesRef(condominioId).collection('listaPorcentajes');
  }

  // Crear una nueva lista de porcentajes
  Future<String> crearListaPorcentajes({
    required String condominioId,
    required ListaPorcentajesModel lista,
  }) async {
    try {
      // Asegurar que el documento principal existe
      await _getGastosComunesRef(
        condominioId,
      ).set({'condominioId': condominioId}, SetOptions(merge: true));

      final docRef = await _getListasPorcentajesRef(
        condominioId,
      ).add(lista.toFirestore());

      return docRef.id;
    } catch (e) {
      print('❌ Error al crear lista de porcentajes: $e');
      throw Exception('Error al crear lista de porcentajes: $e');
    }
  }

  // Obtener todas las listas de porcentajes
  Future<List<ListaPorcentajesModel>> obtenerListasPorcentajes({
    required String condominioId,
  }) async {
    try {
      final querySnapshot = await _getListasPorcentajesRef(
        condominioId,
      ).orderBy('fechaCreacion', descending: true).get();

      return querySnapshot.docs
          .map(
            (doc) => ListaPorcentajesModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('❌ Error al obtener listas de porcentajes: $e');
      return [];
    }
  }

  // Obtener una lista de porcentajes específica
  Future<ListaPorcentajesModel?> obtenerListaPorcentajes({
    required String condominioId,
    required String listaId,
  }) async {
    try {
      final doc = await _getListasPorcentajesRef(
        condominioId,
      ).doc(listaId).get();

      if (doc.exists) {
        return ListaPorcentajesModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener lista de porcentajes: $e');
      return null;
    }
  }

  // Actualizar una lista de porcentajes
  Future<void> actualizarListaPorcentajes({
    required String condominioId,
    required ListaPorcentajesModel lista,
  }) async {
    try {
      await _getListasPorcentajesRef(
        condominioId,
      ).doc(lista.id).update(lista.toFirestore());
    } catch (e) {
      print('❌ Error al actualizar lista de porcentajes: $e');
      throw Exception('Error al actualizar lista de porcentajes: $e');
    }
  }

  // Eliminar una lista de porcentajes
  Future<void> eliminarListaPorcentajes({
    required String condominioId,
    required String listaId,
  }) async {
    try {
      await _getListasPorcentajesRef(condominioId).doc(listaId).delete();
    } catch (e) {
      print('❌ Error al eliminar lista de porcentajes: $e');
      throw Exception('Error al eliminar lista de porcentajes: $e');
    }
  }

  // Obtener todas las viviendas con residentes del condominio
  Future<Map<String, ViviendaPorcentajeModel>> obtenerViviendasConResidentes({
    required String condominioId,
  }) async {
    try {
      print(
        '🔍 Iniciando obtención de viviendas con residentes para condominio: $condominioId',
      );

      // Usar el mismo método que obtenerResidentesCondominio en firestore_service.dart
      final querySnapshot = await _firestore
          .collection(condominioId)
          .doc('usuarios')
          .collection('residentes')
          .get();

      print('📊 Documentos encontrados: ${querySnapshot.docs.length}');

      final Map<String, ViviendaPorcentajeModel> viviendas = {};

      // Filtrar documentos igual que en obtenerResidentesCondominio
      final residentes = querySnapshot.docs
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

      print('👥 Residentes válidos procesados: ${residentes.length}');

      for (final residente in residentes) {
        print('👤 Procesando residente: ${residente.nombre}');
        print('🏠 Tipo vivienda: ${residente.tipoVivienda}');
        print('🔢 Número vivienda: ${residente.numeroVivienda}');
        print('🏢 Etiqueta edificio: ${residente.etiquetaEdificio}');
        print('🚪 Número departamento: ${residente.numeroDepartamento}');
        print('✅ Estado vivienda: ${residente.viviendaSeleccionada}');

        final viviendaKey = residente.descripcionVivienda;
        print('🔑 Clave de vivienda generada: "$viviendaKey"');
        print('📝 Descripción vivienda: "${residente.descripcionVivienda}"');

        // Solo procesar si tiene vivienda asignada y está seleccionada
        // Aceptar tanto boolean true como string 'seleccionada'
        bool viviendaEstaSeleccionada =
            residente.viviendaSeleccionada == 'seleccionada' ||
            residente.viviendaSeleccionada == true;

        if (viviendaKey.isNotEmpty && viviendaEstaSeleccionada) {
          if (viviendas.containsKey(viviendaKey)) {
            print('🔄 Agregando residente a vivienda existente: $viviendaKey');
            // Agregar residente a vivienda existente
            final viviendaExistente = viviendas[viviendaKey]!;
            final nuevaLista = List<String>.from(
              viviendaExistente.listaIdsResidentes,
            )..add(residente.uid);

            viviendas[viviendaKey] = viviendaExistente.copyWith(
              listaIdsResidentes: nuevaLista,
            );
            print(
              '✅ Residente agregado. Total residentes en $viviendaKey: ${nuevaLista.length}',
            );
          } else {
            print('🆕 Creando nueva entrada de vivienda: $viviendaKey');
            // Crear nueva entrada de vivienda
            viviendas[viviendaKey] = ViviendaPorcentajeModel(
              vivienda: viviendaKey,
              listaIdsResidentes: [residente.uid],
              porcentaje: 0,
              descripcionVivienda: residente.descripcionVivienda,
            );
            print('✅ Nueva vivienda creada: $viviendaKey');
          }
        } else {
          if (viviendaKey.isEmpty) {
            print(
              '⚠️ Residente ${residente.nombre} no tiene vivienda asignada válida (clave vacía)',
            );
          } else {
            print(
              '⚠️ Residente ${residente.nombre} tiene vivienda pero no está seleccionada (estado: ${residente.viviendaSeleccionada})',
            );
          }
        }
      }

      print('📈 Total de viviendas procesadas: ${viviendas.length}');
      print('🏠 Viviendas encontradas:');
      viviendas.forEach((key, value) {
        print(
          '   - $key: ${value.descripcionVivienda} (${value.listaIdsResidentes.length} residentes)',
        );
      });

      return viviendas;
    } catch (e) {
      print('❌ Error al obtener viviendas con residentes: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  // Contar el número de listas de porcentajes
  Future<int> contarListasPorcentajes({required String condominioId}) async {
    try {
      final querySnapshot = await _getListasPorcentajesRef(condominioId).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error al contar listas de porcentajes: $e');
      return 0;
    }
  }

  // Stream para escuchar cambios en las listas de porcentajes
  Stream<List<ListaPorcentajesModel>> streamListasPorcentajes({
    required String condominioId,
  }) {
    return _getListasPorcentajesRef(condominioId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ListaPorcentajesModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ==================== CÁLCULO DE GASTOS POR RESIDENTE ====================

  // Calcular gastos comunes por residente
  Future<Map<String, Map<String, dynamic>>> calcularGastosPorResidente({
    required String condominioId,
  }) async {
    try {
      print(
        '🧮 Iniciando cálculo de gastos por residente para condominio: $condominioId',
      );
      //print('📍 Stack trace de inicio: ${StackTrace.current}');

      // Verificar configuración de multas y espacios comunes
      DocumentSnapshot condominioDoc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      bool cobrarMultasConGastos = false;
      bool cobrarEspaciosConGastos = false;
      if (condominioDoc.exists) {
        Map<String, dynamic> condominioData =
            condominioDoc.data() as Map<String, dynamic>;
        cobrarMultasConGastos =
            condominioData['cobrarMultasConGastos'] ?? false;
        cobrarEspaciosConGastos =
            condominioData['cobrarEspaciosConGastos'] ?? false;
        print('📄 Datos del condominio: ${condominioData.toString()}');
      } else {
        print('⚠️ Documento del condominio no existe');
      }

      print('💰 Configuración multas con gastos: $cobrarMultasConGastos');
      print('🏢 Configuración espacios comunes con gastos: $cobrarEspaciosConGastos');

      // Obtener todos los gastos comunes
      final todosLosGastos = await obtenerTodosLosGastos(
        condominioId: condominioId,
      );
      print('📊 Total de tipos de gastos obtenidos: ${todosLosGastos.length}');
      todosLosGastos.forEach((tipo, gastos) {
        print('📋 Tipo: ${tipo.nombre}, Cantidad: ${gastos.length}');
      });

      // Obtener viviendas con residentes
      final viviendas = await obtenerViviendasConResidentes(
        condominioId: condominioId,
      );

      // Contar viviendas activas para gastos "igual para todos"
      final totalViviendasActivas = viviendas.length;
      print('🏠 Total de viviendas activas: $totalViviendasActivas');
      print('🏠 Viviendas encontradas: ${viviendas.keys.join(', ')}');

      if (totalViviendasActivas == 0) {
        print('⚠️ No hay viviendas activas para calcular gastos');
        return {};
      }

      // Mapa para almacenar el resultado: viviendaKey -> {residenteId: monto, total: monto}
      final Map<String, Map<String, dynamic>> gastosCalculados = {};

      // Inicializar el mapa con todas las viviendas
      for (final viviendaKey in viviendas.keys) {
        print('🔄 Inicializando datos para vivienda: $viviendaKey');
        print(
          '👥 Residentes en esta vivienda: ${viviendas[viviendaKey]!.listaIdsResidentes}',
        );

        gastosCalculados[viviendaKey] = {
          'vivienda': viviendaKey,
          'descripcion': viviendas[viviendaKey]!.descripcionVivienda,
          'residentes': viviendas[viviendaKey]!.listaIdsResidentes,
          'montoTotal': 0,
          'montoGastos': 0,
          'montoMultas': 0,
          'montoEspaciosComunes': 0,
          'detalleGastos': <Map<String, dynamic>>[],
          'detalleMultas': <Map<String, dynamic>>[],
          'detalleEspaciosComunes': <Map<String, dynamic>>[]
        };
      }

      // Procesar cada tipo de gasto
      for (final tipoGasto in todosLosGastos.keys) {
        final gastosDelTipo = todosLosGastos[tipoGasto] ?? [];
        print(
          '💰 Procesando ${gastosDelTipo.length} gastos de tipo: ${tipoGasto.nombre}',
        );

        for (final gasto in gastosDelTipo) {
          print(
            '📋 Procesando gasto: ${gasto.descripcion} - Monto: ${gasto.monto} - Tipo cobro: ${gasto.tipoCobro}',
          );
          print('📋 Datos completos del gasto: ${gasto.toFirestore()}');

          if (gasto.tipoCobro == 'igual para todos') {
            // Dividir el monto entre todas las viviendas activas
            final montoPorVivienda = (gasto.monto / totalViviendasActivas)
                .round();
            print(
              '🔢 Monto por vivienda (igual para todos): $montoPorVivienda',
            );
            print(
              '🔢 Cálculo: ${gasto.monto} / $totalViviendasActivas = $montoPorVivienda',
            );

            for (final viviendaKey in viviendas.keys) {
              final montoGastosAntes =
                  gastosCalculados[viviendaKey]!['montoGastos'];
              final montoTotalAntes =
                  gastosCalculados[viviendaKey]!['montoTotal'];

              gastosCalculados[viviendaKey]!['montoGastos'] += montoPorVivienda;
              gastosCalculados[viviendaKey]!['montoTotal'] += montoPorVivienda;

              print(
                '💵 Vivienda $viviendaKey - Gastos: $montoGastosAntes → ${gastosCalculados[viviendaKey]!['montoGastos']}',
              );
              print(
                '💵 Vivienda $viviendaKey - Total: $montoTotalAntes → ${gastosCalculados[viviendaKey]!['montoTotal']}',
              );

              (gastosCalculados[viviendaKey]!['detalleGastos']
                      as List<Map<String, dynamic>>)
                  .add({
                    'descripcion': gasto.descripcion,
                    'monto': montoPorVivienda,
                    'tipoCobro': gasto.tipoCobro,
                    'tipo': tipoGasto.nombre,
                  });
            }
          } else if (gasto.tipoCobro == 'porcentaje por residente' &&
              gasto.pctjePorRes != null) {
            // Usar la lista de porcentajes almacenada
            final pctjeData = gasto.pctjePorRes!;
            final viviendasPorcentajes =
                pctjeData['viviendas'] as Map<String, dynamic>? ?? {};

            print('📊 Usando lista de porcentajes: ${pctjeData['nombre']}');
            print('📊 Datos completos de la lista: $pctjeData');
            print(
              '📈 Porcentajes disponibles: ${viviendasPorcentajes.keys.length}',
            );
            print(
              '📈 Viviendas con porcentaje: ${viviendasPorcentajes.keys.join(', ')}',
            );

            for (final viviendaKey in viviendas.keys) {
              final vivienda = viviendas[viviendaKey]!;

              // Buscar el porcentaje para esta vivienda directamente por su clave
              double porcentajeVivienda = 0.0;

              if (viviendasPorcentajes.containsKey(viviendaKey)) {
                final viviendaData =
                    viviendasPorcentajes[viviendaKey] as Map<String, dynamic>;
                porcentajeVivienda = (viviendaData['porcentaje'] as num)
                    .toDouble();
                print(
                  '🔍 Encontrado porcentaje para vivienda $viviendaKey: ${porcentajeVivienda}%',
                );
                print('🔍 Datos completos: $viviendaData');
              } else {
                print(
                  '⚠️ No se encontró la vivienda $viviendaKey en la lista de porcentajes',
                );
                print(
                  '⚠️ Claves disponibles: ${viviendasPorcentajes.keys.join(', ')}',
                );
              }

              if (porcentajeVivienda > 0) {
                final montoVivienda = (gasto.monto * porcentajeVivienda / 100)
                    .round();
                print(
                  '🏠 Vivienda $viviendaKey: ${porcentajeVivienda}% = $montoVivienda',
                );
                print(
                  '🏠 Cálculo: ${gasto.monto} * ${porcentajeVivienda} / 100 = $montoVivienda',
                );

                final montoGastosAntes =
                    gastosCalculados[viviendaKey]!['montoGastos'];
                final montoTotalAntes =
                    gastosCalculados[viviendaKey]!['montoTotal'];

                gastosCalculados[viviendaKey]!['montoGastos'] += montoVivienda;
                gastosCalculados[viviendaKey]!['montoTotal'] += montoVivienda;

                print(
                  '💵 Vivienda $viviendaKey - Gastos: $montoGastosAntes → ${gastosCalculados[viviendaKey]!['montoGastos']}',
                );
                print(
                  '💵 Vivienda $viviendaKey - Total: $montoTotalAntes → ${gastosCalculados[viviendaKey]!['montoTotal']}',
                );

                (gastosCalculados[viviendaKey]!['detalleGastos']
                        as List<Map<String, dynamic>>)
                    .add({
                      'descripcion': gasto.descripcion,
                      'monto': montoVivienda,
                      'tipoCobro': gasto.tipoCobro,
                      'tipo': tipoGasto.nombre,
                      'porcentaje': porcentajeVivienda,
                      'nombreLista': pctjeData['nombre'],
                    });
              } else {
                print(
                  '! No se encontró porcentaje para vivienda $viviendaKey en gasto ${gasto.descripcion}',
                );
              }
            }
          } else {
            print(
              '⚠️ Tipo de cobro no reconocido o datos faltantes: ${gasto.tipoCobro}',
            );
            if (gasto.tipoCobro == 'porcentaje por residente') {
              print('⚠️ pctjePorRes es null o inválido: ${gasto.pctjePorRes}');
            }
          }
        }
      }

      // Agregar multas si la configuración está activada
      if (cobrarMultasConGastos) {
        print('🚨 Agregando multas al cálculo de gastos comunes');
        print('🚨 Estado de cobrarMultasConGastos: $cobrarMultasConGastos');

        for (final viviendaKey in viviendas.keys) {
          final vivienda = viviendas[viviendaKey]!;
          print('🏠 Procesando multas para vivienda: $viviendaKey');
          print('🏠 Descripción: ${vivienda.descripcionVivienda}');
          print('🏠 Residentes: ${vivienda.listaIdsResidentes}');

          // Extraer información de la vivienda desde la clave
          // La clave viene en formato "Casa 8" o "A-109", necesitamos convertirla
          String tipoVivienda = '';
          String numeroVivienda = '';
          String? etiquetaEdificio;
          String? numeroDepartamento;

          print('🔑 Procesando clave de vivienda: "$viviendaKey"');
          
          // Buscar el residente asociado a esta vivienda para obtener los datos correctos
          String? residenteId = vivienda.listaIdsResidentes.isNotEmpty 
              ? vivienda.listaIdsResidentes.first 
              : null;
          
          if (residenteId != null) {
            try {
              // Obtener datos del residente para extraer información de vivienda
              DocumentSnapshot residenteDoc = await _firestore
                  .collection(condominioId)
                  .doc('usuarios')
                  .collection('residentes')
                  .doc(residenteId)
                  .get();
              
              if (residenteDoc.exists) {
                Map<String, dynamic> residenteData = residenteDoc.data() as Map<String, dynamic>;
                
                tipoVivienda = residenteData['tipoVivienda']?.toString().toLowerCase() ?? '';
                 numeroVivienda = residenteData['numeroVivienda']?.toString() ?? '';
                 etiquetaEdificio = residenteData['etiquetaEdificio']?.toString();
                 numeroDepartamento = residenteData['numeroDepartamento']?.toString();
                 
                 // Validar que tenemos los datos mínimos necesarios
                 if (tipoVivienda.isEmpty || numeroVivienda.isEmpty) {
                   print('⚠️ Datos de vivienda incompletos:');
                   print('   - tipoVivienda: "$tipoVivienda"');
                   print('   - numeroVivienda: "$numeroVivienda"');
                   print('   - Datos completos del residente: $residenteData');
                 }
                
                print('🏘️ Datos extraídos del residente:');
                print('   - Tipo de vivienda: $tipoVivienda');
                print('   - Número de vivienda: $numeroVivienda');
                print('   - Etiqueta edificio: $etiquetaEdificio');
                print('   - Número departamento: $numeroDepartamento');
              } else {
                print('⚠️ No se encontró el documento del residente: $residenteId');
              }
            } catch (e) {
              print('❌ Error al obtener datos del residente: $e');
            }
          } else {
            print('⚠️ No hay residentes asociados a esta vivienda');
          }
          // Obtener multas de la vivienda
          print('🔍 Buscando multas para vivienda $viviendaKey');
          List<MultaModel> multasVivienda = await _multaService
              .obtenerMultasVivienda(
                condominioId: condominioId,
                tipoVivienda: tipoVivienda,
                numeroVivienda: numeroVivienda,
                etiquetaEdificio: etiquetaEdificio,
                numeroDepartamento: numeroDepartamento,
              );

          print('📋 Multas encontradas: ${multasVivienda.length}');
          for (var i = 0; i < multasVivienda.length; i++) {
            print(
              '📋 Multa ${i + 1}: ID=${multasVivienda[i].id}, Tipo=${multasVivienda[i].tipoMulta}',
            );
          }

          int totalMultas = 0;
          List<Map<String, dynamic>> detalleMultas = [];

          for (MultaModel multa in multasVivienda) {
            try {
              print('🧾 Procesando multa: ${multa.id}');
              print('🧾 Datos completos: ${multa.toMap()}');

              if (multa.additionalData != null &&
                  multa.additionalData!['valor'] != null) {
                // Manejar diferentes tipos de datos para el valor
                dynamic valorDynamic = multa.additionalData!['valor'];
                print(
                  '💲 Valor original: $valorDynamic (${valorDynamic.runtimeType})',
                );

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
                  print(
                    '⚠️ Valor de multa en formato no reconocido: $valorDynamic (${valorDynamic.runtimeType})',
                  );
                  continue;
                }

                final totalMultasAntes = totalMultas;
                totalMultas += valorMulta;
                print(
                  '💰 Total multas: $totalMultasAntes → $totalMultas (+$valorMulta)',
                );

                detalleMultas.add({
                  'tipoMulta': multa.tipoMulta ?? 'Multa',
                  'contenido': multa.contenido ?? '',
                  'valor': valorMulta,
                  'fechaRegistro': multa.fechaRegistro ?? '',
                });
                print('📝 Detalle de multa agregado: ${detalleMultas.last}');
              } else {
                print(
                  '⚠️ Multa ${multa.id} no tiene additionalData o valor válido',
                );
                if (multa.additionalData == null) {
                  print('⚠️ additionalData es null');
                } else {
                  print('⚠️ additionalData: ${multa.additionalData}');
                  print(
                    '⚠️ valor en additionalData: ${multa.additionalData!['valor']}',
                  );
                }
              }
            } catch (e) {
              print('❌ Error al procesar multa ${multa.id}: $e');
              print('❌ Stack trace: ${StackTrace.current}');
              continue;
            }
          }

          final montoTotalAntes = gastosCalculados[viviendaKey]!['montoTotal'];

          gastosCalculados[viviendaKey]!['montoMultas'] = totalMultas;
          gastosCalculados[viviendaKey]!['montoTotal'] += totalMultas;
          gastosCalculados[viviendaKey]!['detalleMultas'] = detalleMultas;

          print('🚨 Vivienda $viviendaKey: Multas = $totalMultas');
          print(
            '💵 Vivienda $viviendaKey - Total: $montoTotalAntes → ${gastosCalculados[viviendaKey]!['montoTotal']}',
          );
          print('📊 Resumen para vivienda $viviendaKey:');
          print(
            '   - Gastos: ${gastosCalculados[viviendaKey]!['montoGastos']}',
          );
          print(
            '   - Multas: ${gastosCalculados[viviendaKey]!['montoMultas']}',
          );
          print('   - Total: ${gastosCalculados[viviendaKey]!['montoTotal']}');
        }
      } else {
        print(
          '⚠️ No se agregarán multas porque cobrarMultasConGastos = $cobrarMultasConGastos',
        );
      }

      // Agregar espacios comunes si la configuración está activada
      if (cobrarEspaciosConGastos) {
        print('🏢 Agregando espacios comunes al cálculo de gastos comunes');
        print('🏢 Estado de cobrarEspaciosConGastos: $cobrarEspaciosConGastos');

        for (final viviendaKey in viviendas.keys) {
          final vivienda = viviendas[viviendaKey]!;
          print('🏠 Procesando espacios comunes para vivienda: $viviendaKey');
          print('🏠 Residentes: ${vivienda.listaIdsResidentes}');

          int totalEspaciosComunes = 0;
          List<Map<String, dynamic>> detalleEspaciosComunes = [];

          // Procesar cada residente de la vivienda
          for (String residenteId in vivienda.listaIdsResidentes) {
            try {
              print('👤 Calculando espacios comunes para residente: $residenteId');
              
              // Obtener todas las reservas aprobadas del residente
              QuerySnapshot reservasSnapshot = await _firestore
                  .collection(condominioId)
                  .doc('espaciosComunes')
                  .collection('reservas')
                  .where('residenteId', isEqualTo: residenteId)
                  .where('estado', isEqualTo: 'aprobada')
                  .get();

              print('📋 Reservas aprobadas encontradas: ${reservasSnapshot.docs.length}');

              for (QueryDocumentSnapshot reservaDoc in reservasSnapshot.docs) {
                Map<String, dynamic> reservaData = reservaDoc.data() as Map<String, dynamic>;
                print('🔍 Procesando reserva: ${reservaDoc.id}');
                
                int costoReserva = 0;
                String nombreEspacio = 'Espacio desconocido';
                String espacioId = reservaData['espacioId'] ?? '';
                
                // Obtener datos del espacio común
                if (espacioId.isNotEmpty) {
                  try {
                    DocumentSnapshot espacioDoc = await _firestore
                        .collection(condominioId)
                        .doc('espaciosComunes')
                        .collection('espaciosComunes')
                        .doc(espacioId)
                        .get();
                    
                    if (espacioDoc.exists) {
                      Map<String, dynamic> espacioData = espacioDoc.data() as Map<String, dynamic>;
                      nombreEspacio = espacioData['nombre'] ?? 'Espacio sin nombre';
                      int precioEspacio = espacioData['precio'] ?? 0;
                      costoReserva += precioEspacio;
                      print('💰 Precio del espacio "$nombreEspacio": $precioEspacio');
                      print('💰 Costo reserva después de agregar precio base: $costoReserva');
                    } else {
                      print('❌ Documento del espacio $espacioId no existe');
                    }
                  } catch (e) {
                    print('❌ Error al obtener datos del espacio $espacioId: $e');
                  }
                }
                
                // Sumar costos de revisiones si existen
                int costoRevisiones = 0;
                if (reservaData['revisionesUso'] != null) {
                  dynamic revisionesData = reservaData['revisionesUso'];
                  
                  // Manejar tanto List como Map para revisionesUso
                  if (revisionesData is List<dynamic>) {
                    // Si es una lista, procesar cada elemento
                    for (dynamic revision in revisionesData) {
                      if (revision is Map<String, dynamic>) {
                        int costo = revision['costo'] ?? 0;
                        if (costo > 0) {
                          costoRevisiones += costo;
                          print('🔧 Costo de revisión (lista): $costo');
                        }
                      }
                    }
                  } else if (revisionesData is Map<String, dynamic>) {
                    // Si es un mapa, procesar cada valor
                    revisionesData.forEach((key, revision) {
                      if (revision is Map<String, dynamic>) {
                        int costo = revision['costo'] ?? 0;
                        if (costo > 0) {
                          costoRevisiones += costo;
                          print('🔧 Costo de revisión (mapa): $costo');
                        }
                      }
                    });
                  } else {
                    print('⚠️ Formato inesperado para revisionesUso: ${revisionesData.runtimeType}');
                  }
                }
                
                costoReserva += costoRevisiones;
                print('💰 Costo total de la reserva (base + revisiones): $costoReserva (base: ${costoReserva - costoRevisiones}, revisiones: $costoRevisiones)');
                
                // Solo agregar si hay algún costo
                if (costoReserva > 0) {
                  totalEspaciosComunes += costoReserva;
                  
                  // Formatear fecha
                  String fechaUso = 'Sin fecha';
                  if (reservaData['fechaUso'] != null) {
                    try {
                      DateTime fecha;
                      if (reservaData['fechaUso'] is Timestamp) {
                        fecha = (reservaData['fechaUso'] as Timestamp).toDate();
                      } else if (reservaData['fechaUso'] is String) {
                        fecha = DateTime.parse(reservaData['fechaUso'] as String);
                      } else {
                        throw Exception('Formato de fecha no soportado: ${reservaData['fechaUso'].runtimeType}');
                      }
                      fechaUso = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                    } catch (e) {
                      print('⚠️ Error al formatear fecha: $e');
                      fechaUso = 'Fecha inválida';
                    }
                  }
                  
                  detalleEspaciosComunes.add({
                    'nombreEspacio': nombreEspacio,
                    'fecha': fechaUso,
                    'costoEspacio': costoReserva - costoRevisiones,
                    'costoRevisiones': costoRevisiones,
                    'total': costoReserva,
                  });
                  
                  print('📝 Espacio común agregado: $nombreEspacio - $costoReserva');
                }
              }
            } catch (e) {
              print('❌ Error al procesar espacios comunes del residente $residenteId: $e');
            }
          }

          final montoTotalAntes = gastosCalculados[viviendaKey]!['montoTotal'];

          gastosCalculados[viviendaKey]!['montoEspaciosComunes'] = totalEspaciosComunes;
          gastosCalculados[viviendaKey]!['montoTotal'] += totalEspaciosComunes;
          gastosCalculados[viviendaKey]!['detalleEspaciosComunes'] = detalleEspaciosComunes;

          print('🏢 Vivienda $viviendaKey: Espacios Comunes = $totalEspaciosComunes');
          print(
            '💵 Vivienda $viviendaKey - Total: $montoTotalAntes → ${gastosCalculados[viviendaKey]!['montoTotal']}',
          );
        }
      } else {
        print(
          '⚠️ No se agregarán espacios comunes porque cobrarEspaciosConGastos = $cobrarEspaciosConGastos',
        );
      }

      print(
        '✅ Cálculo completado. Viviendas procesadas: ${gastosCalculados.length}',
      );

      // Mostrar resumen
      gastosCalculados.forEach((viviendaKey, datos) {
        print(
          '🏠 $viviendaKey: Gastos = ${datos['montoGastos']}, Multas = ${datos['montoMultas']}, Espacios = ${datos['montoEspaciosComunes']}, Total = ${datos['montoTotal']}',
        );
      });

      return gastosCalculados;
    } catch (e) {
      print('❌ Error al calcular gastos por residente: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  // Obtener gastos de un residente específico
  Future<Map<String, dynamic>?> obtenerGastosResidente({
    required String condominioId,
    required String residenteId,
  }) async {
    try {
      print(
        '🔍 Obteniendo gastos para residente: $residenteId en condominio: $condominioId',
      );
      //print('📍 Stack trace de inicio: ${StackTrace.current}');

      // Verificar configuración de multas
      DocumentSnapshot condominioDoc = await _firestore
          .collection(condominioId)
          .doc('condominio')
          .get();

      bool cobrarMultasConGastos = false;
      if (condominioDoc.exists) {
        Map<String, dynamic> condominioData =
            condominioDoc.data() as Map<String, dynamic>;
        cobrarMultasConGastos =
            condominioData['cobrarMultasConGastos'] ?? false;
        print('📄 Datos del condominio: ${condominioData.toString()}');
        print('💰 Configuración multas con gastos: $cobrarMultasConGastos');
      } else {
        print('⚠️ Documento del condominio no existe');
      }

      final gastosCalculados = await calcularGastosPorResidente(
        condominioId: condominioId,
      );

      print('📊 Gastos calculados para ${gastosCalculados.length} viviendas');
      print('📊 Viviendas disponibles: ${gastosCalculados.keys.join(', ')}');

      // Buscar la vivienda que contiene este residente
      for (final viviendaKey in gastosCalculados.keys) {
        final viviendaData = gastosCalculados[viviendaKey]!;
        print('🔍 Examinando vivienda: $viviendaKey');
        print('🔍 Datos de la vivienda: ${viviendaData.toString()}');

        // Verificar que residentes no sea null
        if (viviendaData['residentes'] != null) {
          final residentes = List<String>.from(viviendaData['residentes']);
          print('🏠 Vivienda $viviendaKey tiene residentes: $residentes');
          print('🔍 Buscando residente $residenteId en la lista');

          if (residentes.contains(residenteId)) {
            print('✅ Residente encontrado en vivienda: $viviendaKey');
            print('✅ Posición en la lista: ${residentes.indexOf(residenteId)}');

            // Asegurar que todos los campos necesarios existen y no son null
            final resultado = {
              'vivienda': viviendaData['vivienda'] ?? viviendaKey,
              'descripcion': viviendaData['descripcion'] ?? '',
              'residentes': residentes,
              'montoTotal': viviendaData['montoTotal'] ?? 0,
              'montoGastos': viviendaData['montoGastos'] ?? 0,
              'montoMultas': viviendaData['montoMultas'] ?? 0,
              'montoEspaciosComunes': viviendaData['montoEspaciosComunes'] ?? 0,
              'detalleGastos':
                  viviendaData['detalleGastos'] ?? <Map<String, dynamic>>[],
              'detalleMultas':
                  viviendaData['detalleMultas'] ?? <Map<String, dynamic>>[],
              'detalleEspaciosComunes':
                  viviendaData['detalleEspaciosComunes'] ?? <Map<String, dynamic>>[],
            };

            print(
              '📋 Datos del residente: Gastos=${resultado['montoGastos']}, Multas=${resultado['montoMultas']}, Espacios=${resultado['montoEspaciosComunes']}, Total=${resultado['montoTotal']}',
            );
            print(
              '📋 Detalle de gastos: ${(resultado['detalleGastos'] as List).length} items',
            );
            print(
              '📋 Detalle de multas: ${(resultado['detalleMultas'] as List).length} items',
            );
            print(
              '📋 Detalle de espacios comunes: ${(resultado['detalleEspaciosComunes'] as List).length} items',
            );

            // Verificar si hay multas pero no están incluidas en el total
            if (!cobrarMultasConGastos &&
                (resultado['montoMultas'] as int) > 0) {
              print(
                '⚠️ ADVERTENCIA: Hay multas (${resultado['montoMultas']}) pero cobrarMultasConGastos=$cobrarMultasConGastos',
              );
            }

            // Verificar si la suma de gastos, multas y espacios comunes coincide con el total
            int sumaCalculada =
                (resultado['montoGastos'] as int) +
                (resultado['montoMultas'] as int) +
                (resultado['montoEspaciosComunes'] as int);
            if (sumaCalculada != (resultado['montoTotal'] as int)) {
              print(
                '⚠️ ADVERTENCIA: La suma de gastos (${resultado['montoGastos']}), multas (${resultado['montoMultas']}) y espacios comunes (${resultado['montoEspaciosComunes']}) = $sumaCalculada no coincide con el total (${resultado['montoTotal']})',
              );
            }

            return resultado;
          } else {
            print(
              '❓ Residente $residenteId NO encontrado en vivienda $viviendaKey',
            );
          }
        } else {
          print('⚠️ Vivienda $viviendaKey no tiene lista de residentes válida');
        }
      }

      print('❌ Residente $residenteId no encontrado en ninguna vivienda');
      return null;
    } catch (e) {
      print('❌ Error al obtener gastos del residente: $e');
      //print('📍 Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
