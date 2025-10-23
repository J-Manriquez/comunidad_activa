import 'package:flutter/material.dart';
import '../../models/turno_definido_model.dart';
import '../../models/condominio_model.dart';
import '../../services/turnos_service.dart';
import '../../services/firestore_service.dart';

class GestionTurnosDefinidosScreen extends StatefulWidget {
  const GestionTurnosDefinidosScreen({super.key});

  @override
  State<GestionTurnosDefinidosScreen> createState() => _GestionTurnosDefinidosScreenState();
}

class _GestionTurnosDefinidosScreenState extends State<GestionTurnosDefinidosScreen> {
  final TurnosService _turnosService = TurnosService();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TurnoDefinido> _turnos = [];
  bool _isLoading = true;
  String? _condominioId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _condominioId = await _firestoreService.getCondominioId();
      if (_condominioId != null) {
        await _cargarTurnos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar: $e')),
        );
      }
    }
  }

  Future<void> _cargarTurnos() async {
    if (_condominioId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Cargando turnos para condominioId: $_condominioId');
      final turnos = await _turnosService.obtenerTurnosDefinidos(_condominioId!);
      print('Turnos obtenidos: ${turnos.length}');
      for (var turno in turnos) {
        print('Turno: ${turno.tipoTurno} - ${turno.tipoTrabajador} (${turno.horaInicio}-${turno.horaTermino})');
      }
      setState(() {
        _turnos = turnos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar turnos: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar turnos: $e')),
        );
      }
    }
  }

  Future<void> _mostrarModalTurno({TurnoDefinido? turno}) async {
    final resultado = await showDialog<TurnoDefinido>(
      context: context,
      builder: (context) => _ModalTurnoDefinido(turno: turno),
    );

    if (resultado != null && _condominioId != null) {
      try {
        print('Guardando turno: ${resultado.toMap()}');
        await _turnosService.guardarTurnoDefinido(_condominioId!, resultado);
        print('Turno guardado exitosamente');
        await _cargarTurnos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(turno == null ? 'Turno creado exitosamente' : 'Turno actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error al guardar turno: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar turno: $e')),
          );
        }
      }
    } else {
      print('Modal cancelado o condominioId es null');
    }
  }

  Future<void> _eliminarTurno(TurnoDefinido turno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el turno "${turno.tipoTurno}" para ${turno.tipoTrabajador}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && _condominioId != null) {
      try {
        await _turnosService.eliminarTurnoDefinido(_condominioId!, turno.id);
        await _cargarTurnos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turno eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar turno: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Turnos'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Turnos Definidos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    'Gestiona los horarios de trabajo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de turnos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _turnos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay turnos definidos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Presiona el botón + para crear uno',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarTurnos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _turnos.length,
                            itemBuilder: (context, index) {
                              final turno = _turnos[index];
                              return _buildTurnoCard(turno);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalTurno(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTurnoCard(TurnoDefinido turno) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del turno
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turno.tipoTurno,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    turno.tipoTrabajador,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${turno.horaInicio} - ${turno.horaTermino}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menú de opciones
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  _mostrarModalTurno(turno: turno);
                } else if (value == 'eliminar') {
                  _eliminarTurno(turno);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalTurnoDefinido extends StatefulWidget {
  final TurnoDefinido? turno;

  const _ModalTurnoDefinido({this.turno});

  @override
  State<_ModalTurnoDefinido> createState() => _ModalTurnoDefinidoState();
}

class _ModalTurnoDefinidoState extends State<_ModalTurnoDefinido> {
  final _formKey = GlobalKey<FormState>();
  final _tipoTurnoController = TextEditingController();
  final _tipoTurnoPersonalizadoController = TextEditingController();
  
  String? _tipoTrabajadorSeleccionado;
  String? _tipoTurnoSeleccionado;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaTermino;
  bool _mostrarCampoPersonalizado = false;
  
  List<String> _tiposTrabajador = [];
  final List<String> _tiposTurno = [
    'Semana',
    'Fin de semana',
    'Toda la semana',
    'Otro',
  ];

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _cargarTiposTrabajador();
    
    if (widget.turno != null) {
      _tipoTrabajadorSeleccionado = widget.turno!.tipoTrabajador;
      
      // Verificar si el tipo de turno está en las opciones predefinidas
      if (_tiposTurno.contains(widget.turno!.tipoTurno)) {
        _tipoTurnoSeleccionado = widget.turno!.tipoTurno;
      } else {
        _tipoTurnoSeleccionado = 'Otro';
        _mostrarCampoPersonalizado = true;
        _tipoTurnoPersonalizadoController.text = widget.turno!.tipoTurno;
      }
      
      // Parsear horas
      final inicioPartes = widget.turno!.horaInicio.split(':');
      _horaInicio = TimeOfDay(
        hour: int.parse(inicioPartes[0]),
        minute: int.parse(inicioPartes[1]),
      );
      
      final terminoPartes = widget.turno!.horaTermino.split(':');
      _horaTermino = TimeOfDay(
        hour: int.parse(terminoPartes[0]),
        minute: int.parse(terminoPartes[1]),
      );
    }
  }

  Future<void> _cargarTiposTrabajador() async {
    try {
      final condominioId = await _firestoreService.getCondominioId();
      if (condominioId != null) {
        final condominio = await _firestoreService.getCondominioData(condominioId);
        if (condominio.tiposTrabajadores != null && condominio.tiposTrabajadores!.isNotEmpty) {
          setState(() {
            _tiposTrabajador = condominio.tiposTrabajadores!.values.toList();
          });
          print('Tipos de trabajador cargados: $_tiposTrabajador');
        } else {
          print('No se encontraron tipos de trabajador en el condominio, usando valores por defecto');
          _usarTiposPorDefecto();
        }
      } else {
        print('No se pudo obtener el condominioId');
        _usarTiposPorDefecto();
      }
    } catch (e) {
      print('Error al cargar tipos de trabajador: $e');
      _usarTiposPorDefecto();
    }
  }

  void _usarTiposPorDefecto() {
    setState(() {
      _tiposTrabajador = [
        'Conserje',
        'Guardia',
        'Jardinero',
        'Técnico',
        'Limpieza',
        'Administrador',
      ];
    });
  }

  @override
  void dispose() {
    _tipoTurnoController.dispose();
    _tipoTurnoPersonalizadoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: esInicio 
          ? (_horaInicio ?? const TimeOfDay(hour: 8, minute: 0))
          : (_horaTermino ?? const TimeOfDay(hour: 17, minute: 0)),
    );

    if (hora != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = hora;
        } else {
          _horaTermino = hora;
        }
      });
    }
  }

  String _formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  void _guardar() {
    String tipoTurnoFinal;
    
    if (_tipoTurnoSeleccionado == 'Otro') {
      if (_tipoTurnoPersonalizadoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe ingresar un tipo de turno personalizado')),
        );
        return;
      }
      tipoTurnoFinal = _tipoTurnoPersonalizadoController.text.trim();
    } else {
      tipoTurnoFinal = _tipoTurnoSeleccionado ?? '';
    }
    
    if (_formKey.currentState!.validate() && 
        _tipoTrabajadorSeleccionado != null &&
        _tipoTurnoSeleccionado != null &&
        _horaInicio != null &&
        _horaTermino != null) {
      
      final turno = TurnoDefinido(
        id: widget.turno?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        tipoTrabajador: _tipoTrabajadorSeleccionado!,
        tipoTurno: tipoTurnoFinal,
        horaInicio: _formatearHora(_horaInicio!),
        horaTermino: _formatearHora(_horaTermino!),
      );

      Navigator.pop(context, turno);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.turno == null ? 'Crear Turno' : 'Editar Turno',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de turno
              DropdownButtonFormField<String>(
                value: _tipoTurnoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Turno',
                  border: OutlineInputBorder(),
                ),
                items: _tiposTurno.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoTurnoSeleccionado = value;
                    _mostrarCampoPersonalizado = value == 'Otro';
                    if (!_mostrarCampoPersonalizado) {
                      _tipoTurnoPersonalizadoController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un tipo de turno';
                  }
                  return null;
                },
              ),
              
              // Campo personalizado para "Otro"
              if (_mostrarCampoPersonalizado) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoTurnoPersonalizadoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Turno Personalizado',
                    hintText: 'Ingrese el tipo de turno',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_tipoTurnoSeleccionado == 'Otro' && (value == null || value.trim().isEmpty)) {
                      return 'Este campo es requerido';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 16),

              // Tipo de trabajador
              DropdownButtonFormField<String>(
                value: _tipoTrabajadorSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Trabajador',
                  border: OutlineInputBorder(),
                ),
                items: _tiposTrabajador.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoTrabajadorSeleccionado = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un tipo de trabajador';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Hora de inicio
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora de Inicio',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _horaInicio != null 
                              ? _formatearHora(_horaInicio!)
                              : 'Seleccionar hora',
                          style: TextStyle(
                            color: _horaInicio != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _seleccionarHora(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora de Término',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _horaTermino != null 
                              ? _formatearHora(_horaTermino!)
                              : 'Seleccionar hora',
                          style: TextStyle(
                            color: _horaTermino != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.turno == null ? 'Crear' : 'Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}