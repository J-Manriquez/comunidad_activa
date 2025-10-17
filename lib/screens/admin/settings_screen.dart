import 'package:comunidad_activa/screens/admin/vivienda/config_viviendas_screen.dart';
import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';
import '../../services/mensaje_service.dart';
import '../../services/estacionamiento_service.dart';
import '../../services/control_acceso_service.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  final String condominioId;
  
  const SettingsScreen({super.key, required this.condominioId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final MensajeService _mensajeService = MensajeService();
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  CondominioModel? _condominio;
  bool _isLoading = true;
  bool _comunicacionEntreResidentes = false;
  bool _cobrarMultasConGastos = false;
  bool _cobrarEspaciosConGastos = false;
  bool _estacionamientosActivos = false;
  bool _usaEstacionamientoVisitas = false;
  bool _estVisitas = false; // Nueva variable para observar estVisitas
  StreamSubscription<bool>? _estVisitasSubscription; // Suscripción al stream

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
    _loadMensajeSettings();
    _loadEstacionamientoSettings();
    _loadControlAccesoSettings();
    _initEstVisitasStream(); // Inicializar el stream de estVisitas
  }

  @override
  void dispose() {
    _estVisitasSubscription?.cancel(); // Cancelar la suscripción al stream
    super.dispose();
  }

  void _initEstVisitasStream() {
    _estVisitasSubscription = _estacionamientoService
        .observarEstVisitas(widget.condominioId)
        .listen((estVisitas) {
      if (mounted) {
        setState(() {
          _estVisitas = estVisitas;
        });
      }
    });
  }

  Future<void> _loadMensajeSettings() async {
    try {
      final comunicacionHabilitada = await _mensajeService
          .esComunicacionEntreResidentesHabilitada(widget.condominioId);
      
      if (mounted) {
        setState(() {
          _comunicacionEntreResidentes = comunicacionHabilitada;
        });
      }
    } catch (e) {
      print('Error al cargar configuración de mensajes: $e');
    }
  }

  Future<void> _loadEstacionamientoSettings() async {
    try {
      final configuracion = await _estacionamientoService.obtenerConfiguracion(widget.condominioId);
      if (mounted) {
        setState(() {
          _estacionamientosActivos = configuracion['activo'] ?? false;
        });
      }
    } catch (e) {
      // Error al cargar configuración de estacionamientos
    }
  }

  Future<void> _loadControlAccesoSettings() async {
    try {
      final controlAcceso = await _controlAccesoService.getControlAcceso(widget.condominioId);
      if (mounted) {
        setState(() {
          _usaEstacionamientoVisitas = controlAcceso?.usaEstacionamientoVisitas ?? false;
        });
      }
    } catch (e) {
      // Error al cargar configuración de control de acceso
    }
  }

  Future<void> _toggleComunicacionResidentes(bool value) async {
    try {
      await _mensajeService.actualizarComunicacionEntreResidentes(
        condominioId: widget.condominioId,
        permitir: value,
      );
      
      if (mounted) {
        setState(() {
          _comunicacionEntreResidentes = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'Comunicación entre residentes habilitada'
                  : 'Comunicación entre residentes deshabilitada',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCobrarMultasConGastos(bool value) async {
    try {
      await _firestoreService.updateCampoCondominio(
        widget.condominioId,
        'cobrarMultasConGastos',
        value,
      );
      
      if (mounted) {
        setState(() {
          _cobrarMultasConGastos = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'Multas se cobrarán junto con gastos comunes'
                  : 'Multas se cobrarán por separado',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCobrarEspaciosConGastos(bool value) async {
    try {
      await _firestoreService.updateCampoCondominio(
        widget.condominioId,
        'cobrarEspaciosConGastos',
        value,
      );
      
      if (mounted) {
        setState(() {
          _cobrarEspaciosConGastos = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'Espacios comunes se cobrarán junto con gastos comunes'
                  : 'Espacios comunes se cobrarán por separado',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleEstacionamientos(bool? value) async {
    if (value != null) {
      try {
        await _estacionamientoService.actualizarConfiguracion(
          widget.condominioId,
          {'activo': value},
        );
        setState(() {
          _estacionamientosActivos = value;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value 
                    ? 'Gestión de estacionamientos activada'
                    : 'Gestión de estacionamientos desactivada',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar configuración: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUsaEstacionamientoVisitas(bool? value) async {
    if (value != null) {
      try {
        await _controlAccesoService.updateUsaEstacionamientoVisitas(
          widget.condominioId,
          value,
        );
        setState(() {
          _usaEstacionamientoVisitas = value;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value 
                    ? 'Estacionamiento para visitas activado'
                    : 'Estacionamiento para visitas desactivado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar configuración: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCondominioData() async {
    try {
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      if (mounted) {
        setState(() {
          _condominio = condominio;
          _cobrarMultasConGastos = condominio?.cobrarMultasConGastos ?? false;
          _cobrarEspaciosConGastos = condominio?.cobrarEspaciosConGastos ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getConfiguracionInfo() {
    if (_condominio?.tipoCondominio == null) {
      return 'Sin configurar';
    }

    final tipo = _condominio!.tipoCondominio!;
    final total = _condominio!.calcularTotalInmuebles();
    
    switch (tipo) {
      case TipoCondominio.casas:
        return 'Casas • $total viviendas';
      case TipoCondominio.edificio:
        return 'Edificios • $total departamentos';
      case TipoCondominio.mixto:
        int casas = _condominio!.numeroCasas ?? 0;
        int deptos = total - casas;
        return 'Mixto • $casas casas, $deptos deptos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(
              _condominio?.tipoCondominio != null 
                  ? Icons.check_circle 
                  : Icons.warning,
              color: _condominio?.tipoCondominio != null 
                  ? Colors.green 
                  : Colors.orange,
            ),
            title: const Text('Configuración Viviendas del Condominio'),
            subtitle: _isLoading 
                ? const Text('Cargando...')
                : Text(_getConfiguracionInfo()),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViviendasScreen(condominioId: widget.condominioId),
                ),
              ).then((_) => _loadCondominioData());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.blue),
            title: const Text('Comunicación entre Residentes'),
            subtitle: Text(
              _comunicacionEntreResidentes
                  ? 'Los residentes pueden enviarse mensajes entre ellos'
                  : 'Solo pueden comunicarse con administración y conserjería',
            ),
            trailing: Switch(
              value: _comunicacionEntreResidentes,
              onChanged: _toggleComunicacionResidentes,
              activeColor: Colors.blue,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: const Text('Cobrar Multas con Gastos Comunes'),
            subtitle: Text(
              _cobrarMultasConGastos
                  ? 'Las multas se incluyen en el cálculo de gastos comunes'
                  : 'Las multas se cobran por separado de los gastos comunes',
            ),
            trailing: Switch(
              value: _cobrarMultasConGastos,
              onChanged: _toggleCobrarMultasConGastos,
              activeColor: Colors.green,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_work, color: Colors.purple),
            title: const Text('Cobrar Espacios Comunes con Gastos'),
            subtitle: Text(
              _cobrarEspaciosConGastos
                  ? 'Los costos de espacios comunes se incluyen en gastos comunes'
                  : 'Los espacios comunes se cobran por separado',
            ),
            trailing: Switch(
              value: _cobrarEspaciosConGastos,
              onChanged: _toggleCobrarEspaciosConGastos,
              activeColor: Colors.purple,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_parking, color: Colors.indigo),
            title: const Text('Gestión de Estacionamientos'),
            subtitle: Text(
              _estacionamientosActivos
                  ? 'Los residentes pueden gestionar estacionamientos'
                  : 'La gestión de estacionamientos está desactivada',
            ),
            trailing: Switch(
              value: _estacionamientosActivos,
              onChanged: _toggleEstacionamientos,
              activeColor: Colors.indigo,
            ),
          ),
          // Solo mostrar el switch de estacionamiento para visitas cuando estVisitas sea true
          if (_estVisitas) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.teal),
              title: const Text('Estacionamiento para visitas de libre acceso'),
              subtitle: Text(
                _usaEstacionamientoVisitas
                    ? 'Los residentes pueden usar estacionamientos para visitas sin solicitarlo previamente'
                    : 'Los residentes no pueden solicitar estacionamiento para visitas ',
              ),
              trailing: Switch(
                value: _usaEstacionamientoVisitas,
                onChanged: _toggleUsaEstacionamientoVisitas,
                activeColor: Colors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}