// Dialog para configurar edificios individuales
import 'package:comunidad_activa/models/condominio_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfiguracionEdificioDialog extends StatefulWidget {
  final ConfiguracionEdificio? configuracion;
  final Function(ConfiguracionEdificio) onSave;

  const ConfiguracionEdificioDialog({this.configuracion, required this.onSave});

  @override
  State<ConfiguracionEdificioDialog> createState() =>
      _ConfiguracionEdificioDialogState();
}

class _ConfiguracionEdificioDialogState
    extends State<ConfiguracionEdificioDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _numeroTorresController;
  late TextEditingController _apartamentosPorTorreController;
  late TextEditingController _numeracionController;
  late TextEditingController _etiquetasTorresController;
  late TextEditingController _rangoTorresController;

  // Variables para validaciones en tiempo real y expansión
  List<String> _numeracionExpandida = [];
  List<String> _etiquetasExpandidas = [];
  List<String> _rangoTorresExpandido = [];
  String? _errorNumeracion;
  String? _errorEtiquetas;
  String? _errorRangoTorres;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.configuracion?.nombre ?? '',
    );
    _numeroTorresController = TextEditingController(
      text: widget.configuracion?.numeroTorres.toString() ?? '',
    );
    _apartamentosPorTorreController = TextEditingController(
      text: widget.configuracion?.apartamentosPorTorre.toString() ?? '',
    );
    _numeracionController = TextEditingController(
      text: widget.configuracion?.numeracion ?? '',
    );
    _etiquetasTorresController = TextEditingController(
      text: widget.configuracion?.etiquetasTorres ?? '',
    );
    _rangoTorresController = TextEditingController(
      text: widget.configuracion?.rangoTorres ?? '',
    );

    // Expandir rangos existentes
    if (widget.configuracion != null) {
      if (widget.configuracion!.numeracion != null) {
        _numeracionExpandida = _expandirRangos(
          widget.configuracion!.numeracion!,
        );
      }
      if (widget.configuracion!.etiquetasTorres != null) {
        _etiquetasExpandidas = _expandirRangos(
          widget.configuracion!.etiquetasTorres!,
        );
      }
      if (widget.configuracion!.rangoTorres != null) {
        _rangoTorresExpandido = _expandirRangos(
          widget.configuracion!.rangoTorres!,
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroTorresController.dispose();
    _apartamentosPorTorreController.dispose();
    _numeracionController.dispose();
    _etiquetasTorresController.dispose();
    _rangoTorresController.dispose();
    super.dispose();
  }

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

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final configuracion = ConfiguracionEdificio(
        id:
            widget.configuracion?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreController.text,
        numeroTorres: int.parse(_numeroTorresController.text),
        apartamentosPorTorre: int.parse(_apartamentosPorTorreController.text),
        numeracion: _numeracionController.text.isEmpty
            ? null
            : _numeracionController.text,
        etiquetasTorres: _etiquetasTorresController.text.isEmpty
            ? null
            : _etiquetasTorresController.text,
        rangoTorres: _rangoTorresController.text.isEmpty
            ? null
            : _rangoTorresController.text,
      );

      widget.onSave(configuracion);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.configuracion == null
                          ? 'Nueva Configuración'
                          : 'Editar Configuración',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de la configuración
                      TextFormField(
                        controller: _nombreController,
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
                          labelText: 'Nombre de la configuración',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(
                            Icons.label,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Número de torres y apartamentos por torre
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numeroTorresController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.orange.shade500,
                                    width: 2,
                                  ),
                                ),
                                labelText: 'Número de torres',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                prefixIcon: Icon(
                                  Icons.business,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final numero = int.tryParse(value);
                                if (numero == null || numero <= 0) {
                                  return 'Debe ser > 0';
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
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.orange.shade500,
                                    width: 2,
                                  ),
                                ),
                                labelText: 'Dptos por torre',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                prefixIcon: Icon(
                                  Icons.home,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final numero = int.tryParse(value);
                                if (numero == null || numero <= 0) {
                                  return 'Debe ser > 0';
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
                      const SizedBox(height: 20),
                      // Etiquetas de torres
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
                            borderSide: BorderSide(
                              color: Colors.orange.shade500,
                              width: 2,
                            ),
                          ),
                          labelText: 'Etiquetas de torres',
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(
                            Icons.label,
                            color: Colors.orange.shade600,
                          ),
                          errorText: _errorEtiquetas,
                          helperText: 'Ej: A-D, 1-4, Torre1,Torre2',
                        ),
                        onChanged: (value) {
                          setState(() {
                            final cantidadEsperada =
                                _numeroTorresController.text.isNotEmpty
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
                      _buildExpandedChips(_etiquetasExpandidas, (elemento) {
                        _eliminarEtiqueta(elemento);
                      }),

                      const SizedBox(height: 20),
                      // Numeración de apartamentos
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
                            borderSide: BorderSide(
                              color: Colors.orange.shade500,
                              width: 2,
                            ),
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
                            if (_apartamentosPorTorreController
                                .text
                                .isNotEmpty) {
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
                      _buildExpandedChips(_numeracionExpandida, (elemento) {
                        _eliminarNumeracion(elemento);
                      }),

                      const SizedBox(height: 20),

                      // Rango de torres
                      // TextFormField(
                      //   controller: _rangoTorresController,
                      //   decoration: InputDecoration(
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: Colors.grey.shade300),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: Colors.grey.shade300),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //       borderSide: BorderSide(color: Colors.orange.shade500, width: 2),
                      //     ),
                      //     labelText: 'Rango de torres',
                      //     labelStyle: TextStyle(color: Colors.grey.shade600),
                      //     filled: true,
                      //     fillColor: Colors.grey.shade50,
                      //     prefixIcon: Icon(Icons.domain, color: Colors.orange.shade600),
                      //     errorText: _errorRangoTorres,
                      //     helperText: 'Ej: 1-4, A-D',
                      //   ),
                      //   onChanged: (value) {
                      //     setState(() {
                      //       final cantidadEsperada = _numeroTorresController.text.isNotEmpty
                      //           ? int.tryParse(_numeroTorresController.text)
                      //           : null;

                      //       _errorRangoTorres = _validarRangosEnTiempoReal(value, cantidadEsperada);
                      //       if (_errorRangoTorres == null) {
                      //         _rangoTorresExpandido = _expandirRangos(value);
                      //       } else {
                      //         _rangoTorresExpandido.clear();
                      //       }
                      //     });
                      //   },
                      // ),
                      _buildExpandedChips(_rangoTorresExpandido, (elemento) {
                        _eliminarRangoTorre(elemento);
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Guardar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para eliminar elemento de etiquetas y recalcular
  void _eliminarEtiqueta(String elemento) {
    setState(() {
      _etiquetasExpandidas.remove(elemento);
      // Reconstruir el texto del controller sin el elemento eliminado
      _etiquetasTorresController.text = _reconstruirTextoDesdeElementos(_etiquetasExpandidas);
      
      // Recalcular validación
      final cantidadEsperada = _numeroTorresController.text.isNotEmpty
          ? int.tryParse(_numeroTorresController.text)
          : null;
      
      _errorEtiquetas = _validarRangosEnTiempoReal(
        _etiquetasTorresController.text,
        cantidadEsperada,
      );
    });
  }

  // Método para eliminar elemento de numeración y recalcular
  void _eliminarNumeracion(String elemento) {
    setState(() {
      _numeracionExpandida.remove(elemento);
      // Reconstruir el texto del controller sin el elemento eliminado
      _numeracionController.text = _reconstruirTextoDesdeElementos(_numeracionExpandida);
      
      // Recalcular validación
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

  // Método para eliminar elemento de rango torres y recalcular
  void _eliminarRangoTorre(String elemento) {
    setState(() {
      _rangoTorresExpandido.remove(elemento);
      // Reconstruir el texto del controller sin el elemento eliminado
      _rangoTorresController.text = _reconstruirTextoDesdeElementos(_rangoTorresExpandido);
      
      // Recalcular validación
      final cantidadEsperada = _numeroTorresController.text.isNotEmpty
          ? int.tryParse(_numeroTorresController.text)
          : null;
      
      _errorRangoTorres = _validarRangosEnTiempoReal(
        _rangoTorresController.text,
        cantidadEsperada,
      );
    });
  }

  // Método para reconstruir texto desde elementos expandidos
  String _reconstruirTextoDesdeElementos(List<String> elementos) {
    if (elementos.isEmpty) return '';
    
    // Intentar crear rangos cuando sea posible
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

  // Método auxiliar para crear rangos numéricos
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
    
    // Agregar el último rango
    if (inicio == fin) {
      resultado.add(inicio.toString());
    } else {
      resultado.add('$inicio-$fin');
    }
    
    return resultado;
  }

  // Método auxiliar para crear rangos de letras
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
    
    // Agregar el último rango
    if (inicio == fin) {
      resultado.add(inicio);
    } else {
      resultado.add('$inicio-$fin');
    }
    
    return resultado;
  }
}
