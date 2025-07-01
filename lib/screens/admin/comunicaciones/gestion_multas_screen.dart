import 'package:flutter/material.dart';
import '../../../services/multa_service.dart';
import '../../../models/user_model.dart';
import '../../../models/multa_model.dart';

class GestionMultasScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionMultasScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  _GestionMultasScreenState createState() => _GestionMultasScreenState();
}

class _GestionMultasScreenState extends State<GestionMultasScreen> {
  final MultaService _multaService = MultaService();
  final _formKey = GlobalKey<FormState>();
  final _tipoMultaController = TextEditingController();
  final _valorController = TextEditingController();
  final _unidadMedidaController = TextEditingController();
  
  List<GestionMulta> _tiposMultas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarTiposMultas();
  }

  Future<void> _cargarTiposMultas() async {
    setState(() => _isLoading = true);
    try {
      final tipos = await _multaService.obtenerTiposMultas(widget.currentUser.condominioId.toString());
      setState(() => _tiposMultas = tipos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tipos de multas: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarTipoMulta() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _multaService.agregarTipoMulta(
          condominioId: widget.currentUser.condominioId.toString(),
          tipoMulta: _tipoMultaController.text,
          valor: int.parse(_valorController.text),
          unidadMedida: _unidadMedidaController.text,
        );
        
        _tipoMultaController.clear();
        _valorController.clear();
        _unidadMedidaController.clear();
        
        await _cargarTiposMultas();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de multa agregado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar tipo de multa: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarTipoMulta(String gestionId) async {
    try {
      await _multaService.eliminarTipoMulta(widget.currentUser.condominioId.toString(), gestionId);
      await _cargarTiposMultas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo de multa eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionador de Multas'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar Nuevo Tipo de Multa',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tipoMultaController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Multa',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el tipo de multa';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _valorController,
                                    decoration: const InputDecoration(
                                      labelText: 'Valor',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingrese el valor';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Ingrese un número válido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _unidadMedidaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Unidad de Medida',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingrese la unidad';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _agregarTipoMulta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Agregar Tipo de Multa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipos de Multas Configurados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _tiposMultas.isEmpty
                        ? const Center(
                            child: Text('No hay tipos de multas configurados'),
                          )
                        : ListView.builder(
                            itemCount: _tiposMultas.length,
                            itemBuilder: (context, index) {
                              final tipo = _tiposMultas[index];
                              return Card(
                                child: ListTile(
                                  title: Text(tipo.tipoMulta),
                                  subtitle: Text('${tipo.valor} ${tipo.unidadMedida}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarTipoMulta(tipo.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tipoMultaController.dispose();
    _valorController.dispose();
    _unidadMedidaController.dispose();
    super.dispose();
  }
}