import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';

class GestionTiposTrabajadoresScreen extends StatefulWidget {
  final String condominioId;

  const GestionTiposTrabajadoresScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<GestionTiposTrabajadoresScreen> createState() =>
      _GestionTiposTrabajadoresScreenState();
}

class _GestionTiposTrabajadoresScreenState
    extends State<GestionTiposTrabajadoresScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, String> _tiposTrabajadores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTiposTrabajadores();
  }

  Future<void> _loadTiposTrabajadores() async {
    try {
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      if (mounted) {
        setState(() {
          _tiposTrabajadores = condominio?.tiposTrabajadores ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tipos de trabajadores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTiposTrabajadores() async {
    try {
      // Primero obtenemos el condominio actual
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      if (condominio != null) {
        // Creamos una nueva instancia con los tipos de trabajadores actualizados
        final condominioActualizado = CondominioModel(
          id: condominio.id,
          nombre: condominio.nombre,
          direccion: condominio.direccion,
          fechaCreacion: condominio.fechaCreacion,
          pruebaActiva: condominio.pruebaActiva,
          fechaFinPrueba: condominio.fechaFinPrueba,
          comunicacionEntreResidentes: condominio.gestionFunciones.chatEntreRes,
          tipoCondominio: condominio.tipoCondominio,
          numeroCasas: condominio.numeroCasas,
          rangoCasas: condominio.rangoCasas,
          numeroTorres: condominio.numeroTorres,
          apartamentosPorTorre: condominio.apartamentosPorTorre,
          numeracion: condominio.numeracion,
          etiquetasTorres: condominio.etiquetasTorres,
          rangoTorres: condominio.rangoTorres,
          edificiosIguales: condominio.edificiosIguales,
          configuracionesEdificios: condominio.configuracionesEdificios,
          totalInmuebles: condominio.totalInmuebles,
          requiereConfirmacionAdmin: condominio.requiereConfirmacionAdmin,
          gestionMultas: condominio.gestionMultas,
          gestionReclamos: condominio.gestionReclamos,
          cobrarMultasConGastos: condominio.cobrarMultasConGastos,
          cobrarEspaciosConGastos: condominio.cobrarEspaciosConGastos,
          tiposTrabajadores: _tiposTrabajadores,
        );
        
        await _firestoreService.updateCondominioData(condominioActualizado);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipos de trabajadores actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTipoTrabajadorModal({String? tipoId, String? tipoNombre}) {
    final TextEditingController controller = TextEditingController(text: tipoNombre ?? '');
    final bool isEditing = tipoId != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Tipo de Trabajador' : 'Nuevo Tipo de Trabajador'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del tipo de trabajador',
              hintText: 'Ej: Conserje, Guardia, Jardinero',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = controller.text.trim();
                if (nombre.isNotEmpty) {
                  setState(() {
                    if (isEditing) {
                      // Si estamos editando, eliminamos el tipo anterior y agregamos el nuevo
                      _tiposTrabajadores.remove(tipoId);
                    }
                    // Usamos el nombre como clave y valor para simplicidad
                    final key = DateTime.now().millisecondsSinceEpoch.toString();
                    _tiposTrabajadores[key] = nombre;
                  });
                  _saveTiposTrabajadores();
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarTipoTrabajador(String tipoId, String tipoNombre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el tipo de trabajador "$tipoNombre"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _tiposTrabajadores.remove(tipoId);
                });
                _saveTiposTrabajadores();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipos de Trabajadores'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tiposTrabajadores.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay tipos de trabajadores configurados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Usa el botón + para agregar el primer tipo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tiposTrabajadores.length,
                  itemBuilder: (context, index) {
                    final entry = _tiposTrabajadores.entries.elementAt(index);
                    final tipoId = entry.key;
                    final tipoNombre = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.work,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          tipoNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text('ID: $tipoId'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              _showTipoTrabajadorModal(
                                tipoId: tipoId,
                                tipoNombre: tipoNombre,
                              );
                            } else if (value == 'eliminar') {
                              _eliminarTipoTrabajador(tipoId, tipoNombre);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'editar',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTipoTrabajadorModal(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}