import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/control_acceso_model.dart';
import '../models/residente_model.dart';
import '../services/control_acceso_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'admin/controlAcceso/widgets/seleccion_estacionamiento_modal.dart';

// Formateador personalizado para RUT chileno
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Obtener solo los dígitos y K/k
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '');

    // Limitar a máximo 9 caracteres (8 dígitos + 1 verificador)
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    // Si está vacío, retornar vacío
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    String formatted = '';

    // Si tiene más de 1 carácter, formatear
    if (digits.length > 1) {
      // Separar número y dígito verificador
      String numero = digits.substring(0, digits.length - 1);
      String verificador = digits.substring(digits.length - 1).toUpperCase();

      // Formatear el número con puntos
      String numeroFormateado = '';
      for (int i = 0; i < numero.length; i++) {
        if (i > 0 && (numero.length - i) % 3 == 0) {
          numeroFormateado += '.';
        }
        numeroFormateado += numero[i];
      }

      formatted = '$numeroFormateado-$verificador';
    } else {
      formatted = digits;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CrearEditarAccesosPredeterminadosScreen extends StatefulWidget {
  final AccesoPredeterminado? accesoToEdit;

  const CrearEditarAccesosPredeterminadosScreen({Key? key, this.accesoToEdit})
    : super(key: key);

  @override
  State<CrearEditarAccesosPredeterminadosScreen> createState() =>
      _CrearEditarAccesosPredeterminadosScreenState();
}

class _CrearEditarAccesosPredeterminadosScreenState
    extends State<CrearEditarAccesosPredeterminadosScreen> {
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nombreAccesoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _rutController = TextEditingController();
  final _viviendaController = TextEditingController();
  final _tipoAutoController = TextEditingController();
  final _tipoAutoOtroController = TextEditingController();
  final _colorController = TextEditingController();
  final _colorOtroController = TextEditingController();
  final _patenteController = TextEditingController();
  final _tipoTransporteOtroController = TextEditingController();

  // Variables de estado
  TipoIngreso _tipoIngreso = TipoIngreso.residente;
  String? _tipoTransporte;
  String? _tipoAuto;
  String? _color;
  bool _usaEstacionamiento = false;
  String? _estacionamientoSeleccionado;

  // Opciones para dropdowns
  final List<String> _tiposTransporte = [
    'pie',
    'vehiculo',
    'bicicleta',
    'otro',
  ];
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
    'Otro',
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


  Map<String, bool> _camposActivos = {};
  Map<String, dynamic> _camposAdicionales = {};
  Map<String, TextEditingController> _camposAdicionalesControllers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  ResidenteModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    print('🔍 [DEBUG] Iniciando _loadUserAndData');
    
    try {
      final user = _authService.currentUser;
      print('🔍 [DEBUG] Usuario autenticado: ${user != null ? user.uid : 'null'}');
      
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        print('🔍 [DEBUG] Datos del residente obtenidos: ${residente != null ? 'SÍ' : 'NO'}');
        print('🔍 [DEBUG] condominioId del residente: ${residente?.condominioId}');
        
        setState(() {
          _currentUser = residente;
        });
        
        print('🔍 [DEBUG] Llamando a _initializeForm...');
        _initializeForm();
        
        print('🔍 [DEBUG] Llamando a _cargarCamposActivos...');
        await _cargarCamposActivos();
        
        print('🔍 [DEBUG] _loadUserAndData completado exitosamente');
      } else {
        print('❌ [DEBUG] No hay usuario autenticado');
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading user data: $e');
      print('❌ [DEBUG] Stack trace: ${StackTrace.current}');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🔍 [DEBUG] _isLoading establecido a false');
    }
  }

  void _initializeForm() {
    if (widget.accesoToEdit != null) {
      // Modo edición
      final acceso = widget.accesoToEdit!;
      _nombreAccesoController.text = acceso.nombreAcceso;
      _nombreController.text = acceso.nombre;
      _rutController.text = acceso.rut;
      _viviendaController.text = acceso.vivienda;
      _patenteController.text = acceso.patente;
      
      // Manejar tipo de auto personalizado
      if (_tiposAuto.contains(acceso.tipoAuto)) {
        _tipoAuto = acceso.tipoAuto;
      } else {
        _tipoAuto = 'Otro';
        _tipoAutoOtroController.text = acceso.tipoAuto;
      }
      
      // Manejar color personalizado
      if (_colores.containsKey(acceso.color)) {
        _color = acceso.color;
      } else {
        _color = 'Otro';
        _colorOtroController.text = acceso.color;
      }
      
      _tipoIngreso = TipoIngreso.values.firstWhere(
        (e) => e.toString().split('.').last == acceso.tipoIngreso,
        orElse: () => TipoIngreso.residente,
      );
      _tipoTransporte = acceso.tipoTransporte;
      _usaEstacionamiento = acceso.usaEstacionamiento;
    } else {
      // Modo creación - autocompletar campos del residente
      _nombreController.text = _currentUser?.nombre ?? '';
      _rutController.text = '';
      _viviendaController.text = _currentUser?.descripcionVivienda ?? '';
      _tipoIngreso = TipoIngreso.residente;
      _tipoTransporte = 'pie'; // Valor por defecto
    }
  }

  Future<void> _cargarCamposActivos() async {
    print('🔍 [DEBUG] Iniciando _cargarCamposActivos');
    print('🔍 [DEBUG] condominioId: ${_currentUser?.condominioId}');
    
    if (_currentUser?.condominioId == null) {
      print('❌ [DEBUG] condominioId es null, saliendo de _cargarCamposActivos');
      return;
    }

    try {
      print('🔍 [DEBUG] Llamando a getControlAcceso...');
      final controlAcceso = await _controlAccesoService.getControlAcceso(
        _currentUser!.condominioId!,
      );

      print('🔍 [DEBUG] controlAcceso obtenido: ${controlAcceso != null ? 'SÍ' : 'NO'}');
      
      if (controlAcceso != null) {
        print('🔍 [DEBUG] camposActivos: ${controlAcceso.camposActivos}');
        print('🔍 [DEBUG] camposAdicionales: ${controlAcceso.camposAdicionales}');
        print('🔍 [DEBUG] Número de campos adicionales: ${controlAcceso.camposAdicionales.length}');
        
        setState(() {
          _camposActivos = Map<String, bool>.from(controlAcceso.camposActivos);
          _camposAdicionales = Map<String, dynamic>.from(
            controlAcceso.camposAdicionales,
          );

          print('🔍 [DEBUG] _camposAdicionales después de setState: $_camposAdicionales');

          // Inicializar controladores para campos adicionales
          for (String campo in _camposAdicionales.keys) {
            print('🔍 [DEBUG] Inicializando controlador para campo: $campo');
            print('🔍 [DEBUG] Configuración del campo: ${_camposAdicionales[campo]}');
            
            _camposAdicionalesControllers[campo] = TextEditingController();
            
            // Si estamos en modo edición, cargar los valores existentes
            if (widget.accesoToEdit != null && 
                widget.accesoToEdit!.additionalData.containsKey(campo)) {
              final valor = widget.accesoToEdit!.additionalData[campo]?.toString() ?? '';
              print('🔍 [DEBUG] Cargando valor existente para $campo: $valor');
              _camposAdicionalesControllers[campo]!.text = valor;
            }
          }
          
          print('🔍 [DEBUG] Total de controladores creados: ${_camposAdicionalesControllers.length}');
          print('🔍 [DEBUG] Controladores: ${_camposAdicionalesControllers.keys.toList()}');
        });
      } else {
        print('❌ [DEBUG] controlAcceso es null');
      }
    } catch (e) {
      print('❌ [DEBUG] Error al cargar campos activos: $e');
      print('❌ [DEBUG] Stack trace: ${StackTrace.current}');
    }
  }

  List<AccesoPredeterminado> _accesosExistentes = [];

  Future<void> _loadAccesosExistentes() async {
    if (_currentUser?.condominioId == null) return;

    setState(() => _isLoading = true);

    final condominioId = _currentUser!.condominioId!;
    final uid = _currentUser!.uid;

    try {
      final accesos = await _controlAccesoService.getAccesosPredeterminados(
        condominioId,
        uid,
      );
      setState(() {
        _accesosExistentes = accesos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar accesos: $e')));
    }
  }

  Future<void> _saveAcceso() async {
    print('🔍 [DEBUG] Iniciando _saveAcceso');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [DEBUG] Formulario no válido, cancelando guardado');
      return;
    }
    
    if (_currentUser?.condominioId == null) {
      print('❌ [DEBUG] No hay condominioId, cancelando guardado');
      return;
    }

    setState(() => _isSaving = true);

    final condominioId = _currentUser!.condominioId!;
    print('🔍 [DEBUG] condominioId: $condominioId');

    try {
      // Recopilar datos de campos adicionales
      Map<String, dynamic> additionalData = {};
      print('🔍 [DEBUG] Recopilando datos de campos adicionales...');
      print('🔍 [DEBUG] Controllers disponibles: ${_camposAdicionalesControllers.keys.toList()}');
      
      for (String campo in _camposAdicionalesControllers.keys) {
        final controller = _camposAdicionalesControllers[campo];
        print('🔍 [DEBUG] Procesando campo: $campo');
        print('🔍 [DEBUG] Controller existe: ${controller != null}');
        print('🔍 [DEBUG] Valor del controller: ${controller?.text}');
        
        if (controller != null && controller.text.isNotEmpty) {
          additionalData[campo] = controller.text.trim();
          print('✅ [DEBUG] Campo $campo agregado con valor: ${controller.text.trim()}');
        } else {
          print('⚠️ [DEBUG] Campo $campo omitido (controller null o texto vacío)');
        }
      }
      
      print('🔍 [DEBUG] additionalData final: $additionalData');

      final acceso = AccesoPredeterminado(
        id: widget.accesoToEdit?.id ?? '',
        nombreAcceso: _nombreAccesoController.text.trim(),
        nombre: _nombreController.text.trim(),
        rut: _rutController.text.trim(),
        uidResidente: _currentUser?.uid ?? '', // Asignar el uid del residente
        fecha:
            Timestamp.now(), // Se usará la fecha actual al momento de guardar
        hora: TimeOfDay.now().format(
          context,
        ), // Se usará la hora actual al momento de guardar
        tipoIngreso: _tipoIngreso.toString().split('.').last,
        tipoTransporte: _tipoTransporte ?? 'pie',
        tipoAuto: _tipoAuto == 'Otro' ? _tipoAutoOtroController.text.trim() : (_tipoAuto ?? ''),
        color: _color == 'Otro' ? _colorOtroController.text.trim() : (_color ?? ''),
        vivienda: _viviendaController.text.trim(),
        usaEstacionamiento: _usaEstacionamiento,
        patente: _patenteController.text.trim().toUpperCase(),
        additionalData: additionalData,
      );

      print('🔍 [DEBUG] Objeto AccesoPredeterminado creado:');
      print('🔍 [DEBUG] - nombre: ${acceso.nombre}');
      print('🔍 [DEBUG] - rut: ${acceso.rut}');
      print('🔍 [DEBUG] - additionalData: ${acceso.additionalData}');

      bool success;
      if (widget.accesoToEdit != null) {
        // Actualizar acceso existente
        print('🔍 [DEBUG] Actualizando acceso existente con ID: ${widget.accesoToEdit!.id}');
        success = await _controlAccesoService.updateAccesoPredeterminado(
          condominioId,
          widget.accesoToEdit!.id,
          acceso,
        );
      } else {
        // Crear nuevo acceso
        print('🔍 [DEBUG] Creando nuevo acceso');
        String? accesoId = await _controlAccesoService
            .createAccesoPredeterminado(condominioId, acceso);
        success = accesoId != null;
        print('🔍 [DEBUG] Nuevo acceso creado con ID: $accesoId');
      }

      print('🔍 [DEBUG] Resultado del guardado: ${success ? 'ÉXITO' : 'ERROR'}');

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.accesoToEdit != null
                  ? 'Acceso actualizado exitosamente'
                  : 'Acceso creado exitosamente',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el acceso')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }



  String _formatearNombreCampo(String campo) {
    // Formatear el nombre del campo para mostrar
    switch (campo.toLowerCase()) {
      case 'comentario':
        return 'Comentario';
      case 'observaciones':
        return 'Observaciones';
      case 'telefono':
        return 'Teléfono';
      case 'empresa':
        return 'Empresa';
      case 'motivo':
        return 'Motivo de la visita';
      case 'contacto':
        return 'Contacto';
      default:
        // Capitalizar primera letra y reemplazar guiones bajos con espacios
        return campo.replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty 
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : word)
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.accesoToEdit != null
              ? 'Editar Acceso Predeterminado'
              : 'Crear Acceso Predeterminado',
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(onPressed: _saveAcceso, icon: const Icon(Icons.save)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormFields(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }



  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información básica
        Text(
          'Información Básica',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 16),

        // Nombre del Acceso
        TextFormField(
          controller: _nombreAccesoController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Acceso',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
            hintText: 'Ej: Acceso Principal, Visita Familiar, etc.',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre del acceso es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Vivienda (no modificable)
        TextFormField(
          controller: _viviendaController,
          decoration: const InputDecoration(
            labelText: 'Vivienda',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          enabled: false, // No modificable
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La vivienda es requerida';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Nombre (auto-completado desde currentUser)
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre Completo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          enabled: _tipoIngreso == TipoIngreso.visita, // Habilitado solo para visitas
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // RUT con formato automático
        TextFormField(
          controller: _rutController,
          decoration: const InputDecoration(
            labelText: 'RUT',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
            hintText: 'Ej: 12.345.678-9',
          ),
          inputFormatters: [RutInputFormatter()],
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El RUT es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Tipo de ingreso
        Text(
          'Tipo de Ingreso',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipoIngreso>(
          value: _tipoIngreso,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.login),
          ),
          items: TipoIngreso.values.map((tipo) {
            return DropdownMenuItem(value: tipo, child: Text(tipo.displayName));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _tipoIngreso = value;
                // Si el tipo de ingreso es visita, limpiar el campo nombre
                if (value == TipoIngreso.visita) {
                  _nombreController.clear();
                } else {
                  // Si no es visita, restaurar el nombre del usuario actual
                  _nombreController.text = _currentUser?.nombre ?? '';
                }
              });
            }
          },
        ),
        const SizedBox(height: 24),

        // Transporte con nuevas opciones
        Text(
          'Transporte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipoTransporte,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions),
          ),
          items: _tiposTransporte.map((tipo) {
            return DropdownMenuItem(value: tipo, child: Text(tipo));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _tipoTransporte = value;
              // Limpiar campos de vehículo si no es necesario
              if (value != 'vehiculo' && value != 'otro') {
                _tipoAuto = null;
                _color = null;
                _patenteController.clear();
                _estacionamientoSeleccionado = null;
              }
            });
          },
        ),
        const SizedBox(height: 16),

        // Campo de texto para "otro" transporte
        if (_tipoTransporte == 'otro') ...[
          TextFormField(
            controller: _tipoTransporteOtroController,
            decoration: const InputDecoration(
              labelText: 'Especificar tipo de transporte',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (_tipoTransporte == 'otro' &&
                  (value == null || value.trim().isEmpty)) {
                return 'Debe especificar el tipo de transporte';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        // Campos de vehículo (para vehiculo y otro)
        if (_tipoTransporte == 'vehiculo' || _tipoTransporte == 'otro') ...[
          Text(
            'Información del Vehículo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),

          // Tipo de vehículo
          DropdownButtonFormField<String>(
            value: _tipoAuto,
            decoration: const InputDecoration(
              labelText: 'Tipo de Vehículo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car),
            ),
            items: _tiposAuto.map((tipo) {
              return DropdownMenuItem(value: tipo, child: Text(tipo));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _tipoAuto = value;
                // Limpiar el campo personalizado si no es "Otro"
                if (value != 'Otro') {
                  _tipoAutoOtroController.clear();
                }
              });
            },
            validator: (value) {
              if ((_tipoTransporte == 'vehiculo' ||
                      _tipoTransporte == 'otro') &&
                  (value == null || value.isEmpty)) {
                return 'Debe seleccionar el tipo de vehículo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de texto para "Otro" tipo de vehículo
          if (_tipoAuto == 'Otro') ...[
            TextFormField(
              controller: _tipoAutoOtroController,
              decoration: const InputDecoration(
                labelText: 'Especificar tipo de vehículo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (_tipoAuto == 'Otro' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Debe especificar el tipo de vehículo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Color del vehículo
          DropdownButtonFormField<String>(
            value: _color,
            decoration: const InputDecoration(
              labelText: 'Color del Vehículo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.palette),
            ),
            items: _colores.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.key),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _color = value;
                // Limpiar el campo personalizado si no es "Otro"
                if (value != 'Otro') {
                  _colorOtroController.clear();
                }
              });
            },
            validator: (value) {
              if ((_tipoTransporte == 'vehiculo' ||
                      _tipoTransporte == 'otro') &&
                  (value == null || value.isEmpty)) {
                return 'Debe seleccionar el color del vehículo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de texto para "Otro" color
          if (_color == 'Otro') ...[
            TextFormField(
              controller: _colorOtroController,
              decoration: const InputDecoration(
                labelText: 'Especificar color del vehículo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (_color == 'Otro' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Debe especificar el color del vehículo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Patente del vehículo
          TextFormField(
            controller: _patenteController,
            decoration: const InputDecoration(
              labelText: 'Patente del Vehículo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number),
              hintText: 'Ej: ABCD12',
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              // Transformar a mayúsculas en tiempo real
              final upperCaseValue = value.toUpperCase();
              if (value != upperCaseValue) {
                _patenteController.value = _patenteController.value.copyWith(
                  text: upperCaseValue,
                  selection: TextSelection.collapsed(offset: upperCaseValue.length),
                );
              }
            },
            validator: (value) {
              if ((_tipoTransporte == 'vehiculo' ||
                      _tipoTransporte == 'otro') &&
                  (value == null || value.trim().isEmpty)) {
                return 'La patente es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Usa estacionamiento
          Card(
            child: SwitchListTile(
              title: const Text('Usa Estacionamiento'),
              subtitle: _estacionamientoSeleccionado != null
                  ? Text('Estacionamiento: $_estacionamientoSeleccionado')
                  : const Text('No usa estacionamiento'),
              value: _estacionamientoSeleccionado != null,
              onChanged: (value) {
                if (value) {
                  _mostrarModalEstacionamiento();
                } else {
                  setState(() => _estacionamientoSeleccionado = null);
                }
              },
              secondary: const Icon(Icons.local_parking),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Campos adicionales configurados por el administrador
        if (_camposAdicionales.isNotEmpty && 
            _camposAdicionales.entries.any((entry) => 
              (entry.value as Map<String, dynamic>)['activo'] == true)) ...[
          const SizedBox(height: 8),
          Text(
            'Información Adicional',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          ..._camposAdicionales.entries.map((entry) {
            final campo = entry.key;
            final configuracionCampo = entry.value as Map<String, dynamic>;
            final isActive = configuracionCampo['activo'] ?? false;

            print('🔍 [DEBUG] Renderizando campo adicional: $campo');
            print('🔍 [DEBUG] Configuración del campo: $configuracionCampo');
            print('🔍 [DEBUG] Campo activo: $isActive');
            print('🔍 [DEBUG] Controller existe: ${_camposAdicionalesControllers[campo] != null}');
            print('🔍 [DEBUG] Valor actual del controller: ${_camposAdicionalesControllers[campo]?.text}');

            if (!isActive) {
              print('🔍 [DEBUG] Campo $campo no está activo, omitiendo renderizado');
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                TextFormField(
                  controller: _camposAdicionalesControllers[campo],
                  decoration: InputDecoration(
                    labelText: _formatearNombreCampo(campo),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.info_outline),
                  ),
                  onChanged: (value) {
                    print('🔍 [DEBUG] Campo $campo cambió a: $value');
                  },
                  validator: configuracionCampo['requerido'] == true
                      ? (value) {
                          print('🔍 [DEBUG] Validando campo requerido $campo: $value');
                          if (value == null || value.trim().isEmpty) {
                            return 'Este campo es requerido';
                          }
                          return null;
                        }
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],

        const SizedBox(height: 32),

        // Botón de guardar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAcceso,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.accesoToEdit != null
                        ? 'Actualizar Acceso'
                        : 'Crear Acceso',
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _mostrarModalEstacionamiento() async {
    final estacionamientoSeleccionado = await showDialog<String>(
      context: context,
      builder: (context) => SeleccionEstacionamientoModal(
        condominioId: _currentUser?.condominioId ?? '',
        titulo: 'Seleccionar Estacionamiento',
        viviendaSeleccionada: _viviendaController.text.trim().isEmpty
            ? null
            : _viviendaController.text.trim(),
        esResidente: true, // Indicar que es un residente
        onSeleccion: (estacionamiento) {
          Navigator.of(context).pop(estacionamiento);
        },
      ),
    );

    if (estacionamientoSeleccionado != null) {
      setState(() {
        _estacionamientoSeleccionado = estacionamientoSeleccionado;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreAccesoController.dispose();
    _rutController.dispose();
    _viviendaController.dispose();
    _patenteController.dispose();
    _tipoTransporteOtroController.dispose();
    // Dispose de los controladores de campos adicionales
    for (final controller in _camposAdicionalesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}