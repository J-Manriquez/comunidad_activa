import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/control_acceso_model.dart';
import '../../../services/control_acceso_service.dart';
import '../../../widgets/seleccion_vivienda_bloqueo_modal.dart';
import 'widgets/seleccion_estacionamiento_modal.dart';

class FormularioControlAccesoScreen extends StatefulWidget {
  final UserModel currentUser;

  const FormularioControlAccesoScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<FormularioControlAccesoScreen> createState() => _FormularioControlAccesoScreenState();
}

class _FormularioControlAccesoScreenState extends State<FormularioControlAccesoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  
  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _viviendaController = TextEditingController();
  final TextEditingController _tipoIngresoOtroController = TextEditingController();
  final TextEditingController _tipoTransporteOtroController = TextEditingController();
  final TextEditingController _patenteController = TextEditingController();
  final TextEditingController _colorOtroController = TextEditingController();
  final TextEditingController _tipoAutoOtroController = TextEditingController();
  
  // Variables de estado
  Map<String, bool> _camposActivos = {};
  Map<String, dynamic> _camposAdicionales = {};
  Map<String, TextEditingController> _camposAdicionalesControllers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Valores de los campos
  String? _tipoIngreso;
  String? _tipoTransporte;
  String? _tipoAuto;
  String? _color;
  bool _usaEstacionamiento = false;
  String? _estacionamientoSeleccionado;
  DateTime _fecha = DateTime.now();
  String _hora = '';
  
  // Opciones para dropdowns
  final List<String> _tiposIngreso = ['residente', 'visita', 'trabajador', 'otro'];
  final List<String> _tiposTransporte = ['pie', 'vehiculo', 'bicicleta', 'otro'];
  final List<String> _tiposAuto = [
    'Auto',
    'Camioneta',
    'SUV',
    'Hatchback',
    'Sedan',
    'Station Wagon',
    'Pick-up',
    'Furgón',
    'Motocicleta',
    'Scooter',
    'Cuatrimoto',
    'Otro'
  ];
  
  final Map<String, Color> _colores = {
    'Blanco': Colors.white,
    'Negro': Colors.black,
    'Gris': Colors.grey,
    'Plata': Colors.grey[300]!,
    'Rojo': Colors.red,
    'Azul': Colors.blue,
    'Verde': Colors.green,
    'Amarillo': Colors.yellow,
    'Naranja': Colors.orange,
    'Morado': Colors.purple,
    'Café': Colors.brown,
    'Beige': const Color(0xFFF5F5DC),
    'Dorado': const Color(0xFFFFD700),
    'Celeste': Colors.lightBlue,
    'Otro': Colors.transparent,
  };

  @override
  void initState() {
    super.initState();
    _inicializarHora();
    _cargarDatos();
  }

  void _inicializarHora() {
    final now = DateTime.now();
    _hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cargarDatos() async {
    try {
      final controlAcceso = await _controlAccesoService.getControlAcceso(
        widget.currentUser.condominioId!,
      );

      if (controlAcceso != null) {
        setState(() {
          _camposActivos = Map<String, bool>.from(controlAcceso.camposActivos);
          _camposAdicionales = Map<String, dynamic>.from(controlAcceso.camposAdicionales);
          
          // Inicializar controladores para campos adicionales
          for (String campo in _camposAdicionales.keys) {
            _camposAdicionalesControllers[campo] = TextEditingController();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar configuración: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rutController.dispose();
    _viviendaController.dispose();
    _tipoIngresoOtroController.dispose();
    _tipoTransporteOtroController.dispose();
    _patenteController.dispose();
    _colorOtroController.dispose();
    _tipoAutoOtroController.dispose();
    
    for (var controller in _camposAdicionalesControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Validación de nombre completo (mínimo 2 palabras)
  bool _validarNombreCompleto(String nombre) {
    final nombreTrimmed = nombre.trim();
    if (nombreTrimmed.isEmpty) return false;
    
    final palabras = nombreTrimmed.split(RegExp(r'\s+'));
    return palabras.length >= 2 && palabras.every((palabra) => palabra.isNotEmpty);
  }

  // Validación de RUT chileno con dígito verificador
  String _formatearRut(String rut) {
    // Limpiar el RUT de caracteres no numéricos excepto K
    String rutLimpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    
    if (rutLimpio.isEmpty) return '';
    
    // Si tiene más de 9 caracteres, truncar
    if (rutLimpio.length > 9) {
      rutLimpio = rutLimpio.substring(0, 9);
    }
    
    // Si tiene menos de 2 caracteres, devolver tal como está
    if (rutLimpio.length < 2) return rutLimpio;
    
    // Separar número y dígito verificador
    String numero = rutLimpio.substring(0, rutLimpio.length - 1);
    String dv = rutLimpio.substring(rutLimpio.length - 1);
    
    // Formatear el número con puntos
    String numeroFormateado = '';
    for (int i = 0; i < numero.length; i++) {
      if (i > 0 && (numero.length - i) % 3 == 0) {
        numeroFormateado += '.';
      }
      numeroFormateado += numero[i];
    }
    
    return '$numeroFormateado-$dv';
  }

  bool _validarRutChileno(String rut) {
    // Limpiar el RUT de puntos y guiones
    String rutLimpio = rut.replaceAll(RegExp(r'[.-]'), '').toUpperCase();
    
    if (rutLimpio.length < 2) return false;
    
    // Separar número y dígito verificador
    String numero = rutLimpio.substring(0, rutLimpio.length - 1);
    String digitoVerificador = rutLimpio.substring(rutLimpio.length - 1);
    
    // Verificar que el número sea numérico
    if (!RegExp(r'^\d+$').hasMatch(numero)) return false;
    
    // Validar que el número no sea todo ceros o muy corto
    int numeroInt = int.parse(numero);
    if (numeroInt < 1000000 || numeroInt > 99999999) return false;
    
    // Rechazar patrones inválidos comunes
    if (numero == '00000000' || numero == '11111111' || numero == '22222222' || 
        numero == '33333333' || numero == '44444444' || numero == '55555555' ||
        numero == '66666666' || numero == '77777777' || numero == '88888888' || 
        numero == '99999999') {
      return false;
    }
    
    // Calcular dígito verificador
    int suma = 0;
    int multiplicador = 2;
    
    for (int i = numero.length - 1; i >= 0; i--) {
      suma += int.parse(numero[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    
    int resto = suma % 11;
    String digitoCalculado = resto == 0 ? '0' : resto == 1 ? 'K' : (11 - resto).toString();
    
    return digitoVerificador == digitoCalculado;
  }

  Future<void> _mostrarSeleccionVivienda() async {
    final viviendaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => SeleccionViviendaBloqueoModal(
        condominioId: widget.currentUser.condominioId!,
        titulo: 'Seleccionar Vivienda de Destino',
        onSeleccion: (vivienda) {
          Navigator.of(context).pop(vivienda);
        },
      ),
    );

    if (viviendaSeleccionada != null) {
      setState(() {
        _viviendaController.text = viviendaSeleccionada;
      });
    }
  }

  Future<void> _mostrarSeleccionEstacionamiento() async {
    final estacionamientoSeleccionado = await showDialog<String>(
      context: context,
      builder: (context) => SeleccionEstacionamientoModal(
        condominioId: widget.currentUser.condominioId!,
        titulo: 'Seleccionar Estacionamiento',
        viviendaSeleccionada: _viviendaController.text.trim().isEmpty ? null : _viviendaController.text.trim(), // Pasar la vivienda seleccionada
        onSeleccion: (estacionamiento) {
          Navigator.of(context).pop(estacionamiento);
        },
      ),
    );

    if (estacionamientoSeleccionado != null) {
      setState(() {
        _estacionamientoSeleccionado = estacionamientoSeleccionado;
        _usaEstacionamiento = true;
      });
    }
  }

  bool _validarFormulario() {
    // Validar campos obligatorios
    if (_camposActivos['nombre'] == true) {
      if (!_validarNombreCompleto(_nombreController.text)) {
        _mostrarError('El nombre debe contener al menos nombre y apellido');
        return false;
      }
    }

    if (_camposActivos['rut'] == true) {
      if (!_validarRutChileno(_rutController.text)) {
        _mostrarError('El RUT ingresado no es válido. Formato: 12.345.678-9');
        return false;
      }
    }

    if (_camposActivos['vivienda'] == true) {
      if (_viviendaController.text.trim().isEmpty) {
        _mostrarError('La vivienda es obligatoria');
        return false;
      }
    }

    // Validar tipo de ingreso "otro"
    if (_tipoIngreso == 'otro' && _tipoIngresoOtroController.text.trim().isEmpty) {
      _mostrarError('Debe especificar el tipo de ingreso');
      return false;
    }

    // Validar tipo de transporte "otro"
    if (_tipoTransporte == 'otro' && _tipoTransporteOtroController.text.trim().isEmpty) {
      _mostrarError('Debe especificar el tipo de transporte');
      return false;
    }

    return true;
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate() || !_validarFormulario()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Preparar datos adicionales
      Map<String, dynamic> additionalData = {};
      for (String campo in _camposAdicionales.keys) {
        if (_camposAdicionalesControllers[campo] != null) {
          additionalData[campo] = _camposAdicionalesControllers[campo]!.text;
        }
      }

      // Crear registro de control diario
      final controlDiario = ControlDiario(
        id: '',
        nombre: _camposActivos['nombre'] == true ? _nombreController.text : '',
        rut: _camposActivos['rut'] == true ? _rutController.text : '',
        fecha: Timestamp.fromDate(_fecha),
        hora: _hora,
        tipoIngreso: _camposActivos['tipoIngreso'] == true 
            ? (_tipoIngreso == 'otro' ? _tipoIngresoOtroController.text : _tipoIngreso ?? '') 
            : '',
        tipoTransporte: _camposActivos['tipoTransporte'] == true 
            ? (_tipoTransporte == 'otro' ? _tipoTransporteOtroController.text : _tipoTransporte ?? '') 
            : '',
        tipoAuto: _camposActivos['tipoAuto'] == true 
            ? (_tipoAuto == 'Otro' ? _tipoAutoOtroController.text : _tipoAuto ?? '') 
            : '',
        color: _camposActivos['color'] == true ? _color ?? '' : '',
        vivienda: _camposActivos['vivienda'] == true ? _viviendaController.text : '',
        usaEstacionamiento: _camposActivos['usaEstacionamiento'] == true ? (_estacionamientoSeleccionado ?? '') : '',
        patente: _camposActivos['patente'] == true ? _patenteController.text : '',
        additionalData: additionalData,
      );

      final registroId = await _controlAccesoService.addControlDiario(
        widget.currentUser.condominioId!,
        controlDiario,
      );

      if (registroId != null) {
        _mostrarExito('Registro guardado exitosamente');
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      } else {
        _mostrarError('Error al guardar el registro');
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo Registro'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Registro de Acceso'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información automática
                _buildInfoAutomaticaCard(),
                const SizedBox(height: 16),
                
                // Campos del formulario
                _buildCamposFormulario(),
                
                const SizedBox(height: 24),
                
                // Botones de acción
                _buildBotonesAccion(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoAutomaticaCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Fecha', '${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                ),
                Expanded(
                  child: _buildInfoItem('Hora', _hora),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCamposFormulario() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Datos del Registro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Campos dinámicos basados en configuración
            ..._buildCamposDinamicos(),
            
            // Campos adicionales
            if (_camposAdicionales.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Campos Adicionales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 12),
              ..._buildCamposAdicionales(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCamposDinamicos() {
    List<Widget> campos = [];

    // Campo Nombre
    if (_camposActivos['nombre'] == true) {
      campos.add(_buildCampoNombre());
      campos.add(const SizedBox(height: 16));
    }

    // Campo RUT
    if (_camposActivos['rut'] == true) {
      campos.add(_buildCampoRut());
      campos.add(const SizedBox(height: 16));
    }

    // Campo Vivienda
    if (_camposActivos['vivienda'] == true) {
      campos.add(_buildCampoVivienda());
      campos.add(const SizedBox(height: 16));
    }

    // Campo Tipo de Ingreso
    if (_camposActivos['tipoIngreso'] == true) {
      campos.add(_buildCampoTipoIngreso());
      campos.add(const SizedBox(height: 16));
    }

    // Campo Tipo de Transporte
    if (_camposActivos['tipoTransporte'] == true) {
      campos.add(_buildCampoTipoTransporte());
      campos.add(const SizedBox(height: 16));
    }

    // Campos dependientes del transporte
    if (_camposActivos['tipoTransporte'] == true && _tipoTransporte != null && _tipoTransporte != 'pie' && _tipoTransporte != 'bicicleta') {
      if (_camposActivos['usaEstacionamiento'] == true) {
        campos.add(_buildCampoUsaEstacionamiento());
        campos.add(const SizedBox(height: 16));
      }

      if (_camposActivos['tipoAuto'] == true) {
        campos.add(_buildCampoTipoAuto());
        campos.add(const SizedBox(height: 16));
      }

      if (_camposActivos['color'] == true) {
        campos.add(_buildCampoColor());
        campos.add(const SizedBox(height: 16));
      }

      if (_camposActivos['patente'] == true) {
        campos.add(_buildCampoPatente());
        campos.add(const SizedBox(height: 16));
      }
    }

    return campos;
  }

  Widget _buildCampoNombre() {
    return TextFormField(
      controller: _nombreController,
      decoration: const InputDecoration(
        labelText: 'Nombre Completo *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
        hintText: 'Ingrese nombre y apellido',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre es obligatorio';
        }
        if (!_validarNombreCompleto(value)) {
          return 'Debe ingresar al menos nombre y apellido';
        }
        return null;
      },
    );
  }

  Widget _buildCampoRut() {
    return TextFormField(
      controller: _rutController,
      decoration: const InputDecoration(
        labelText: 'RUT',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge),
        hintText: '12.345.678-9',
      ),
      onChanged: (value) {
        String rutFormateado = _formatearRut(value);
        if (rutFormateado != value) {
          _rutController.value = TextEditingValue(
            text: rutFormateado,
            selection: TextSelection.collapsed(offset: rutFormateado.length),
          );
        }
      },
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          if (!_validarRutChileno(value)) {
            return 'RUT inválido. Formato: 12.345.678-9';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCampoVivienda() {
    return GestureDetector(
      onTap: _mostrarSeleccionVivienda,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _viviendaController,
          decoration: const InputDecoration(
            labelText: 'Vivienda *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
            suffixIcon: Icon(Icons.arrow_drop_down),
            hintText: 'Seleccionar vivienda',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La vivienda es obligatoria';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCampoTipoIngreso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _tipoIngreso,
          decoration: const InputDecoration(
            labelText: 'Tipo de Ingreso',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.login),
          ),
          items: _tiposIngreso.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(_getTipoIngresoDisplayName(tipo)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tipoIngreso = value;
              if (value != 'otro') {
                _tipoIngresoOtroController.clear();
              }
            });
          },
        ),
        if (_tipoIngreso == 'otro') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _tipoIngresoOtroController,
            decoration: const InputDecoration(
              labelText: 'Especificar tipo de ingreso',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (_tipoIngreso == 'otro' && (value == null || value.trim().isEmpty)) {
                return 'Debe especificar el tipo de ingreso';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCampoTipoTransporte() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _tipoTransporte,
          decoration: const InputDecoration(
            labelText: 'Tipo de Transporte',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions),
          ),
          items: _tiposTransporte.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(_getTipoTransporteDisplayName(tipo)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tipoTransporte = value;
              if (value != 'otro') {
                _tipoTransporteOtroController.clear();
              }
              // Resetear campos dependientes si cambia a pie o bicicleta
              if (value == 'pie' || value == 'bicicleta') {
                _usaEstacionamiento = false;
                _tipoAuto = null;
                _color = null;
                _patenteController.clear();
                _estacionamientoSeleccionado = null;
              }
            });
          },
        ),
        if (_tipoTransporte == 'otro') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _tipoTransporteOtroController,
            decoration: const InputDecoration(
              labelText: 'Especificar tipo de transporte',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (_tipoTransporte == 'otro' && (value == null || value.trim().isEmpty)) {
                return 'Debe especificar el tipo de transporte';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCampoUsaEstacionamiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _mostrarSeleccionEstacionamiento,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.local_parking, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estacionamiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                      if (_estacionamientoSeleccionado != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Estacionamiento ${_estacionamientoSeleccionado}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Seleccionar estacionamiento',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_estacionamientoSeleccionado != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _estacionamientoSeleccionado = null;
                      _usaEstacionamiento = false;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Quitar estacionamiento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCampoTipoAuto() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _tipoAuto,
          decoration: const InputDecoration(
            labelText: 'Tipo de Vehículo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_car),
          ),
          items: _tiposAuto.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(tipo),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tipoAuto = value;
            });
          },
        ),
        if (_tipoAuto == 'Otro') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _tipoAutoOtroController,
            decoration: const InputDecoration(
              labelText: 'Especificar tipo de vehículo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
              hintText: 'Ingrese el tipo de vehículo',
            ),
            validator: (value) {
              if (_tipoAuto == 'Otro' && (value == null || value.trim().isEmpty)) {
                return 'Debe especificar el tipo de vehículo';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCampoColor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _color,
          decoration: const InputDecoration(
            labelText: 'Color del Vehículo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette),
          ),
          items: _colores.keys.map((colorName) {
            return DropdownMenuItem(
              value: colorName,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _colores[colorName],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(colorName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _color = value;
              if (value != 'Otro') {
                _colorOtroController.clear();
              }
            });
          },
        ),
        if (_color == 'Otro') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _colorOtroController,
            decoration: const InputDecoration(
              labelText: 'Especificar color',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (_color == 'Otro' && (value == null || value.trim().isEmpty)) {
                return 'Debe especificar el color';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCampoPatente() {
    return TextFormField(
      controller: _patenteController,
      decoration: const InputDecoration(
        labelText: 'Patente del vehículo',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.directions_car),
        hintText: 'Ej: ABC123',
      ),
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.toUpperCase());
        }),
      ],
      validator: (value) {
        if (_camposActivos['patente'] == true && (value == null || value.trim().isEmpty)) {
          return 'La patente es requerida';
        }
        return null;
      },
    );
  }

  List<Widget> _buildCamposAdicionales() {
    List<Widget> campos = [];
    
    for (String campo in _camposAdicionales.keys) {
      campos.add(
        TextFormField(
          controller: _camposAdicionalesControllers[campo],
          decoration: InputDecoration(
            labelText: _getCampoAdicionalDisplayName(campo),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.note_add),
          ),
        ),
      );
      campos.add(const SizedBox(height: 12));
    }
    
    return campos;
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[600]!),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _guardarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar Registro',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  String _getTipoIngresoDisplayName(String tipo) {
    switch (tipo) {
      case 'residente':
        return 'Residente';
      case 'visita':
        return 'Visita';
      case 'trabajador':
        return 'Trabajador';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }

  String _getTipoTransporteDisplayName(String tipo) {
    switch (tipo) {
      case 'pie':
        return 'A pie';
      case 'vehiculo':
        return 'Vehículo';
      case 'bicicleta':
        return 'Bicicleta';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }

  String _getCampoAdicionalDisplayName(String campo) {
    switch (campo) {
      case 'comentario':
        return 'Comentario';
      case 'observaciones':
        return 'Observaciones';
      case 'telefono':
        return 'Teléfono';
      case 'empresa':
        return 'Empresa';
      default:
        return campo.replaceAll('_', ' ').toUpperCase();
    }
  }
}