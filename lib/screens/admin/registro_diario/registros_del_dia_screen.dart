import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/registro_diario_model.dart';
import '../../../services/registro_diario_service.dart';
import '../../../widgets/image_carousel_widget.dart';
import '../../../utils/image_fullscreen_helper.dart';
import '../../../utils/image_display_widget.dart';

class RegistrosDelDiaScreen extends StatefulWidget {
  final String condominioId;

  const RegistrosDelDiaScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<RegistrosDelDiaScreen> createState() => _RegistrosDelDiaScreenState();
}

class _RegistrosDelDiaScreenState extends State<RegistrosDelDiaScreen> {
  final RegistroDiarioService _registroDiarioService = RegistroDiarioService();
  bool _isLoading = true;
  List<RegistroDiario> _registrosDelDia = [];
  String _fechaActual = '';

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  void _inicializarDatos() {
    _fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _cargarRegistrosDelDia();
  }

  Future<void> _cargarRegistrosDelDia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final registros = await _registroDiarioService.obtenerRegistrosPorFecha(
        condominioId: widget.condominioId,
        fecha: DateTime.now(),
      );

      setState(() {
        _registrosDelDia = registros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar registros: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> _obtenerImagenesRegistro(RegistroDiario registro) {
    List<Map<String, dynamic>> imagenes = [];
    
    if (registro.additionalData != null) {
      if (registro.additionalData!['imagen1'] != null) {
        imagenes.add(registro.additionalData!['imagen1']);
      }
      if (registro.additionalData!['imagen2'] != null) {
        imagenes.add(registro.additionalData!['imagen2']);
      }
    }
    
    return imagenes;
  }

  Widget _buildImageCarousel(RegistroDiario registro) {
    final imagenes = _obtenerImagenesRegistro(registro);
    
    if (imagenes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
              SizedBox(height: 4),
              Text('Sin imágenes', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: ImageCarouselWidget(
          images: imagenes,
          height: 100,
          borderRadius: BorderRadius.circular(8.0),
          onImageTap: (imageData) {
            ImageFullscreenHelper.showFullscreenImage(context, imageData);
          },
        ),
      ),
    );
  }

  Widget _buildRegistroCard(RegistroDiario registro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesModal(registro),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen del registro - Lado izquierdo
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: _buildImageCarousel(registro),
              ),
              const SizedBox(width: 12),
              // Información del registro - Lado derecho
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con hora y usuario
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          registro.hora,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTipoUsuarioColor(registro.tipoUsuario),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            registro.tipoUsuario.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Nombre del usuario
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            registro.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Comentario (preview)
                    Text(
                      registro.comentario,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTipoUsuarioColor(String tipoUsuario) {
    switch (tipoUsuario.toLowerCase()) {
      case 'administrador':
        return Colors.red.shade600;
      case 'trabajador':
        return Colors.orange.shade600;
      case 'residente':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _mostrarDetallesModal(RegistroDiario registro) {
    showDialog(
      context: context,
      builder: (context) => _DetalleRegistroModal(
        registro: registro,
        condominioId: widget.condominioId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros del Día'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRegistrosDelDia,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con fecha actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Registros del ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_registrosDelDia.length} registros',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de registros
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _registrosDelDia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay registros para hoy',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los registros creados hoy aparecerán aquí',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarRegistrosDelDia,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _registrosDelDia.length,
                          itemBuilder: (context, index) {
                            return _buildRegistroCard(_registrosDelDia[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Modal para mostrar detalles del registro
class _DetalleRegistroModal extends StatelessWidget {
  final RegistroDiario registro;
  final String condominioId;

  const _DetalleRegistroModal({
    required this.registro,
    required this.condominioId,
  });

  List<Map<String, dynamic>> _obtenerImagenesRegistro() {
    List<Map<String, dynamic>> imagenes = [];
    
    if (registro.additionalData != null) {
      if (registro.additionalData!['imagen1'] != null) {
        imagenes.add(registro.additionalData!['imagen1']);
      }
      if (registro.additionalData!['imagen2'] != null) {
        imagenes.add(registro.additionalData!['imagen2']);
      }
    }
    
    return imagenes;
  }

  Widget _buildImagenesGrid(BuildContext context) {
    final imagenes = _obtenerImagenesRegistro();
    
    if (imagenes.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('No hay imágenes disponibles', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imagenes.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ImageFullscreenHelper.showFullscreenImage(context, imagenes[index]);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageDisplayWidget(
                imageData: imagenes[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.blue.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_note,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido del modal
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Hora del Registro',
                      value: registro.hora,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'Usuario',
                      value: registro.nombre,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.badge,
                      label: 'Tipo de Usuario',
                      value: registro.tipoUsuario.toUpperCase(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Comentario del registro
                    const Text(
                      'Comentario:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        registro.comentario,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Imágenes en formato grid
                    const Text(
                      'Imágenes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagenesGrid(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}