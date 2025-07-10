import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/estacionamiento_service.dart';

class ModalConfigurarEstacionamientos extends StatefulWidget {
  final String condominioId;
  final bool esVisita;
  final List<String> numeracionActual;
  final VoidCallback onConfiguracionGuardada;

  const ModalConfigurarEstacionamientos({
    super.key,
    required this.condominioId,
    required this.esVisita,
    required this.numeracionActual,
    required this.onConfiguracionGuardada,
  });

  @override
  State<ModalConfigurarEstacionamientos> createState() =>
      _ModalConfigurarEstacionamientosState();
}

class _ModalConfigurarEstacionamientosState
    extends State<ModalConfigurarEstacionamientos> {
  final _formKey = GlobalKey<FormState>();
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _numeracionController = TextEditingController();
  
  List<String> _elementosExpandidos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.numeracionActual.isNotEmpty) {
      _totalController.text = widget.numeracionActual.length.toString();
      _numeracionController.text = _reconstruirTextoDesdeElementos(widget.numeracionActual);
      _elementosExpandidos = List.from(widget.numeracionActual);
    }
  }

  @override
  void dispose() {
    _totalController.dispose();
    _numeracionController.dispose();
    super.dispose();
  }

  // Expandir rangos de numeración (similar a la lógica de viviendas)
  List<String> _expandirRangos(String input) {
    if (input.trim().isEmpty) return [];
    
    List<String> resultado = [];
    List<String> partes = input.split(',');
    
    for (String parte in partes) {
      parte = parte.trim();
      if (parte.isEmpty) continue;
      
      if (parte.contains('-')) {
        List<String> rango = parte.split('-');
        if (rango.length == 2) {
          String inicio = rango[0].trim();
          String fin = rango[1].trim();
          
          // Verificar si son números
          if (RegExp(r'^[0-9]+$').hasMatch(inicio) && RegExp(r'^[0-9]+$').hasMatch(fin)) {
            int inicioNum = int.parse(inicio);
            int finNum = int.parse(fin);
            
            for (int i = inicioNum; i <= finNum; i++) {
              resultado.add(i.toString());
            }
          }
          // Verificar si son letras
          else if (RegExp(r'^[A-Za-z]+$').hasMatch(inicio) && RegExp(r'^[A-Za-z]+$').hasMatch(fin)) {
            int inicioCode = inicio.toUpperCase().codeUnitAt(0);
            int finCode = fin.toUpperCase().codeUnitAt(0);
            
            for (int i = inicioCode; i <= finCode; i++) {
              resultado.add(String.fromCharCode(i));
            }
          }
        }
      } else {
        resultado.add(parte);
      }
    }
    
    return resultado;
  }

  // Reconstruir texto desde elementos expandidos
  String _reconstruirTextoDesdeElementos(List<String> elementos) {
    if (elementos.isEmpty) return '';
    
    List<String> rangos = [];
    List<String> elementosOrdenados = List.from(elementos);
    
    // Separar números y letras
    List<int> numeros = [];
    List<String> letras = [];
    
    for (String elemento in elementosOrdenados) {
      if (RegExp(r'^[0-9]+$').hasMatch(elemento)) {
        numeros.add(int.parse(elemento));
      } else {
        letras.add(elemento);
      }
    }
    
    // Procesar números
    if (numeros.isNotEmpty) {
      numeros.sort();
      rangos.addAll(_crearRangosNumeros(numeros));
    }
    
    // Procesar letras
    if (letras.isNotEmpty) {
      letras.sort();
      rangos.addAll(_crearRangosLetras(letras));
    }
    
    return rangos.join(',');
  }

  List<String> _crearRangosNumeros(List<int> numeros) {
    List<String> rangos = [];
    int inicio = numeros[0];
    int anterior = numeros[0];
    
    for (int i = 1; i < numeros.length; i++) {
      if (numeros[i] != anterior + 1) {
        if (inicio == anterior) {
          rangos.add(inicio.toString());
        } else {
          rangos.add('$inicio-$anterior');
        }
        inicio = numeros[i];
      }
      anterior = numeros[i];
    }
    
    if (inicio == anterior) {
      rangos.add(inicio.toString());
    } else {
      rangos.add('$inicio-$anterior');
    }
    
    return rangos;
  }

  List<String> _crearRangosLetras(List<String> letras) {
    List<String> rangos = [];
    String inicio = letras[0];
    String anterior = letras[0];
    
    for (int i = 1; i < letras.length; i++) {
      if (letras[i].codeUnitAt(0) != anterior.codeUnitAt(0) + 1) {
        if (inicio == anterior) {
          rangos.add(inicio);
        } else {
          rangos.add('$inicio-$anterior');
        }
        inicio = letras[i];
      }
      anterior = letras[i];
    }
    
    if (inicio == anterior) {
      rangos.add(inicio);
    } else {
      rangos.add('$inicio-$anterior');
    }
    
    return rangos;
  }

  void _validarRangosEnTiempoReal() {
    setState(() {
      try {
        _elementosExpandidos = _expandirRangos(_numeracionController.text);
      } catch (e) {
        _elementosExpandidos = [];
      }
    });
  }

  String? _validarNumeracion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese la numeración';
    }

    int? cantidadEsperada;
    if (_totalController.text.isNotEmpty) {
      cantidadEsperada = int.tryParse(_totalController.text);
    }

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

  void _eliminarElemento(String elemento) {
    setState(() {
      _elementosExpandidos.remove(elemento);
      _numeracionController.text = _reconstruirTextoDesdeElementos(_elementosExpandidos);
    });
  }

  Widget _buildExpandedChips() {
    if (_elementosExpandidos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 16, color: Colors.indigo.shade700),
              const SizedBox(width: 6),
              Text(
                'Estacionamientos generados (${_elementosExpandidos.length}):',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _elementosExpandidos
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
                    onDeleted: () => _eliminarElemento(elemento),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.indigo.shade300),
                    labelStyle: TextStyle(color: Colors.indigo.shade800),
                    deleteIconColor: Colors.indigo.shade600,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_elementosExpandidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe configurar al menos un estacionamiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _estacionamientoService.crearEstacionamientos(
        widget.condominioId,
        _elementosExpandidos,
        esVisita: widget.esVisita,
      );

      if (success) {
        widget.onConfiguracionGuardada();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.esVisita
                    ? 'Estacionamientos de visitas configurados correctamente'
                    : 'Estacionamientos configurados correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error al guardar la configuración');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  colors: widget.esVisita
                      ? [Colors.purple.shade600, Colors.purple.shade700]
                      : [Colors.indigo.shade600, Colors.indigo.shade700],
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
                    child: Icon(
                      widget.esVisita ? Icons.car_rental : Icons.local_parking,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.esVisita
                          ? 'Configurar Estacionamientos de Visitas'
                          : 'Configurar Estacionamientos',
                      style: const TextStyle(
                        fontSize: 18,
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
                      // Campo de total
                      TextFormField(
                        controller: _totalController,
                        decoration: InputDecoration(
                          labelText: widget.esVisita
                              ? 'Total de estacionamientos de visitas'
                              : 'Total de estacionamientos',
                          hintText: 'Ej: 50',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el total de estacionamientos';
                          }
                          final total = int.tryParse(value);
                          if (total == null || total <= 0) {
                            return 'Ingrese un número válido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campo de numeración
                      TextFormField(
                        controller: _numeracionController,
                        decoration: InputDecoration(
                          labelText: 'Numeración de estacionamientos',
                          hintText: 'Ej: 101-110,112 o A-F,H',
                          prefixIcon: const Icon(Icons.format_list_numbered),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          helperText: 'Use rangos (1-10) o valores separados por comas (1,3,5)',
                          helperMaxLines: 2,
                        ),
                        onChanged: (_) => _validarRangosEnTiempoReal(),
                        validator: _validarNumeracion,
                      ),
                      
                      // Mostrar elementos expandidos
                      _buildExpandedChips(),
                      
                      const SizedBox(height: 24),
                      
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _guardarConfiguracion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.esVisita
                                    ? Colors.purple.shade600
                                    : Colors.indigo.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}