import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/control_acceso_service.dart';
import '../../../models/control_acceso_model.dart';
import 'gestion_campos_adicionales_screen.dart';

class CamposActivosScreen extends StatefulWidget {
  final UserModel currentUser;
  
  const CamposActivosScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<CamposActivosScreen> createState() => _CamposActivosScreenState();
}

class _CamposActivosScreenState extends State<CamposActivosScreen> {
  final ControlAccesoService _service = ControlAccesoService();
  Map<String, dynamic> _camposActivos = {};
  Map<String, dynamic> _camposAdicionales = {};
  bool _isLoading = true;

  // Definición de campos del formulario con sus descripciones
  final Map<String, Map<String, dynamic>> _camposFormulario = {
    'nombre': {
      'descripcion': 'Nombre completo de la persona que ingresa',
      'obligatorio': true,
      'icono': Icons.person,
    },
    'vivienda': {
      'descripcion': 'Número o identificación de la vivienda de destino',
      'obligatorio': true,
      'icono': Icons.home,
    },
    'rut': {
      'descripcion': 'RUT o documento de identidad de la persona',
      'obligatorio': false,
      'icono': Icons.badge,
    },
    'tipoIngreso': {
      'descripcion': 'Tipo de persona que ingresa (residente, visita, trabajador, etc.)',
      'obligatorio': false,
      'icono': Icons.category,
    },
    'tipoTransporte': {
      'descripcion': 'Medio de transporte utilizado para el ingreso',
      'obligatorio': false,
      'icono': Icons.directions_car,
    },
    'hora': {
      'descripcion': 'Hora de ingreso al condominio',
      'obligatorio': false,
      'icono': Icons.access_time,
    },
    'usaEstacionamiento': {
      'descripcion': 'Indica si utilizará estacionamiento (depende del tipo de transporte)',
      'obligatorio': false,
      'dependeDe': 'tipoTransporte',
      'icono': Icons.local_parking,
    },
    'tipoAuto': {
      'descripcion': 'Tipo de vehículo (auto, camioneta, etc.) - solo si usa transporte vehicular',
      'obligatorio': false,
      'dependeDe': 'tipoTransporte',
      'icono': Icons.directions_car_filled,
    },
    'color': {
      'descripcion': 'Color del vehículo - solo si usa transporte vehicular',
      'obligatorio': false,
      'dependeDe': 'tipoTransporte',
      'icono': Icons.palette,
    },
    'patente': {
      'descripcion': 'Patente o placa del vehículo - solo si usa transporte vehicular',
      'obligatorio': false,
      'dependeDe': 'tipoTransporte',
      'icono': Icons.confirmation_number,
    },
  };

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final controlAcceso = await _service.getControlAcceso(widget.currentUser.condominioId!);
      
      setState(() {
        _camposActivos = controlAcceso?.camposActivos ?? _getDefaultCamposActivos();
        _camposAdicionales = controlAcceso?.camposAdicionales ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar los datos: $e');
    }
  }

  Map<String, dynamic> _getDefaultCamposActivos() {
    Map<String, dynamic> defaults = {};
    for (String campo in _camposFormulario.keys) {
      defaults[campo] = _camposFormulario[campo]!['obligatorio'] == true;
    }
    return defaults;
  }

  Future<void> _toggleCampo(String campo) async {
    // No permitir desactivar campos obligatorios
    if (_camposFormulario[campo]?['obligatorio'] == true) {
      _mostrarError('Este campo es obligatorio y no se puede desactivar');
      return;
    }

    try {
      final nuevoEstado = !(_camposActivos[campo] ?? false);
      
      // Si se desactiva tipoTransporte, también desactivar sus dependientes
      if (campo == 'tipoTransporte' && !nuevoEstado) {
        _camposActivos['usaEstacionamiento'] = false;
        _camposActivos['tipoAuto'] = false;
        _camposActivos['color'] = false;
      }
      
      _camposActivos[campo] = nuevoEstado;
      
      await _service.updateCamposActivos(widget.currentUser.condominioId!, _camposActivos);
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado ? 'Campo activado' : 'Campo desactivado'),
          backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      _mostrarError('Error al actualizar el campo: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _puedeActivarCampo(String campo) {
    final dependeDe = _camposFormulario[campo]?['dependeDe'];
    if (dependeDe != null) {
      return _camposActivos[dependeDe] == true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campos Activos'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[700]!,
              Colors.orange[50]!,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de Campos del Formulario',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Activa o desactiva los campos que aparecerán en el formulario de control de acceso',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de campos
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Campos obligatorios
                        _buildSeccionHeader('Campos Obligatorios', 
                          'Estos campos siempre aparecen en el formulario'),
                        
                        ..._camposFormulario.entries
                            .where((entry) => entry.value['obligatorio'] == true)
                            .map((entry) => _buildCampoCard(entry.key, entry.value, true)),
                        
                        const SizedBox(height: 20),
                        
                        // Campos opcionales
                        _buildSeccionHeader('Campos Opcionales', 
                          'Puedes activar o desactivar estos campos'),
                        
                        ..._camposFormulario.entries
                            .where((entry) => entry.value['obligatorio'] != true)
                            .map((entry) => _buildCampoCard(entry.key, entry.value, false)),
                        
                        const SizedBox(height: 20),
                        
                        // Campos adicionales
                        // if (_camposAdicionales.isNotEmpty) ...[
                        //   _buildSeccionHeader('Campos Adicionales Configurados', 
                        //     'Campos personalizados creados por el administrador'),
                          
                        //   ..._camposAdicionales.entries.map((entry) => 
                        //     _buildCampoAdicionalCard(entry.key, entry.value)),
                        // ],
                        
                        // const SizedBox(height: 20),
                        
                        // Cuadro de navegación a campos adicionales
                        _buildCamposAdicionalesCard(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo, String descripcion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCard(String campo, Map<String, dynamic> info, bool esObligatorio) {
    final estaActivo = _camposActivos[campo] ?? false;
    final puedeActivar = _puedeActivarCampo(campo);
    final dependeDe = info['dependeDe'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estaActivo ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            info['icono'],
            color: estaActivo ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        title: Text(
          _getCampoDisplayName(campo),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: esObligatorio ? Colors.blue[800] : Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info['descripcion']),
            if (dependeDe != null)
              Text(
                'Depende de: ${_getCampoDisplayName(dependeDe)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (esObligatorio)
              Text(
                'Campo obligatorio',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: esObligatorio
            ? Icon(Icons.lock, color: Colors.blue[700])
            : Switch(
                value: estaActivo,
                onChanged: puedeActivar ? (value) => _toggleCampo(campo) : null,
                activeColor: Colors.green,
              ),
      ),
    );
  }

  Widget _buildCampoAdicionalCard(String clave, Map<String, dynamic> campo) {
    final estaActivo = campo['activo'] ?? true;
    final etiqueta = campo['etiqueta'] ?? clave;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estaActivo ? Colors.purple[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.extension,
            color: estaActivo ? Colors.purple[700] : Colors.grey[600],
          ),
        ),
        title: Text(
          etiqueta,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text('Campo adicional personalizado'),
        trailing: Icon(
          estaActivo ? Icons.visibility : Icons.visibility_off,
          color: estaActivo ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCamposAdicionalesCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_box_outlined,
              color: Colors.blue[800],
              size: 28,
            ),
          ),
          title: Text(
            'Gestión de Campos Adicionales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          subtitle: Text(
            'Los campos adicionales se activan en su propia pantalla de gestión. Toca aquí para crear, editar o configurar campos personalizados.',
            style: TextStyle(
              color: Colors.blue[700],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue[700],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GestionCamposAdicionalesScreen(
                  currentUser: widget.currentUser,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCampoDisplayName(String campo) {
    switch (campo) {
      case 'nombre':
        return 'Nombre';
      case 'vivienda':
        return 'Vivienda';
      case 'rut':
        return 'RUT';
      case 'tipoIngreso':
        return 'Tipo de Ingreso';
      case 'tipoTransporte':
        return 'Tipo de Transporte';
      case 'hora':
        return 'Hora';
      case 'usaEstacionamiento':
        return 'Usa Estacionamiento';
      case 'tipoAuto':
        return 'Tipo de Auto';
      case 'color':
        return 'Color del Vehículo';
      default:
        return campo;
    }
  }
}