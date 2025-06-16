import 'package:comunidad_activa/screens/admin/dialog_config_viviendas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';

class ViviendasScreen extends StatefulWidget {
  final String condominioId;

  const ViviendasScreen({super.key, required this.condominioId});

  @override
  State<ViviendasScreen> createState() => _ViviendasScreenState();
}

class _ViviendasScreenState extends State<ViviendasScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  CondominioModel? _condominio;
  bool _isLoading = true;
  TipoCondominio? _tipoSeleccionado;
  bool _edificiosIguales = true;
  // Controladores para casas
  final TextEditingController _numeroCasasController = TextEditingController();
  final TextEditingController _rangoCasasController = TextEditingController();

  // Controladores para edificios (compatibilidad)
  final TextEditingController _numeroTorresController = TextEditingController();
  final TextEditingController _apartamentosPorTorreController =
      TextEditingController();
  final TextEditingController _numeracionController = TextEditingController();
  final TextEditingController _etiquetasTorresController =
      TextEditingController();
  final TextEditingController _rangoTorresController = TextEditingController();

  // Lista de configuraciones de edificios
  List<ConfiguracionEdificio> _configuracionesEdificios = [];

  // Listas para mostrar los elementos expandidos
  List<String> _numeracionExpandida = [];
  List<String> _etiquetasExpandidas = [];
  List<String> _rangoCasasExpandido = [];

  // Variables para validaciones en tiempo real
  String? _errorNumeracion;
  String? _errorEtiquetas;
  String? _errorRangoCasas;

  // Método para eliminar elemento de numeración y recalcular
  void _eliminarNumeracion(String elemento) {
    setState(() {
      _numeracionExpandida.remove(elemento);
      _numeracionController.text = _reconstruirTextoDesdeElementos(_numeracionExpandida);
      
      int? apartamentosPorTorre;
      if (_apartamentosPorTorreController.text.isNotEmpty) {
        apartamentosPorTorre = int.tryParse(_apartamentosPorTorreController.text);
      }
      
      _errorNumeracion = _validarRangosEnTiempoReal(
        _numeracionController.text,
        apartamentosPorTorre,
      );
    });
  }

  // Método para eliminar elemento de etiquetas y recalcular
  void _eliminarEtiqueta(String elemento) {
    setState(() {
      _etiquetasExpandidas.remove(elemento);
      _etiquetasTorresController.text = _reconstruirTextoDesdeElementos(_etiquetasExpandidas);
      
      final cantidadEsperada = _numeroTorresController.text.isNotEmpty
          ? int.tryParse(_numeroTorresController.text)
          : null;
      
      _errorEtiquetas = _validarRangosEnTiempoReal(
        _etiquetasTorresController.text,
        cantidadEsperada,
      );
    });
  }

  // Método para eliminar elemento de rango casas y recalcular
  void _eliminarRangoCasa(String elemento) {
    setState(() {
      _rangoCasasExpandido.remove(elemento);
      _rangoCasasController.text = _reconstruirTextoDesdeElementos(_rangoCasasExpandido);
      
      final cantidadEsperada = _numeroCasasController.text.isNotEmpty
          ? int.tryParse(_numeroCasasController.text)
          : null;
      
      _errorRangoCasas = _validarRangosEnTiempoReal(
        _rangoCasasController.text,
        cantidadEsperada,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
  }

  @override
  void dispose() {
    _numeroCasasController.dispose();
    _rangoCasasController.dispose();
    _numeroTorresController.dispose();
    _apartamentosPorTorreController.dispose();
    _numeracionController.dispose();
    _etiquetasTorresController.dispose();
    _rangoTorresController.dispose();
    super.dispose();
  }

  Future<void> _loadCondominioData() async {
    try {
      final condominio = await _firestoreService.getCondominioData(
        widget.condominioId,
      );

      if (mounted) {
        setState(() {
          _condominio = condominio;
          _tipoSeleccionado = condominio.tipoCondominio;
          _edificiosIguales = condominio.edificiosIguales ?? true;

          // Inicializar controladores con valores existentes
          _numeroCasasController.text =
              condominio.numeroCasas?.toString() ?? '';
          _rangoCasasController.text = condominio.rangoCasas ?? '';
          _numeroTorresController.text =
              condominio.numeroTorres?.toString() ?? '';
          _apartamentosPorTorreController.text =
              condominio.apartamentosPorTorre?.toString() ?? '';
          _numeracionController.text = condominio.numeracion ?? '';
          _etiquetasTorresController.text = condominio.etiquetasTorres ?? '';
          _rangoTorresController.text = condominio.rangoTorres ?? '';

          // Cargar configuraciones de edificios
          if (condominio.configuracionesEdificios != null) {
            _configuracionesEdificios = List.from(
              condominio.configuracionesEdificios!,
            );
          }

          // Expandir rangos existentes
          if (condominio.numeracion != null) {
            _numeracionExpandida = _expandirRangos(condominio.numeracion!);
          }
          if (condominio.etiquetasTorres != null) {
            _etiquetasExpandidas = _expandirRangos(condominio.etiquetasTorres!);
          }
          if (condominio.rangoCasas != null) {
            _rangoCasasExpandido = _expandirRangos(condominio.rangoCasas!);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _calcularTotalInmuebles() {
    if (_tipoSeleccionado == TipoCondominio.casas) {
      return int.tryParse(_numeroCasasController.text) ?? 0;
    } else if (_tipoSeleccionado == TipoCondominio.edificio) {
      int torres = int.tryParse(_numeroTorresController.text) ?? 0;
      int apartamentos =
          int.tryParse(_apartamentosPorTorreController.text) ?? 0;
      return torres * apartamentos;
    }
    return 0;
  }

  // ... existing code ...

  // Método para expandir rangos y elementos manuales
  List<String> _expandirRangos(String input) {
    List<String> resultado = [];

    if (input.trim().isEmpty) return resultado;

    try {
      // Limpiar espacios
      input = input.replaceAll(' ', '');

      // Dividir por comas
      List<String> partes = input.split(',');

      for (String parte in partes) {
        if (parte.contains('-')) {
          // Es un rango
          List<String> rango = parte.split('-');
          if (rango.length == 2) {
            String inicio = rango[0];
            String fin = rango[1];

            // Verificar si son números o letras
            if (RegExp(r'^[0-9]+$').hasMatch(inicio) &&
                RegExp(r'^[0-9]+$').hasMatch(fin)) {
              // Rango numérico
              int inicioNum = int.parse(inicio);
              int finNum = int.parse(fin);
              if (inicioNum <= finNum) {
                for (int i = inicioNum; i <= finNum; i++) {
                  resultado.add(i.toString());
                }
              }
            } else if (RegExp(r'^[A-Za-z]$').hasMatch(inicio) &&
                RegExp(r'^[A-Za-z]$').hasMatch(fin)) {
              // Rango de letras
              int inicioCode = inicio.toUpperCase().codeUnitAt(0);
              int finCode = fin.toUpperCase().codeUnitAt(0);
              if (inicioCode <= finCode) {
                for (int i = inicioCode; i <= finCode; i++) {
                  resultado.add(String.fromCharCode(i));
                }
              }
            }
          }
        } else {
          // Es un elemento manual
          if (parte.isNotEmpty) {
            resultado.add(parte);
          }
        }
      }
    } catch (e) {
      // En caso de error, devolver lista vacía
      return [];
    }

    return resultado;
  }

  // Validar entrada de rangos en tiempo real
  String? _validarRangosEnTiempoReal(String value, int? cantidadEsperada) {
    if (value.trim().isEmpty) return null;

    try {
      List<String> expandido = _expandirRangos(value);

      if (expandido.isEmpty && value.trim().isNotEmpty) {
        return 'Formato inválido';
      }

      // Verificar que no haya mezcla de letras y números
      bool tieneNumeros = expandido.any((e) => RegExp(r'^[0-9]+$').hasMatch(e));
      bool tieneLetras = expandido.any(
        (e) => RegExp(r'^[A-Za-z]+$').hasMatch(e),
      );

      if (tieneNumeros && tieneLetras) {
        return 'No se puede mezclar números y letras';
      }

      // Verificar cantidad si se especifica
      if (cantidadEsperada != null &&
          cantidadEsperada > 0 &&
          expandido.length != cantidadEsperada) {
        return 'Debe ingresar exactamente $cantidadEsperada elementos (actual: ${expandido.length})';
      }

      return null;
    } catch (e) {
      return 'Formato inválido';
    }
  }

  // Widget para mostrar elementos expandidos con opción de eliminar
  Widget _buildExpandedChips(
    List<String> elementos,
    Function(String) onDelete,
  ) {
    if (elementos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'Elementos generados (${elementos.length}):',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: elementos
                .map(
                  (elemento) => Chip(
                    label: Text(
                      elemento,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onDelete(elemento),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blue.shade300),
                    labelStyle: TextStyle(color: Colors.blue.shade800),
                    deleteIconColor: Colors.blue.shade600,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Método para reconstruir texto desde elementos expandidos (igual que en dialog_config_viviendas.dart)
  String _reconstruirTextoDesdeElementos(List<String> elementos) {
    if (elementos.isEmpty) return '';
    
    List<String> resultado = [];
    List<String> elementosOrdenados = List.from(elementos);
    
    // Separar números y letras
    List<int> numeros = [];
    List<String> letras = [];
    List<String> otros = [];
    
    for (String elemento in elementosOrdenados) {
      if (RegExp(r'^[0-9]+$').hasMatch(elemento)) {
        numeros.add(int.parse(elemento));
      } else if (RegExp(r'^[A-Za-z]$').hasMatch(elemento)) {
        letras.add(elemento.toUpperCase());
      } else {
        otros.add(elemento);
      }
    }
    
    // Procesar números
    if (numeros.isNotEmpty) {
      numeros.sort();
      resultado.addAll(_crearRangosNumericos(numeros));
    }
    
    // Procesar letras
    if (letras.isNotEmpty) {
      letras.sort();
      resultado.addAll(_crearRangosLetras(letras));
    }
    
    // Agregar otros elementos
    resultado.addAll(otros);
    
    return resultado.join(',');
  }

  // Métodos auxiliares para crear rangos (iguales que en dialog_config_viviendas.dart)
  List<String> _crearRangosNumericos(List<int> numeros) {
    List<String> resultado = [];
    int inicio = numeros[0];
    int fin = numeros[0];
    
    for (int i = 1; i < numeros.length; i++) {
      if (numeros[i] == fin + 1) {
        fin = numeros[i];
      } else {
        if (inicio == fin) {
          resultado.add(inicio.toString());
        } else {
          resultado.add('$inicio-$fin');
        }
        inicio = numeros[i];
        fin = numeros[i];
      }
    }
    
    if (inicio == fin) {
      resultado.add(inicio.toString());
    } else {
      resultado.add('$inicio-$fin');
    }
    
    return resultado;
  }

  List<String> _crearRangosLetras(List<String> letras) {
    List<String> resultado = [];
    String inicio = letras[0];
    String fin = letras[0];
    
    for (int i = 1; i < letras.length; i++) {
      if (letras[i].codeUnitAt(0) == fin.codeUnitAt(0) + 1) {
        fin = letras[i];
      } else {
        if (inicio == fin) {
          resultado.add(inicio);
        } else {
          resultado.add('$inicio-$fin');
        }
        inicio = letras[i];
        fin = letras[i];
      }
    }
    
    if (inicio == fin) {
      resultado.add(inicio);
    } else {
      resultado.add('$inicio-$fin');
    }
    
    return resultado;
  }

  // Método para agregar nueva configuración de edificio
  void _agregarConfiguracionEdificio() {
    showDialog(
      context: context,
      builder: (context) => ConfiguracionEdificioDialog(
        onSave: (configuracion) {
          setState(() {
            _configuracionesEdificios.add(configuracion);
          });
        },
      ),
    );
  }

  // Método para editar configuración de edificio
  void _editarConfiguracionEdificio(int index) {
    showDialog(
      context: context,
      builder: (context) => ConfiguracionEdificioDialog(
        configuracion: _configuracionesEdificios[index],
        onSave: (configuracion) {
          setState(() {
            _configuracionesEdificios[index] = configuracion;
          });
        },
      ),
    );
  }

  // Método para eliminar configuración de edificio
  void _eliminarConfiguracionEdificio(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Configuración'),
        content: Text(
          '¿Está seguro de eliminar la configuración "${_configuracionesEdificios[index].nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _configuracionesEdificios.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCondominioData() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar errores en tiempo real antes de guardar
    if (_errorNumeracion != null ||
        _errorEtiquetas != null ||
        _errorRangoCasas != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor corrija los errores antes de guardar'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Crear nuevo modelo con los datos actualizados
      final updatedCondominio = CondominioModel(
        id: _condominio!.id,
        nombre: _condominio!.nombre,
        direccion: _condominio!.direccion,
        fechaCreacion: _condominio!.fechaCreacion,
        pruebaActiva: _condominio!.pruebaActiva,
        fechaFinPrueba: _condominio!.fechaFinPrueba,
        tipoCondominio: _tipoSeleccionado,
        // Casas
        numeroCasas:
            (_tipoSeleccionado == TipoCondominio.casas ||
                    _tipoSeleccionado == TipoCondominio.mixto) &&
                _numeroCasasController.text.isNotEmpty
            ? int.tryParse(_numeroCasasController.text)
            : null,
        rangoCasas:
            (_tipoSeleccionado == TipoCondominio.casas ||
                _tipoSeleccionado == TipoCondominio.mixto)
            ? _rangoCasasController.text.isEmpty
                  ? null
                  : _rangoCasasController.text
            : null,
        // Edificios (compatibilidad hacia atrás)
        numeroTorres:
            _tipoSeleccionado == TipoCondominio.edificio &&
                _edificiosIguales &&
                _numeroTorresController.text.isNotEmpty
            ? int.tryParse(_numeroTorresController.text)
            : null,
        apartamentosPorTorre:
            _tipoSeleccionado == TipoCondominio.edificio &&
                _edificiosIguales &&
                _apartamentosPorTorreController.text.isNotEmpty
            ? int.tryParse(_apartamentosPorTorreController.text)
            : null,
        numeracion:
            _tipoSeleccionado == TipoCondominio.edificio && _edificiosIguales
            ? _numeracionController.text.isEmpty
                  ? null
                  : _numeracionController.text
            : null,
        etiquetasTorres:
            _tipoSeleccionado == TipoCondominio.edificio && _edificiosIguales
            ? _etiquetasTorresController.text.isEmpty
                  ? null
                  : _etiquetasTorresController.text
            : null,
        rangoTorres:
            _tipoSeleccionado == TipoCondominio.edificio && _edificiosIguales
            ? _rangoTorresController.text.isEmpty
                  ? null
                  : _rangoTorresController.text
            : null,
        // Nuevas propiedades
        edificiosIguales:
            (_tipoSeleccionado == TipoCondominio.edificio ||
                _tipoSeleccionado == TipoCondominio.mixto)
            ? _edificiosIguales
            : null,
        configuracionesEdificios:
            (_tipoSeleccionado == TipoCondominio.edificio &&
                    !_edificiosIguales) ||
                (_tipoSeleccionado == TipoCondominio.mixto &&
                    !_edificiosIguales)
            ? _configuracionesEdificios.isNotEmpty
                  ? _configuracionesEdificios
                  : null
            : null,
      );

      // Guardar en Firestore
      await _firestoreService.updateCondominioData(updatedCondominio);

      if (mounted) {
        setState(() {
          _condominio = updatedCondominio;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Configuración guardada correctamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Configuración de Viviendas',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando configuración...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Configuración de Viviendas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _saveCondominioData,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de tipo de condominio
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.home_work,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tipo de Condominio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<TipoCondominio>(
                        value: _tipoSeleccionado,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade500,
                              width: 2,
                            ),
                          ),
                          labelText: 'Tipo de condominio',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TipoCondominio.casas,
                            child: Row(
                              children: [
                                Icon(Icons.house, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Casas'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: TipoCondominio.edificio,
                            child: Row(
                              children: [
                                Icon(Icons.apartment, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Edificios'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: TipoCondominio.mixto,
                            child: Row(
                              children: [
                                Icon(Icons.location_city, color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Casas y Edificios'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoSeleccionado = value;
                            // Limpiar campos y errores cuando cambie el tipo
                            _numeracionExpandida.clear();
                            _etiquetasExpandidas.clear();
                            _rangoCasasExpandido.clear();
                            _errorNumeracion = null;
                            _errorEtiquetas = null;
                            _errorRangoCasas = null;
                            _edificiosIguales = true;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor seleccione un tipo de condominio';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sección de Casas
              if (_tipoSeleccionado == TipoCondominio.casas ||
                  _tipoSeleccionado == TipoCondominio.mixto)
                _buildCasasSection(),

              // Sección de Edificios
              if (_tipoSeleccionado == TipoCondominio.edificio ||
                  _tipoSeleccionado == TipoCondominio.mixto)
                _buildEdificiosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCasasSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.house,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuración de Casas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                TextFormField(
                  controller: _numeroCasasController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green.shade500,
                        width: 2,
                      ),
                    ),
                    labelText: 'Número de casas',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: Colors.green.shade600,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (_tipoSeleccionado == TipoCondominio.casas &&
                        (value == null || value.isEmpty)) {
                      return 'Este campo es requerido para casas';
                    }
                    if (value != null && value.isNotEmpty) {
                      final numero = int.tryParse(value);
                      if (numero == null || numero <= 0) {
                        return 'Debe ser un número mayor a 0';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rangoCasasController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green.shade500,
                        width: 2,
                      ),
                    ),
                    labelText: 'Numeración de casas',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(
                      Icons.format_list_numbered,
                      color: Colors.green.shade600,
                    ),
                    errorText: _errorRangoCasas,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _errorRangoCasas = _validarRangosEnTiempoReal(
                        value,
                        _numeroCasasController.text.isNotEmpty
                            ? int.tryParse(_numeroCasasController.text)
                            : null,
                      );
                      if (_errorRangoCasas == null) {
                        _rangoCasasExpandido = _expandirRangos(value);
                      } else {
                        _rangoCasasExpandido.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            _buildExpandedChips(_rangoCasasExpandido, _eliminarRangoCasa),
          ],
        ),
      ),
    );
  }

  Widget _buildEdificiosSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.apartment,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuración de Edificios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle para edificios iguales/diferentes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _edificiosIguales
                        ? Icons.content_copy
                        : Icons.dashboard_customize,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _edificiosIguales
                          ? 'Todos los edificios tienen la misma configuración'
                          : 'Cada edificio puede tener configuración diferente',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _edificiosIguales,
                    onChanged: (value) {
                      setState(() {
                        _edificiosIguales = value;
                        if (!value && _configuracionesEdificios.isEmpty) {
                          // Si cambia a diferentes, agregar una configuración por defecto
                          _configuracionesEdificios.add(
                            ConfiguracionEdificio(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              nombre: 'Edificio 1',
                              numeroTorres: 1,
                              apartamentosPorTorre: 1,
                            ),
                          );
                        }
                      });
                    },
                    activeColor: Colors.orange.shade600,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Configuración única (edificios iguales)
            if (_edificiosIguales) _buildConfiguracionUnicaEdificios(),

            // Configuraciones múltiples (edificios diferentes)
            if (!_edificiosIguales) _buildConfiguracionesMultiplesEdificios(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguracionUnicaEdificios() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _numeroTorresController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.shade500,
                      width: 2,
                    ),
                  ),
                  labelText: 'Número de torres',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(
                    Icons.business,
                    color: Colors.orange.shade600,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_tipoSeleccionado == TipoCondominio.edificio &&
                      _edificiosIguales &&
                      (value == null || value.isEmpty)) {
                    return 'Este campo es requerido';
                  }
                  if (value != null && value.isNotEmpty) {
                    final numero = int.tryParse(value);
                    if (numero == null || numero <= 0) {
                      return 'Debe ser un número mayor a 0';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    // Revalidar etiquetas cuando cambie el número de torres
                    final cantidadEsperada = int.tryParse(value);
                    _errorEtiquetas = _validarRangosEnTiempoReal(
                      _etiquetasTorresController.text,
                      cantidadEsperada,
                    );
                    if (_errorEtiquetas == null) {
                      _etiquetasExpandidas = _expandirRangos(
                        _etiquetasTorresController.text,
                      );
                    } else {
                      _etiquetasExpandidas.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _apartamentosPorTorreController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.shade500,
                      width: 2,
                    ),
                  ),
                  labelText: 'Dptos por torre',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: Icon(
                    Icons.door_front_door,
                    color: Colors.orange.shade600,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_tipoSeleccionado == TipoCondominio.edificio &&
                      _edificiosIguales &&
                      (value == null || value.isEmpty)) {
                    return 'Este campo es requerido';
                  }
                  if (value != null && value.isNotEmpty) {
                    final numero = int.tryParse(value);
                    if (numero == null || numero <= 0) {
                      return 'Debe ser un número mayor a 0';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    // Revalidar numeración cuando cambien los apartamentos
                    int? apartamentosPorTorre;
                    if (value.isNotEmpty) {
                      apartamentosPorTorre = int.tryParse(value);
                    }

                    _errorNumeracion = _validarRangosEnTiempoReal(
                      _numeracionController.text,
                      apartamentosPorTorre,
                    );
                    if (_errorNumeracion == null) {
                      _numeracionExpandida = _expandirRangos(
                        _numeracionController.text,
                      );
                    } else {
                      _numeracionExpandida.clear();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _etiquetasTorresController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
            ),
            labelText: 'Etiquetas de torres',
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: Icon(Icons.label, color: Colors.orange.shade600),
            errorText: _errorEtiquetas,
            helperText: 'Ej: A-D, 1-4, Torre1,Torre2',
          ),
          onChanged: (value) {
            setState(() {
              final cantidadEsperada = _numeroTorresController.text.isNotEmpty
                  ? int.tryParse(_numeroTorresController.text)
                  : null;

              _errorEtiquetas = _validarRangosEnTiempoReal(
                value,
                cantidadEsperada,
              );
              if (_errorEtiquetas == null) {
                _etiquetasExpandidas = _expandirRangos(value);
              } else {
                _etiquetasExpandidas.clear();
              }
            });
          },
        ),
        _buildExpandedChips(_etiquetasExpandidas, _eliminarEtiqueta),
        const SizedBox(height: 16),
        TextFormField(
          controller: _numeracionController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
            ),
            labelText: 'Numeración de Departamentos',
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: Icon(
              Icons.format_list_numbered,
              color: Colors.orange.shade600,
            ),
            errorText: _errorNumeracion,
            helperText: 'Ej: 101-110, A-F, 1,3,5',
          ),
          onChanged: (value) {
            setState(() {
              // Cambio principal: usar solo apartamentos por torre, no el total
              int? apartamentosPorTorre;
              if (_apartamentosPorTorreController.text.isNotEmpty) {
                apartamentosPorTorre = int.tryParse(
                  _apartamentosPorTorreController.text,
                );
              }

              _errorNumeracion = _validarRangosEnTiempoReal(
                value,
                apartamentosPorTorre,
              );
              if (_errorNumeracion == null) {
                _numeracionExpandida = _expandirRangos(value);
              } else {
                _numeracionExpandida.clear();
              }
            });
          },
        ),
        _buildExpandedChips(_numeracionExpandida, _eliminarNumeracion),
      ],
    );
  }

  Widget _buildConfiguracionesMultiplesEdificios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configuraciones de Edificios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _agregarConfiguracionEdificio,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_configuracionesEdificios.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.apartment_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay configuraciones de edificios',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agregue al menos una configuración',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _configuracionesEdificios.length,
            itemBuilder: (context, index) {
              final config = _configuracionesEdificios[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade600,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    config.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${config.numeroTorres} torres • ${config.apartamentosPorTorre} aptos/torre • Total: ${config.totalApartamentos}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editarConfiguracionEdificio(index),
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.orange.shade600,
                      ),
                      IconButton(
                        onPressed: () => _eliminarConfiguracionEdificio(index),
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red.shade600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
