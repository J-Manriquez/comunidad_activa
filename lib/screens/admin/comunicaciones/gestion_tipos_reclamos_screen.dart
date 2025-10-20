import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/tipo_reclamo_model.dart';
import '../../../services/reclamo_service.dart';

class GestionTiposReclamosScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionTiposReclamosScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _GestionTiposReclamosScreenState createState() =>
      _GestionTiposReclamosScreenState();
}

class _GestionTiposReclamosScreenState
    extends State<GestionTiposReclamosScreen> {
  final ReclamoService _reclamoService = ReclamoService();
  List<TipoReclamo> _tiposReclamo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTiposReclamo();
  }

  Future<void> _cargarTiposReclamo() async {
    setState(() => _isLoading = true);
    try {
      final tipos = await _reclamoService.getTiposReclamoDisponibles(
        widget.currentUser.condominioId.toString(),
      );
      setState(() {
        _tiposReclamo = tipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tipos de reclamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarModalCrearTipo() async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => _TipoReclamoFormDialog(),
    );

    if (resultado != null && resultado.isNotEmpty) {
      await _crearTipoReclamo(resultado);
    }
  }

  Future<void> _mostrarModalEditarTipo(TipoReclamo tipo) async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => _TipoReclamoFormDialog(tipoInicial: tipo.tipoReclamo),
    );

    if (resultado != null && resultado.isNotEmpty) {
      await _actualizarTipoReclamo(tipo.id, resultado);
    }
  }

  Future<void> _crearTipoReclamo(String tipoReclamo) async {
    try {
      await _reclamoService.crearTipoReclamo(
        widget.currentUser.condominioId.toString(),
        tipoReclamo,
      );
      await _cargarTiposReclamo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de reclamo creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear tipo de reclamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actualizarTipoReclamo(String tipoId, String nuevoTipo) async {
    try {
      await _reclamoService.actualizarTipoReclamo(
        widget.currentUser.condominioId.toString(),
        tipoId,
        nuevoTipo,
      );
      await _cargarTiposReclamo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de reclamo actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar tipo de reclamo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarTipoReclamo(TipoReclamo tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de que desea eliminar el tipo de reclamo "${tipo.tipoReclamo}"?',
        ),
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
        await _reclamoService.eliminarTipoReclamo(
          widget.currentUser.condominioId.toString(),
          tipo.id,
        );
        await _cargarTiposReclamo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de reclamo eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar tipo de reclamo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestión de Tipos de Reclamos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con botón para crear nuevo tipo
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: _mostrarModalCrearTipo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.green[600]!, Colors.green[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crear Nuevo Tipo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Añadir un nuevo tipo de reclamo',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Lista de tipos de reclamos
                Expanded(
                  child: _tiposReclamo.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay tipos de reclamos configurados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea el primer tipo de reclamo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tiposReclamo.length,
                          itemBuilder: (context, index) {
                            final tipo = _tiposReclamo[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  tipo.tipoReclamo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'ID: ${tipo.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _mostrarModalEditarTipo(tipo),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue[700],
                                      ),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      onPressed: () => _eliminarTipoReclamo(tipo),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// Dialog para crear/editar tipos de reclamos
class _TipoReclamoFormDialog extends StatefulWidget {
  final String? tipoInicial;

  const _TipoReclamoFormDialog({Key? key, this.tipoInicial}) : super(key: key);

  @override
  _TipoReclamoFormDialogState createState() => _TipoReclamoFormDialogState();
}

class _TipoReclamoFormDialogState extends State<_TipoReclamoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tipoInicial != null) {
      _tipoController.text = widget.tipoInicial!;
    }
  }

  @override
  void dispose() {
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tipoInicial != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Editar Tipo de Reclamo' : 'Crear Tipo de Reclamo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tipoController,
              decoration: InputDecoration(
                labelText: 'Nombre del tipo de reclamo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese un nombre para el tipo de reclamo';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_tipoController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isEditing ? Colors.blue[700] : Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}