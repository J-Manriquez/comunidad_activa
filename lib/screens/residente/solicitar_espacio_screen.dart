import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/espacio_comun_model.dart';
import '../../models/reserva_model.dart';
import '../../models/residente_model.dart';
import '../../services/espacios_comunes_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/image_display_widget.dart';
import '../../widgets/image_carousel_widget.dart';

class SolicitarEspacioScreen extends StatefulWidget {
  final UserModel currentUser;

  const SolicitarEspacioScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SolicitarEspacioScreen> createState() => _SolicitarEspacioScreenState();
}

class _SolicitarEspacioScreenState extends State<SolicitarEspacioScreen> {
  final EspaciosComunesService _espaciosComunesService =
      EspaciosComunesService();
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _cantidadPersonasController = TextEditingController();

  List<EspacioComunModel> _espaciosDisponibles = [];
  EspacioComunModel? _espacioSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicioSeleccionada;
  List<ReservaModel> _reservasDelDia = [];
  bool _isLoading = false;
  bool _mostrandoHorarios = false;
  ResidenteModel? _residenteData;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    await Future.wait([
      _cargarEspaciosDisponibles(),
      _cargarDatosResidente(),
    ]);
  }

  Future<void> _cargarDatosResidente() async {
    try {
      final residente = await _firestoreService.getResidenteData(widget.currentUser.uid);
      setState(() {
        _residenteData = residente;
      });
    } catch (e) {
      print('Error al cargar datos del residente: $e');
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _cantidadPersonasController.dispose();
    super.dispose();
  }

  Future<void> _cargarEspaciosDisponibles() async {
    try {
      print('🚀 [DEBUG] Iniciando _cargarEspaciosDisponibles');
      print('👤 [DEBUG] Usuario actual: ${widget.currentUser.nombre}');
      print('🏢 [DEBUG] CondominioId: ${widget.currentUser.condominioId}');
      
      setState(() {
        _isLoading = true;
      });

      print('📞 [DEBUG] Llamando a obtenerEspaciosComunes...');
      final espacios = await _espaciosComunesService
          .obtenerEspaciosComunes(widget.currentUser.condominioId!);

      print('📦 [DEBUG] Espacios recibidos del servicio: ${espacios.length}');
      for (final espacio in espacios) {
        print('🏠 [DEBUG] Espacio recibido: ${espacio.nombre}, Estado: ${espacio.estado}');
      }

      print('🔍 [DEBUG] Filtrando espacios activos...');
       for (final espacio in espacios) {
         print('🔍 [DEBUG] Verificando espacio: ${espacio.nombre}, estado: "${espacio.estado}"');
       }
       
       final espaciosActivos = espacios.where((e) => e.estado.toLowerCase() == 'activo').toList();
       print('✅ [DEBUG] Espacios activos filtrados: ${espaciosActivos.length}');
       
       for (final espacio in espaciosActivos) {
         print('✅ [DEBUG] Espacio activo: ${espacio.nombre}');
       }
      
      setState(() {
        _espaciosDisponibles = espaciosActivos;
        _isLoading = false;
      });
      
      print('🎯 [DEBUG] Estado actualizado - espaciosDisponibles: ${_espaciosDisponibles.length}');
    } catch (e) {
      print('💥 [DEBUG] Error en _cargarEspaciosDisponibles: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar espacios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _horariosOcupados = [];

  Future<void> _verificarDisponibilidad() async {
    if (_espacioSeleccionado == null || _fechaSeleccionada == null) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _mostrandoHorarios = false;
      });

      final horariosOcupados = await _espaciosComunesService
          .obtenerHorariosOcupados(
              condominioId: widget.currentUser.condominioId!,
              espacioId: _espacioSeleccionado!.id,
              fecha: _fechaSeleccionada!);

      setState(() {
        _horariosOcupados = horariosOcupados;
        _mostrandoHorarios = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar disponibilidad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _esHorarioDisponible(TimeOfDay horaInicio) {
    if (_espacioSeleccionado == null) return false;

    final tiempoUso = int.tryParse(_espacioSeleccionado!.tiempoUso) ?? 1;
    final horaFin = TimeOfDay(
      hour: (horaInicio.hour + tiempoUso) % 24,
      minute: horaInicio.minute,
    );

    for (final horarioOcupado in _horariosOcupados) {
      final reservaInicio = _parseTimeOfDay(horarioOcupado['horaInicio']);
      final reservaFin = _parseTimeOfDay(horarioOcupado['horaFin']);

      if (_horariosSeSuperponen(horaInicio, horaFin, reservaInicio, reservaFin)) {
        return false;
      }
    }

    return true;
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _horariosSeSuperponen(
      TimeOfDay inicio1, TimeOfDay fin1, TimeOfDay inicio2, TimeOfDay fin2) {
    final minutos1Inicio = inicio1.hour * 60 + inicio1.minute;
    final minutos1Fin = fin1.hour * 60 + fin1.minute;
    final minutos2Inicio = inicio2.hour * 60 + inicio2.minute;
    final minutos2Fin = fin2.hour * 60 + fin2.minute;

    return minutos1Inicio < minutos2Fin && minutos1Fin > minutos2Inicio;
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate() ||
        _espacioSeleccionado == null ||
        _fechaSeleccionada == null ||
        _horaInicioSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_esHorarioDisponible(_horaInicioSeleccionada!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El horario seleccionado no está disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final tiempoUso = int.tryParse(_espacioSeleccionado!.tiempoUso) ?? 1;
      final horaFin = TimeOfDay(
        hour: (_horaInicioSeleccionada!.hour + tiempoUso) % 24,
        minute: _horaInicioSeleccionada!.minute,
      );

      await _espaciosComunesService.crearReservaResidente(
        condominioId: widget.currentUser.condominioId!,
        espacioId: _espacioSeleccionado!.id,
        residenteId: widget.currentUser.uid,
        nombreResidente: widget.currentUser.nombre,
        nombreEspacio: _espacioSeleccionado!.nombre,
        fechaUso: _fechaSeleccionada!,
        horaInicio: '${_horaInicioSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaInicioSeleccionada!.minute.toString().padLeft(2, '0')}',
        horaFin: '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}',
        motivo: _motivoController.text.trim(),
        cantidadPersonas: int.parse(_cantidadPersonasController.text.trim()),
        vivienda: _residenteData?.descripcionVivienda ?? 'Sin vivienda asignada'
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [DEBUG] Build ejecutándose - _isLoading: $_isLoading, espaciosDisponibles: ${_espaciosDisponibles.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Espacio Común'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selección de espacio
                    const Text(
                      'Seleccionar Espacio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_espaciosDisponibles.isEmpty) ...[
                      Builder(
                        builder: (context) {
                          print('❌ [DEBUG] Mostrando mensaje de no hay espacios disponibles');
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No hay espacios comunes disponibles',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          print('✅ [DEBUG] Mostrando ${_espaciosDisponibles.length} espacios disponibles');
                          return Column(
                            children: _espaciosDisponibles.map((espacio) {
                              print('🏠 [DEBUG] Renderizando espacio: ${espacio.nombre}');
                              return _buildEspacioCard(espacio);
                            }).toList(),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Selección de fecha
                    const Text(
                      'Fecha de Uso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (fecha != null) {
                          setState(() {
                            _fechaSeleccionada = fecha;
                            _mostrandoHorarios = false;
                            _horaInicioSeleccionada = null;
                          });
                          await _verificarDisponibilidad();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(
                              _fechaSeleccionada != null
                                  ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)
                                  : 'Seleccionar fecha',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cantidad de personas
                    const Text(
                      'Cantidad de Personas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cantidadPersonasController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.people),
                        hintText: 'Número de personas',
                        suffixText: _espacioSeleccionado != null 
                            ? 'Máx: ${_espacioSeleccionado!.capacidad}'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese la cantidad de personas';
                        }
                        final cantidad = int.tryParse(value.trim());
                        if (cantidad == null || cantidad <= 0) {
                          return 'Ingrese un número válido mayor a 0';
                        }
                        if (_espacioSeleccionado != null && cantidad > _espacioSeleccionado!.capacidad) {
                          return 'Máximo ${_espacioSeleccionado!.capacidad} personas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selección de hora
                    const Text(
                      'Hora de Inicio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        if (_espacioSeleccionado == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Primero seleccione un espacio común'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (hora != null) {
                          // Verificar si está dentro del horario del espacio
                          if (_espacioSeleccionado!.horaApertura != null && 
                              _espacioSeleccionado!.horaCierre != null) {
                            final apertura = _parseTimeOfDay(_espacioSeleccionado!.horaApertura!);
                            final cierre = _parseTimeOfDay(_espacioSeleccionado!.horaCierre!);
                            final horaMinutos = hora.hour * 60 + hora.minute;
                            final aperturaMinutos = apertura.hour * 60 + apertura.minute;
                            final cierreMinutos = cierre.hour * 60 + cierre.minute;
                            
                            if (horaMinutos < aperturaMinutos || horaMinutos >= cierreMinutos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'La hora debe estar entre ${_espacioSeleccionado!.horaApertura} y ${_espacioSeleccionado!.horaCierre}'
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                          
                          setState(() {
                            _horaInicioSeleccionada = hora;
                          });
                          
                          if (_fechaSeleccionada != null) {
                            await _verificarDisponibilidad();
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Text(
                              _horaInicioSeleccionada != null
                                  ? _horaInicioSeleccionada!.format(context)
                                  : 'Seleccionar hora',
                            ),
                            if (_espacioSeleccionado != null && 
                                _espacioSeleccionado!.horaApertura != null && 
                                _espacioSeleccionado!.horaCierre != null) ...[
                              const Spacer(),
                              Text(
                                'Horario: ${_espacioSeleccionado!.horaApertura} - ${_espacioSeleccionado!.horaCierre}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mostrar horarios disponibles
                    if (_mostrandoHorarios) ..._buildHorariosDisponibles(),

                    // Motivo
                    const Text(
                      'Motivo de la Solicitud',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Describa el motivo de su solicitud',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese el motivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botón enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_espacioSeleccionado == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor seleccione un espacio común'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (_formKey.currentState!.validate() &&
                                    _fechaSeleccionada != null &&
                                    _horaInicioSeleccionada != null) {
                                  _enviarSolicitud();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Por favor complete todos los campos requeridos'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Enviar Solicitud',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEspacioImage(EspacioComunModel espacio) {
    // Recopilar todas las imágenes disponibles
    List<Map<String, dynamic>> images = [];
    
    if (espacio.additionalData != null) {
      // Buscar imagen1Data, imagen2Data y imagen3Data
      for (int i = 1; i <= 3; i++) {
        final imageKey = 'imagen${i}Data';
        if (espacio.additionalData![imageKey] != null) {
          Map<String, dynamic> imageData = espacio.additionalData![imageKey];
          
          // Debug: Imprimir la estructura de imageData
          print('DEBUG - $imageKey structure: $imageData');
          print('DEBUG - $imageKey type: ${imageData['type']}');
          print('DEBUG - $imageKey keys: ${imageData.keys.toList()}');
          
          // Validar y corregir la estructura de imageData si es necesario
          Map<String, dynamic> validImageData = _validateImageData(imageData);
          images.add(validImageData);
        }
      }
    }
    
    if (images.isNotEmpty) {
      return ImageCarouselWidget(
        images: images,
        onImageTap: (imageData) => _mostrarImagenCompleta(imageData),
      );
    } else {
      return const Icon(
        Icons.business,
        size: 40,
        color: Colors.grey,
      );
    }
  }

  Widget _buildEspacioCard(EspacioComunModel espacio) {
    final isSelected = _espacioSeleccionado?.id == espacio.id;
    return Card(
      elevation: isSelected ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _espacioSeleccionado = espacio;
            _mostrandoHorarios = false;
            _horaInicioSeleccionada = null;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen del espacio - Aumentado el tamaño para mejor proporción
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: _buildEspacioImage(espacio),
              ),
              const SizedBox(width: 12),
              // Información del espacio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      espacio.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (espacio.descripcion != null &&
                        espacio.descripcion!.isNotEmpty)
                      Text(
                        espacio.descripcion!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tiempo: ${espacio.tiempoUso}h',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    if (espacio.horaApertura != null &&
                        espacio.horaCierre != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Horario: ${espacio.horaApertura} - ${espacio.horaCierre}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (espacio.precio != null && espacio.precio! > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Precio: \$${espacio.precio}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Indicador de selección
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 24,
                )
              else
                const Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHorariosDisponibles() {
    if (_espacioSeleccionado == null) return [];

    final widgets = <Widget>[
      const Text(
        'Horarios Disponibles',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
    ];

    // Mostrar horarios ocupados si los hay
    if (_horariosOcupados.isNotEmpty) {
      widgets.add(
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horarios Ocupados:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_horariosOcupados.map((horario) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            horario['estado'] == 'aceptado' 
                                ? Icons.check_circle 
                                : Icons.pending,
                            size: 16,
                            color: horario['estado'] == 'aceptado' 
                                ? Colors.red 
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${horario['horaInicio']} - ${horario['horaFin']}',  //no incluir (${horario['nombreSolicitante']})  ni - ${horario['estado'].toUpperCase()}
                              style: TextStyle(
                                color: horario['estado'] == 'aceptado' 
                                    ? Colors.red 
                                    : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
              ],
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // // Selector de hora de inicio ya mostrado
    // widgets.add(
    //   InkWell(
    //     onTap: () async {
    //       final hora = await showTimePicker(
    //         context: context,
    //         initialTime: TimeOfDay.now(),
    //       );
    //       if (hora != null) {
    //         setState(() {
    //           _horaInicioSeleccionada = hora;
    //         });
    //       }
    //     },
    //     child: Container(
    //       padding: const EdgeInsets.all(16),
    //       decoration: BoxDecoration(
    //         border: Border.all(color: Colors.grey),
    //         borderRadius: BorderRadius.circular(4),
    //       ),
    //       child: Row(
    //         children: [
    //           const Icon(Icons.access_time),
    //           const SizedBox(width: 8),
    //           Text(
    //             _horaInicioSeleccionada != null
    //                 ? '${_horaInicioSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaInicioSeleccionada!.minute.toString().padLeft(2, '0')}'
    //                 : 'Seleccionar hora de inicio',
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );

    // Mostrar si el horario seleccionado está disponible
    if (_horaInicioSeleccionada != null) {
      final disponible = _esHorarioDisponible(_horaInicioSeleccionada!);
      final tiempoUso = int.tryParse(_espacioSeleccionado!.tiempoUso) ?? 1;
      final horaFin = TimeOfDay(
        hour: (_horaInicioSeleccionada!.hour + tiempoUso) % 24,
        minute: _horaInicioSeleccionada!.minute,
      );

      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Card(
          color: disponible ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  disponible ? Icons.check_circle : Icons.cancel,
                  color: disponible ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disponible
                        ? 'Horario disponible: ${_horaInicioSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaInicioSeleccionada!.minute.toString().padLeft(2, '0')} - ${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}'
                        : 'Horario no disponible. Seleccione otro horario.',
                    style: TextStyle(
                      color: disponible ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  void _mostrarImagenCompleta(Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Fondo semi-transparente
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Imagen en pantalla completa
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageDisplayWidget(
                      imageData: imageData,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 40,
                right: 40,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Valida y corrige la estructura de imageData si es necesario
  Map<String, dynamic> _validateImageData(Map<String, dynamic> imageData) {
    // Debug: Imprimir información detallada
    print('DEBUG - Validating imageData: $imageData');
    
    // Verificar si tiene el campo 'type'
    if (!imageData.containsKey('type')) {
      print('DEBUG - Missing type field, attempting to infer...');
      
      // Intentar inferir el tipo basado en la estructura
      if (imageData.containsKey('data') && imageData['data'] is String) {
        print('DEBUG - Found data field with String, assuming normal type');
        return {
          'type': 'normal',
          'data': imageData['data'],
        };
      } else if (imageData.containsKey('fragments') && imageData['fragments'] is List) {
        print('DEBUG - Found fragments field, assuming internal_fragmented type');
        return {
          'type': 'internal_fragmented',
          'fragments': imageData['fragments'],
          'total_fragments': imageData['total_fragments'] ?? (imageData['fragments'] as List).length,
          'original_type': imageData['original_type'] ?? 'jpeg',
        };
      } else if (imageData.containsKey('fragment_id')) {
        print('DEBUG - Found fragment_id field, assuming external_fragmented type');
        return {
          'type': 'external_fragmented',
          'fragment_id': imageData['fragment_id'],
          'total_fragments': imageData['total_fragments'] ?? 1,
          'original_type': imageData['original_type'] ?? 'jpeg',
        };
      } else {
        print('DEBUG - Cannot infer type, defaulting to normal with error handling');
        return {
          'type': 'normal',
          'data': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=', // Imagen placeholder muy pequeña
        };
      }
    }
    
    // Si ya tiene type, verificar que sea válido
    final type = imageData['type'] as String?;
    if (type == null || !['normal', 'internal_fragmented', 'external_fragmented'].contains(type)) {
      print('DEBUG - Invalid type: $type, defaulting to normal');
      return {
        'type': 'normal',
        'data': imageData['data'] ?? 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=',
      };
    }
    
    print('DEBUG - imageData is valid with type: $type');
    return imageData;
  }
}