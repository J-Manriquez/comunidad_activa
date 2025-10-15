import 'package:flutter/material.dart';
import '../../../services/control_acceso_service.dart';
import '../../../models/control_acceso_model.dart';
import '../../../models/user_model.dart';
import 'campo_adicional_modal.dart';

class GestionCamposAdicionalesScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionCamposAdicionalesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<GestionCamposAdicionalesScreen> createState() => _GestionCamposAdicionalesScreenState();
}

class _GestionCamposAdicionalesScreenState extends State<GestionCamposAdicionalesScreen> {
  final ControlAccesoService _service = ControlAccesoService();
  Map<String, dynamic> _camposAdicionales = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCampos();
  }

  Future<void> _cargarCampos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final controlAcceso = await _service.getControlAcceso(widget.currentUser.condominioId!);
      setState(() {
        _camposAdicionales = controlAcceso?.camposAdicionales ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar los campos: $e');
    }
  }

  Future<void> _agregarCampo() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CampoAdicionalModal(),
    );

    if (resultado != null) {
      try {
        await _service.addCampoAdicional(
          widget.currentUser.condominioId!,
          resultado['nombre'],
          {
            'tipo': 'texto',
            'requerido': resultado['requerido'],
            'activo': resultado['activo'],
          },
        );
        _mostrarExito('Campo agregado exitosamente');
        await _cargarCampos(); // Actualización automática
      } catch (e) {
        _mostrarError('Error al agregar el campo: $e');
      }
    }
  }

  Future<void> _editarCampo(String clave, Map<String, dynamic> campo) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CampoAdicionalModal(
        campoExistente: campo,
        claveExistente: clave,
      ),
    );

    if (resultado != null) {
      try {
        // Si cambió el nombre, eliminar el anterior y crear uno nuevo
        if (resultado['claveAnterior'] != resultado['nombre']) {
          await _service.deleteCampoAdicional(widget.currentUser.condominioId!, resultado['claveAnterior']);
          await _service.addCampoAdicional(
            widget.currentUser.condominioId!,
            resultado['nombre'],
            {
              'tipo': 'texto',
              'requerido': resultado['requerido'],
              'activo': resultado['activo'],
            },
          );
        } else {
          await _service.updateCampoAdicional(
            widget.currentUser.condominioId!,
            resultado['nombre'],
            {
              'tipo': 'texto',
              'requerido': resultado['requerido'],
              'activo': resultado['activo'],
            },
          );
        }
        _mostrarExito('Campo actualizado exitosamente');
        await _cargarCampos(); // Actualización automática
      } catch (e) {
        _mostrarError('Error al actualizar el campo: $e');
      }
    }
  }

  Future<void> _toggleCampoActivo(String clave, Map<String, dynamic> campo) async {
    try {
      final campoActualizado = Map<String, dynamic>.from(campo);
      campoActualizado['activo'] = !(campo['activo'] ?? true);
      
      await _service.updateCampoAdicional(widget.currentUser.condominioId!, clave, campoActualizado);
      
      setState(() {
        _camposAdicionales[clave] = campoActualizado;
      });
      
      _mostrarExito(campoActualizado['activo'] 
          ? 'Campo activado exitosamente' 
          : 'Campo desactivado exitosamente');
    } catch (e) {
      _mostrarError('Error al cambiar el estado del campo: $e');
    }
  }

  Future<void> _eliminarCampo(String clave) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar el campo "$clave"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _service.deleteCampoAdicional(widget.currentUser.condominioId!, clave);
        _mostrarExito('Campo eliminado exitosamente');
        await _cargarCampos(); // Actualización automática
      } catch (e) {
        _mostrarError('Error al eliminar campo: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Campos Adicionales'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // Header con estadísticas
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campos Adicionales',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configura los campos personalizados del formulario de control de acceso',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // // Estadísticas
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _buildEstadisticaCard(
                        //         'Total',
                        //         _camposAdicionales.length.toString(),
                        //         Icons.add_box_outlined,
                        //         Colors.white.withOpacity(0.2),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 12),
                        //     Expanded(
                        //       child: _buildEstadisticaCard(
                        //         'Activos',
                        //         _camposAdicionales.values
                        //             .where((campo) => campo['activo'] == true)
                        //             .length
                        //             .toString(),
                        //         Icons.visibility,
                        //         Colors.green.withOpacity(0.2),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 12),
                        //     Expanded(
                        //       child: _buildEstadisticaCard(
                        //         'Inactivos',
                        //         _camposAdicionales.values
                        //             .where((campo) => campo['activo'] == false)
                        //             .length
                        //             .toString(),
                        //         Icons.visibility_off,
                        //         Colors.orange.withOpacity(0.2),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      
                      ],
                    ),
                  ),
                  
                  // Lista de campos
                  Expanded(
                    child: _camposAdicionales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_box_outlined,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay campos adicionales configurados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca el botón + para agregar tu primer campo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _camposAdicionales.length,
                            itemBuilder: (context, index) {
                              final clave = _camposAdicionales.keys.elementAt(index);
                              final campo = _camposAdicionales[clave];
                              return _buildCampoCard(clave, campo);
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarCampo,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Campo'),
      ),
    );
  }

  Widget _buildEstadisticaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icono, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCard(String clave, Map<String, dynamic> campo) {
    final esObligatorio = campo['obligatorio'] ?? false;
    final estaActivo = campo['activo'] ?? true;
    final etiqueta = campo['etiqueta'] ?? clave;
    final tipo = campo['tipo'] ?? 'texto';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              estaActivo ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estaActivo ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconoTipo(tipo),
                      color: estaActivo ? Colors.green[700] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                etiqueta,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            if (esObligatorio)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 12, color: Colors.red[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Obligatorio',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Clave: $clave',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle de activación
                  Container(
                    decoration: BoxDecoration(
                      color: estaActivo ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Switch(
                      value: estaActivo,
                      onChanged: (value) => _toggleCampoActivo(clave, campo),
                      activeColor: Colors.green[700],
                      inactiveThumbColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información adicional y acciones
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          _getNombreTipo(tipo),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Botones de acción
                  IconButton(
                    onPressed: () => _editarCampo(clave, campo),
                    icon: Icon(Icons.edit_outlined, color: Colors.blue[600]),
                    tooltip: 'Editar campo',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _eliminarCampo(clave),
                    icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                    tooltip: 'Eliminar campo',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo) {
      case 'texto': return Icons.text_fields;
      case 'numero': return Icons.numbers;
      case 'email': return Icons.email_outlined;
      case 'telefono': return Icons.phone_outlined;
      case 'fecha': return Icons.calendar_today_outlined;
      case 'hora': return Icons.access_time_outlined;
      case 'seleccion_simple': return Icons.radio_button_checked_outlined;
      case 'seleccion_multiple': return Icons.check_box_outlined;
      case 'booleano': return Icons.toggle_on_outlined;
      default: return Icons.text_fields;
    }
  }

  String _getNombreTipo(String tipo) {
    switch (tipo) {
      case 'texto': return 'Texto';
      case 'numero': return 'Número';
      case 'email': return 'Email';
      case 'telefono': return 'Teléfono';
      case 'fecha': return 'Fecha';
      case 'hora': return 'Hora';
      case 'seleccion_simple': return 'Selección Simple';
      case 'seleccion_multiple': return 'Selección Múltiple';
      case 'booleano': return 'Sí/No';
      default: return 'Texto';
    }
  }
}