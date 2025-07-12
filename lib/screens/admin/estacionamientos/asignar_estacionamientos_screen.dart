import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../models/estacionamiento_model.dart';

class AsignarEstacionamientosScreen extends StatefulWidget {
  final String condominioId;

  const AsignarEstacionamientosScreen({super.key, required this.condominioId});

  @override
  State<AsignarEstacionamientosScreen> createState() => _AsignarEstacionamientosScreenState();
}

class _AsignarEstacionamientosScreenState extends State<AsignarEstacionamientosScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  List<EstacionamientoModel> _estacionamientosDisponibles = [];
  List<EstacionamientoModel> _todosLosEstacionamientos = [];
  Map<String, List<String>> _viviendasPorTipo = {};
  Map<String, TextEditingController> _controllers = {};
  Map<String, bool> _gruposExpandidos = {};
  Map<String, String> _erroresVivienda = {};
  Map<String, List<String>> _asignacionesOriginales = {};
  bool _isLoading = true;
  bool _mostrarEstacionamientosDisponibles = false;
  bool _haycambiosPendientes = false;
  int _currentGroup = 0;
  final int _itemsPerGroup = 10;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar todos los estacionamientos
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(widget.condominioId);
      // Filtrar solo estacionamientos de residentes (no de visitas)
      final estacionamientosResidentes = estacionamientos.where((e) => !e.estVisita).toList();
      final disponibles = estacionamientosResidentes.where((e) => e.viviendaAsignada == null || e.viviendaAsignada!.isEmpty).toList();
      
      // Cargar viviendas agrupadas por tipo
      final viviendas = await _estacionamientoService.obtenerTodasLasViviendas(widget.condominioId);
      
      // Crear mapa de asignaciones actuales por vivienda (solo estacionamientos de residentes)
      final asignacionesActuales = <String, List<String>>{};
      for (var estacionamiento in estacionamientosResidentes) {
        if (estacionamiento.viviendaAsignada != null && estacionamiento.viviendaAsignada!.isNotEmpty) {
          final vivienda = estacionamiento.viviendaAsignada!;
          if (!asignacionesActuales.containsKey(vivienda)) {
            asignacionesActuales[vivienda] = [];
          }
          asignacionesActuales[vivienda]!.add(estacionamiento.nroEstacionamiento);
        }
      }
      
      if (mounted) {
        setState(() {
          _todosLosEstacionamientos = estacionamientosResidentes;
          _estacionamientosDisponibles = disponibles;
          _viviendasPorTipo = viviendas;
          _asignacionesOriginales = Map.from(asignacionesActuales);
          _isLoading = false;
          
          // Inicializar controladores para cada vivienda
          for (var tipo in _viviendasPorTipo.keys) {
            _gruposExpandidos[tipo] = false;
            for (var vivienda in _viviendasPorTipo[tipo]!) {
              final asignaciones = asignacionesActuales[vivienda] ?? [];
              _controllers[vivienda] = TextEditingController(
                text: asignaciones.join(', ')
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _validarEntrada(String vivienda, String numerosTexto) {
    if (numerosTexto.trim().isEmpty) {
      setState(() {
        _erroresVivienda.remove(vivienda);
        _verificarCambiosPendientes();
      });
      return;
    }

    // Separar números por comas y limpiar espacios
    final numeros = numerosTexto.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    final numerosInvalidos = <String>[];

    for (var numero in numeros) {
      // Verificar si el número existe en todos los estacionamientos
      final existe = _todosLosEstacionamientos.any((e) => e.nroEstacionamiento == numero);
      if (!existe) {
        numerosInvalidos.add(numero);
        continue;
      }
      
      // Verificar si está disponible o ya asignado a esta vivienda
      final estacionamiento = _todosLosEstacionamientos.firstWhere((e) => e.nroEstacionamiento == numero);
      final yaAsignadoAOtraVivienda = estacionamiento.viviendaAsignada != null && 
                                     estacionamiento.viviendaAsignada!.isNotEmpty && 
                                     estacionamiento.viviendaAsignada != vivienda;
      
      if (yaAsignadoAOtraVivienda) {
        numerosInvalidos.add(numero);
      }
    }

    setState(() {
      if (numerosInvalidos.isNotEmpty) {
        _erroresVivienda[vivienda] = 'Números no disponibles: ${numerosInvalidos.join(', ')}';
      } else {
        _erroresVivienda.remove(vivienda);
      }
      _verificarCambiosPendientes();
    });
  }

  void _verificarCambiosPendientes() {
    bool hayCambios = false;
    
    for (var vivienda in _controllers.keys) {
      final textoActual = _controllers[vivienda]!.text.trim();
      final asignacionesOriginales = _asignacionesOriginales[vivienda] ?? [];
      final textoOriginal = asignacionesOriginales.join(', ');
      
      if (textoActual != textoOriginal) {
        hayCambios = true;
        break;
      }
    }
    
    _haycambiosPendientes = hayCambios;
  }

  Future<void> _guardarTodosLosCambios() async {
    if (_erroresVivienda.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija los errores antes de guardar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Primero, desasignar todos los estacionamientos que ya no están en los controladores
      for (var vivienda in _asignacionesOriginales.keys) {
        final asignacionesOriginales = _asignacionesOriginales[vivienda] ?? [];
        for (var numero in asignacionesOriginales) {
          await _estacionamientoService.asignarEstacionamientoAVivienda(
            widget.condominioId,
            numero,
            '', // Desasignar
          );
        }
      }

      // Luego, asignar según los valores actuales en los controladores
      for (var vivienda in _controllers.keys) {
        final textoActual = _controllers[vivienda]!.text.trim();
        if (textoActual.isNotEmpty) {
          final numeros = textoActual.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
          for (var numero in numeros) {
            await _estacionamientoService.asignarEstacionamientoAVivienda(
              widget.condominioId,
              numero,
              vivienda,
            );
          }
        }
      }

      // Recargar datos para reflejar los cambios
      await _cargarDatos();
      
      setState(() {
        _haycambiosPendientes = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignaciones guardadas exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Estacionamientos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_haycambiosPendientes)
            IconButton(
              onPressed: _isLoading ? null : _guardarTodosLosCambios,
              icon: const Icon(Icons.save),
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instrucciones
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Instrucciones de uso',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Los estacionamientos disponibles se muestran arriba\n'
                            '• Expanda cada grupo de viviendas para ver las opciones\n'
                            '• Ingrese el número de estacionamiento junto a cada vivienda\n'
                            '• Para asignar múltiples estacionamientos, separe los números con comas (ej: 1,5,10)\n'
                            '• Los números inválidos se mostrarán en rojo\n'
                            '• No todas las viviendas necesitan tener estacionamiento asignado',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Estacionamientos disponibles con icono de visibilidad
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Estacionamientos de Residentes Disponibles (${_estacionamientosDisponibles.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _mostrarEstacionamientosDisponibles = !_mostrarEstacionamientosDisponibles;
                          });
                        },
                        icon: Icon(
                          _mostrarEstacionamientosDisponibles 
                              ? Icons.visibility_off 
                              : Icons.visibility,
                          color: Colors.blue,
                        ),
                        tooltip: _mostrarEstacionamientosDisponibles 
                            ? 'Ocultar estacionamientos' 
                            : 'Mostrar estacionamientos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_mostrarEstacionamientosDisponibles) ...[
                    if (_estacionamientosDisponibles.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay estacionamientos de residentes disponibles para asignar',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      // Barra de grupos
                      if (_estacionamientosDisponibles.length > _itemsPerGroup) ...[
                        Container(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (_estacionamientosDisponibles.length / _itemsPerGroup).ceil(),
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentGroup;
                              final groupStart = index * _itemsPerGroup + 1;
                              final groupEnd = ((index + 1) * _itemsPerGroup).clamp(0, _estacionamientosDisponibles.length);
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentGroup = index;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.blue[700] : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? Colors.blue[900]! : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: Text(
                                      'Grupo ${index + 1} ($groupStart-$groupEnd)',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Estacionamientos del grupo actual
                      Builder(
                        builder: (context) {
                          final startIndex = _currentGroup * _itemsPerGroup;
                          final endIndex = (startIndex + _itemsPerGroup).clamp(0, _estacionamientosDisponibles.length);
                          final currentGroupItems = _estacionamientosDisponibles.sublist(startIndex, endIndex);
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: currentGroupItems.map((estacionamiento) {
                              return Chip(
                                label: Text(
                                  estacionamiento.nroEstacionamiento,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.green,
                                side: BorderSide.none,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Lista de viviendas agrupadas
                  const Text(
                    'Viviendas del Condominio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._viviendasPorTipo.entries.map((entry) {
                    final tipo = entry.key;
                    final viviendas = entry.value;
                    final isExpanded = _gruposExpandidos[tipo] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              tipo.toLowerCase().contains('casa') 
                                  ? Icons.home 
                                  : Icons.apartment,
                              color: Colors.blue,
                            ),
                            title: Text(
                              '$tipo (${viviendas.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                _gruposExpandidos[tipo] = !isExpanded;
                              });
                            },
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            ...viviendas.map((vivienda) {
                              final controller = _controllers[vivienda]!;
                              final hasError = _erroresVivienda.containsKey(vivienda);
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        vivienda,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: controller,
                                            decoration: InputDecoration(
                                              hintText: 'Ej: 1,5,10',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              errorBorder: hasError
                                                  ? OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: const BorderSide(color: Colors.red),
                                                    )
                                                  : null,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            keyboardType: TextInputType.text,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9,\s]'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              _validarEntrada(vivienda, value);
                                            },
                                          ),
                                          if (hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                _erroresVivienda[vivienda]!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}