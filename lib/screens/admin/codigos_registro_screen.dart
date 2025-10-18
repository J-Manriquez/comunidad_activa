import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/codigo_registro_model.dart';
import '../../services/codigo_registro_service.dart';
import '../../services/auth_service.dart';
import 'crear_editar_codigo_registro_screen.dart';

class CodigosRegistroScreen extends StatefulWidget {
  final String condominioId;
  
  const CodigosRegistroScreen({Key? key, required this.condominioId}) : super(key: key);

  @override
  State<CodigosRegistroScreen> createState() => _CodigosRegistroScreenState();
}

class _CodigosRegistroScreenState extends State<CodigosRegistroScreen> {
  final CodigoRegistroService _codigoService = CodigoRegistroService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos de Registro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navegarACrearCodigo(),
          ),
        ],
      ),
      body: StreamBuilder<List<CodigoRegistroModel>>(
        stream: _codigoService.obtenerCodigosCondominio(widget.condominioId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final codigos = snapshot.data ?? [];

          if (codigos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay códigos de registro',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navegarACrearCodigo(),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer código'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codigos.length,
            itemBuilder: (context, index) {
              final codigo = codigos[index];
              return _buildCodigoCard(codigo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarACrearCodigo(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCodigoCard(CodigoRegistroModel codigo) {
    Color estadoColor = codigo.isActivo ? Colors.green : Colors.red;
    IconData estadoIcon = codigo.isActivo ? Icons.check_circle : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        codigo.codigo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipo: ${_getTipoUsuarioText(codigo.tipoUsuario)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  estadoIcon,
                  color: estadoColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Usuarios: ${codigo.usuariosRegistrados.length}/${codigo.cantUsuarios}',
                    codigo.isLleno ? Colors.red : Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    codigo.isActivo ? 'Activo' : 'Inactivo',
                    estadoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Creado: ${_formatearFecha(codigo.fechaIngreso)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _mostrarDetallesCodigo(codigo),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver'),
                ),
                TextButton.icon(
                  onPressed: () => _navegarAEditarCodigo(codigo),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _cambiarEstadoCodigo(codigo),
                  icon: Icon(
                    codigo.isActivo ? Icons.block : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(codigo.isActivo ? 'Desactivar' : 'Activar'),
                  style: TextButton.styleFrom(
                    foregroundColor: codigo.isActivo ? Colors.red : Colors.green,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'eliminar') {
                      _confirmarEliminarCodigo(codigo);
                    }
                  },
                  itemBuilder: (context) => [
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getTipoUsuarioText(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'residente':
        return 'Residente';
      case 'trabajador':
        return 'Trabajador';
      case 'comite':
        return 'Comité';
      default:
        return tipo;
    }
  }

  String _formatearFecha(String fecha) {
    try {
      DateTime dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }

  void _navegarACrearCodigo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarCodigoRegistroScreen(condominioId: widget.condominioId),
      ),
    );
  }

  void _navegarAEditarCodigo(CodigoRegistroModel codigo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEditarCodigoRegistroScreen(codigo: codigo, condominioId: widget.condominioId),
      ),
    );
  }

  void _mostrarDetallesCodigo(CodigoRegistroModel codigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Código'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Código:', codigo.codigo),
              _buildDetalleRow('Tipo de Usuario:', _getTipoUsuarioText(codigo.tipoUsuario)),
              _buildDetalleRow('Capacidad:', '${codigo.usuariosRegistrados.length}/${codigo.cantUsuarios}'),
              _buildDetalleRow('Estado:', codigo.isActivo ? 'Activo' : 'Inactivo'),
              _buildDetalleRow('Fecha de Creación:', _formatearFecha(codigo.fechaIngreso)),
              const SizedBox(height: 16),
              if (codigo.usuariosRegistrados.isNotEmpty) ...[
                const Text(
                  'Usuarios Registrados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...codigo.usuariosRegistrados.map((usuario) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${usuario.nombre} (${_formatearFecha(usuario.fecha)})'),
                )),
              ] else
                const Text('No hay usuarios registrados con este código.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstadoCodigo(CodigoRegistroModel codigo) async {
    String nuevoEstado = codigo.isActivo ? 'inactivo' : 'activo';
    String accion = codigo.isActivo ? 'desactivar' : 'activar';

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar ${accion}'),
        content: Text('¿Está seguro que desea $accion este código?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: codigo.isActivo ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(accion.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      bool exito = await _codigoService.cambiarEstadoCodigo(
        condominioId: widget.condominioId,
        codigoId: codigo.id,
        nuevoEstado: nuevoEstado,
      );

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código ${accion}do exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado del código'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminarCodigo(CodigoRegistroModel codigo) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Está seguro que desea eliminar este código?'),
            const SizedBox(height: 8),
            Text('Código: ${codigo.codigo}'),
            if (codigo.usuariosRegistrados.isNotEmpty)
              Text('Usuarios registrados: ${codigo.usuariosRegistrados.length}'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      bool exito = await _codigoService.eliminarCodigoRegistro(
        condominioId: widget.condominioId,
        codigoId: codigo.id,
      );

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar el código'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}