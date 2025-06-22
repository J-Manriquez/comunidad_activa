import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/reclamo_service.dart';

class CrearReclamoScreen extends StatefulWidget {
  final UserModel currentUser;

  const CrearReclamoScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _CrearReclamoScreenState createState() => _CrearReclamoScreenState();
}

class _CrearReclamoScreenState extends State<CrearReclamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contenidoController = TextEditingController();
  final _tipoPersonalizadoController = TextEditingController();
  final ReclamoService _reclamoService = ReclamoService();
  
  String? _tipoSeleccionado;
  bool _usarTipoPersonalizado = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Crear Reclamo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del usuario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.person,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviado por:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.currentUser.nombre ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Tipo de reclamo
              const Text(
                'Tipo de Reclamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Seleccione el tipo de reclamo',
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  ..._reclamoService.getTiposReclamoDisponibles().map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value;
                    _usarTipoPersonalizado = value == 'Otro';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor seleccione un tipo de reclamo';
                  }
                  return null;
                },
              ),
              
              // Campo personalizado si selecciona "Otro"
              if (_usarTipoPersonalizado) ...[
                const SizedBox(height: 16),
                const Text(
                  'Especifique el tipo de reclamo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tipoPersonalizadoController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Ingrese el tipo de reclamo',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (_usarTipoPersonalizado && (value == null || value.isEmpty)) {
                      return 'Por favor especifique el tipo de reclamo';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Descripción del reclamo
              const Text(
                'Descripción del Reclamo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contenidoController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Describa detalladamente su reclamo...',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción del reclamo';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),
              
              // Botón para enviar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearReclamo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enviar Reclamo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _crearReclamo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        String tipoReclamo = _usarTipoPersonalizado 
            ? _tipoPersonalizadoController.text 
            : _tipoSeleccionado!;
            
        await _reclamoService.crearReclamo(
          condominioId: widget.currentUser.condominioId.toString(),
          residenteId: widget.currentUser.uid,
          tipoReclamo: tipoReclamo,
          contenido: _contenidoController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reclamo enviado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar reclamo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _contenidoController.dispose();
    _tipoPersonalizadoController.dispose();
    super.dispose();
  }
}