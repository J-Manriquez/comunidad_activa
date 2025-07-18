import 'dart:convert';
import 'package:comunidad_activa/widgets/modal_entrega_correspondencia.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../models/user_model.dart';
import '../../../services/correspondencia_service.dart';

// CorrespondenciaModel está definido en correspondencia_config_model.dart
// por lo que ya está importado

class CorrespondenciasActivasScreen extends StatefulWidget {
  final String condominioId;
  final UserModel currentUser;

  const CorrespondenciasActivasScreen({
    super.key,
    required this.condominioId,
    required this.currentUser,
  });

  @override
  State<CorrespondenciasActivasScreen> createState() =>
      _CorrespondenciasActivasScreenState();
}

class _CorrespondenciasActivasScreenState
    extends State<CorrespondenciasActivasScreen> {
  final CorrespondenciaService _correspondenciaService =
      CorrespondenciaService();
  CorrespondenciaConfigModel? _config;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await _correspondenciaService.getCorrespondenciaConfig(
        widget.condominioId,
      );
      if (mounted) {
        setState(() {
          _config = config;
        });
      }
    } catch (e) {
      print('Error al cargar configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondencias Activas'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CorrespondenciaModel>>(
        stream: _correspondenciaService.getCorrespondencias(
          widget.condominioId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar correspondencias',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final correspondencias = snapshot.data ?? [];

          // Filtrar solo correspondencias activas (sin fecha de entrega)
          final correspondenciasActivas = correspondencias
              .where(
                (c) =>
                    c.fechaHoraEntrega == null || c.fechaHoraEntrega!.isEmpty,
              )
              .toList();

          if (correspondenciasActivas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay correspondencias activas',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las correspondencias aparecerán aquí cuando se registren',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: correspondenciasActivas.length,
            itemBuilder: (context, index) {
              final correspondencia = correspondenciasActivas[index];
              return _buildCorrespondenciaCard(correspondencia);
            },
          );
        },
      ),
    );
  }

  Widget _buildCorrespondenciaCard(CorrespondenciaModel correspondencia) {
    final fechaRecepcion = DateTime.tryParse(
      correspondencia.fechaHoraRecepcion,
    );
    final fechaFormateada = fechaRecepcion != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRecepcion)
        : correspondencia.fechaHoraRecepcion;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => _mostrarDetallesCorrespondencia(correspondencia),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTipoColor(correspondencia.tipoCorrespondencia),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      correspondencia.tipoCorrespondencia.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    fechaFormateada,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tipo de entrega
              Row(
                children: [
                  Icon(
                    _getTipoEntregaIcon(correspondencia.tipoEntrega),
                    size: 20,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    correspondencia.tipoEntrega,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Datos de entrega
              Text(
                'Entrega: ${correspondencia.datosEntrega}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),

              // Vivienda de recepción (si aplica)
              if (correspondencia.viviendaRecepcion != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Recepción: ${correspondencia.viviendaRecepcion}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],

              // Adjuntos
              if (correspondencia.adjuntos != null &&
                  correspondencia.adjuntos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${correspondencia.adjuntos!.length} archivo(s) adjunto(s)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'paquete':
        return Colors.blue.shade600;
      case 'carta':
        return Colors.green.shade600;
      case 'boleta':
        return Colors.orange.shade600;
      default:
        return Colors.purple.shade600;
    }
  }

  IconData _getTipoEntregaIcon(String tipoEntrega) {
    switch (tipoEntrega) {
      case 'A un residente':
        return Icons.person;
      case 'Entre residentes':
        return Icons.people;
      case 'Residente a un tercero':
        return Icons.person_outline;
      default:
        return Icons.mail;
    }
  }

  void _mostrarDetallesCorrespondencia(CorrespondenciaModel correspondencia) {
    showDialog(
      context: context,
      builder: (context) => _DetalleCorrespondenciaModal(
        condominioId: widget.condominioId,
        correspondencia: correspondencia,
        config: _config,
        currentUser: widget.currentUser,
        onCorrespondenciaActualizada: () {
          // Trigger rebuild to refresh the list
          setState(() {});
        },
      ),
    );
  }

  Future<void> _abrirModalEntrega(CorrespondenciaModel correspondencia) async {
    if (_config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando configuración...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEntregaCorrespondencia(
        condominioId: widget.condominioId,
        correspondencia: correspondencia,
        config: _config!,
      ),
    );

    if (resultado == true && mounted) {
      // La entrega fue exitosa, el modal ya mostró el mensaje de éxito
      // No necesitamos hacer nada adicional aquí
    }
  }
}

class _DetalleCorrespondenciaModal extends StatefulWidget {
  final String condominioId;
  final CorrespondenciaModel correspondencia;
  final CorrespondenciaConfigModel? config;
  final UserModel currentUser;
  final VoidCallback onCorrespondenciaActualizada;

  const _DetalleCorrespondenciaModal({
    required this.condominioId,
    required this.correspondencia,
    required this.config,
    required this.currentUser,
    required this.onCorrespondenciaActualizada,
  });

  @override
  State<_DetalleCorrespondenciaModal> createState() => _DetalleCorrespondenciaModalState();
}

class _DetalleCorrespondenciaModalState extends State<_DetalleCorrespondenciaModal> {
  final TextEditingController _nuevoMensajeController = TextEditingController();
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  bool _guardandoMensaje = false;
  bool _enviarNotificacion = false;

  @override
  void dispose() {
    _nuevoMensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles de Correspondencia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetalleRow('Tipo:', widget.correspondencia.tipoCorrespondencia),
                    _buildDetalleRow('Tipo de entrega:', widget.correspondencia.tipoEntrega),
                    _buildDetalleRow('Datos de entrega:', widget.correspondencia.datosEntrega),
                    if (widget.correspondencia.viviendaRecepcion != null)
                      _buildDetalleRow('Vivienda de recepción:', widget.correspondencia.viviendaRecepcion!),
                    _buildDetalleRow('Fecha de recepción:', _formatearFecha(widget.correspondencia.fechaHoraRecepcion)),
                    if (widget.correspondencia.fechaHoraEntrega != null)
                      _buildDetalleRow('Fecha de entrega:', _formatearFecha(widget.correspondencia.fechaHoraEntrega!)),
                    
                    const SizedBox(height: 16),
                    
                    // Adjuntos
                    if (widget.correspondencia.adjuntos.isNotEmpty) ...[
                      Text(
                        'Adjuntos:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAdjuntos(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Mensajes adicionales existentes
                    if (widget.correspondencia.infAdicional != null && widget.correspondencia.infAdicional!.isNotEmpty) ...[
                      Text(
                        'Mensajes adicionales:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMensajesExistentes(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Campo para nuevo mensaje
                    Text(
                      'Añadir nuevo mensaje:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNuevoMensaje(),
                  ],
                ),
              ),
            ),
            
            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.currentUser.tipoUsuario == UserType.administrador &&
                    widget.correspondencia.fechaHoraEntrega == null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _abrirModalEntrega();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Marcar como Entregada'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  Widget _buildAdjuntos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.correspondencia.adjuntos.entries.map((entry) {
        return GestureDetector(
          onTap: () => _mostrarImagenCompleta(entry.value),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(entry.value),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMensajesExistentes() {
    final mensajes = widget.correspondencia.infAdicional!;
    
    return Column(
      children: mensajes.map((mensaje) {
        final texto = mensaje['mensaje'] ?? '';
        final fechaHora = mensaje['fechaHora'] ?? '';
        final usuarioId = mensaje['usuarioId'] ?? '';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Por: $usuarioId - ${_formatearFecha(fechaHora)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNuevoMensaje() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nuevoMensajeController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribir nuevo mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _guardandoMensaje ? null : _guardarNuevoMensaje,
              icon: _guardandoMensaje
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _enviarNotificacion,
              onChanged: (value) {
                setState(() {
                  _enviarNotificacion = value ?? false;
                });
              },
            ),
            const Text('Enviar notificación al residente'),
          ],
        ),
      ],
    );
  }

  String _formatearFecha(String fechaHora) {
    try {
      final fecha = DateTime.parse(fechaHora);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return fechaHora;
    }
  }

  void _mostrarImagenCompleta(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Imagen adjunta'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarNuevoMensaje() async {
    final mensaje = _nuevoMensajeController.text.trim();
    if (mensaje.isEmpty) return;

    setState(() {
      _guardandoMensaje = true;
    });

    try {
      final now = DateTime.now();
      final fechaHora = now.toIso8601String();
      
      final nuevoMensaje = {
        'mensaje': mensaje,
        'fechaHora': fechaHora,
        'usuarioId': widget.currentUser.tipoUsuario == UserType.administrador ? 'admin' : widget.currentUser.uid,
      };

      // Obtener la lista actual de mensajes o crear una nueva
      final mensajesActuales = widget.correspondencia.infAdicional ?? [];
      final nuevaListaMensajes = [...mensajesActuales, nuevoMensaje];

      await _correspondenciaService.updateCorrespondencia(
        widget.condominioId,
        widget.correspondencia.id,
        {'infAdicional': nuevaListaMensajes},
      );

      // Enviar notificación si está marcado el checkbox
      if (_enviarNotificacion && widget.correspondencia.residenteIdEntrega != null) {
        await _correspondenciaService.enviarNotificacionMensajeAdicional(
          widget.condominioId,
          widget.correspondencia.residenteIdEntrega!,
          widget.correspondencia.id,
          mensaje,
          widget.correspondencia,
        );
      }

      _nuevoMensajeController.clear();
      setState(() {
        _enviarNotificacion = false;
      });
      widget.onCorrespondenciaActualizada();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enviarNotificacion 
              ? 'Mensaje guardado y notificación enviada exitosamente'
              : 'Mensaje guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardandoMensaje = false;
        });
      }
    }
  }

  Future<void> _abrirModalEntrega() async {
    if (widget.config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando configuración...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalEntregaCorrespondencia(
        condominioId: widget.condominioId,
        correspondencia: widget.correspondencia,
        config: widget.config!,
      ),
    );

    if (resultado == true && mounted) {
      widget.onCorrespondenciaActualizada();
      Navigator.of(context).pop();
    }
  }
}
