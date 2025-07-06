import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/publicacion_service.dart';
import '../../comunicaciones/ver_publicacion_screen.dart';

class PublicacionesResidenteScreen extends StatefulWidget {
  final UserModel currentUser;

  const PublicacionesResidenteScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<PublicacionesResidenteScreen> createState() => _PublicacionesResidenteScreenState();
}

class _PublicacionesResidenteScreenState extends State<PublicacionesResidenteScreen> {
  final PublicacionService _publicacionService = PublicacionService();
  List<PublicacionModel> _publicaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _corregirYCargarPublicaciones();
  }

  Future<void> _corregirYCargarPublicaciones() async {
    print('🚀 Iniciando corrección y carga de publicaciones');
    try {
      // Primero corregir el estado de las publicaciones existentes
      print('🔧 Llamando a corregirEstadoPublicaciones');
      await _publicacionService.corregirEstadoPublicaciones(widget.currentUser.condominioId!);
      print('✅ Corrección completada, ahora cargando publicaciones');
      // Luego cargar las publicaciones
      await _cargarPublicaciones();
    } catch (e) {
      print('❌ Error en _corregirYCargarPublicaciones: $e');
    }
  }

  Future<void> _cargarPublicaciones() async {
    try {
      final publicaciones = await _publicacionService.obtenerPublicacionesPorTipo(
        widget.currentUser.condominioId!,
        'residentes',
      );
      
      if (mounted) {
        setState(() {
          _publicaciones = publicaciones;
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
            content: Text('Error al cargar publicaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _marcarComoLeida(PublicacionModel publicacion) async {
    try {
      await _publicacionService.marcarComoLeida(
        widget.currentUser.condominioId!,
        publicacion.id,
        widget.currentUser.uid,
      );
      
      // Actualizar el estado local
      setState(() {
        final index = _publicaciones.indexWhere((p) => p.id == publicacion.id);
        if (index != -1) {
          final updatedIsRead = Map<String, dynamic>.from(publicacion.isRead ?? {});
          updatedIsRead[widget.currentUser.uid] = true;
          _publicaciones[index] = publicacion.copyWith(isRead: updatedIsRead);
        }
      });
    } catch (e) {
      print('Error al marcar como leída: $e');
    }
  }

  bool _esPublicacionLeida(PublicacionModel publicacion) {
    return publicacion.isRead?[widget.currentUser.uid] == true;
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return DateFormat('dd/MM/yyyy HH:mm', 'es').format(fecha);
    } catch (e) {
      return fechaIso;
    }
  }

  void _mostrarDetallePublicacion(PublicacionModel publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerPublicacionScreen(
          publicacion: publicacion,
          currentUser: widget.currentUser,
          esAdministrador: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              print('🔧 Botón de corrección presionado');
              await _publicacionService.corregirEstadoPublicaciones(widget.currentUser.condominioId!);
              await _cargarPublicaciones();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Corregir y recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publicaciones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarPublicaciones,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _publicaciones.length,
                    itemBuilder: (context, index) {
                      final publicacion = _publicaciones[index];
                      return _buildPublicacionCard(publicacion);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay publicaciones disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las nuevas publicaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicacionCard(PublicacionModel publicacion) {
    final esLeida = _esPublicacionLeida(publicacion);
    
    return Card(
      elevation: esLeida ? 1 : 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esLeida 
            ? BorderSide.none 
            : BorderSide(color: Colors.green[300]!, width: 2),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallePublicacion(publicacion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      publicacion.titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: esLeida ? Colors.grey[700] : Colors.black,
                      ),
                    ),
                  ),
                  if (!esLeida)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'NUEVA',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Contenido (preview)
              Text(
                publicacion.contenido.length > 100
                    ? '${publicacion.contenido.substring(0, 100)}...'
                    : publicacion.contenido,
                style: TextStyle(
                  fontSize: 14,
                  color: esLeida ? Colors.grey[600] : Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // Footer con fecha y acción
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatearFecha(publicacion.fechaPublicacion),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Toca para leer más',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.green[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}