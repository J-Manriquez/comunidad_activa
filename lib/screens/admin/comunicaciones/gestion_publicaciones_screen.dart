import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/publicacion_model.dart';
import '../../../services/publicacion_service.dart';
import 'crear_publicacion_screen.dart';
import '../../comunicaciones/ver_publicacion_screen.dart';

class GestionPublicacionesScreen extends StatefulWidget {
  final UserModel currentUser;

  const GestionPublicacionesScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<GestionPublicacionesScreen> createState() => _GestionPublicacionesScreenState();
}

class _GestionPublicacionesScreenState extends State<GestionPublicacionesScreen> {
  final PublicacionService _publicacionService = PublicacionService();
  List<PublicacionModel> _publicaciones = [];
  bool _isLoading = true;
  String _filtroTipo = 'todas';

  @override
  void initState() {
    super.initState();
    _corregirYCargarPublicaciones();
  }

  Future<void> _corregirYCargarPublicaciones() async {
    print('🚀 Admin: Iniciando corrección y carga de publicaciones');
    try {
      // Primero corregir el estado de las publicaciones existentes
      await _publicacionService.corregirEstadoPublicaciones(widget.currentUser.condominioId!);
      // Luego cargar las publicaciones
      await _cargarPublicaciones();
    } catch (e) {
      print('❌ Admin: Error en corrección: $e');
      // Si falla la corrección, al menos cargar las publicaciones
      await _cargarPublicaciones();
    }
  }

  Future<void> _cargarPublicaciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final publicaciones = await _publicacionService.obtenerPublicaciones(
        widget.currentUser.condominioId!,
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

  List<PublicacionModel> get _publicacionesFiltradas {
    if (_filtroTipo == 'todas') {
      return _publicaciones;
    }
    return _publicaciones.where((p) => p.tipoPublicacion == _filtroTipo).toList();
  }

  Future<void> _eliminarPublicacion(PublicacionModel publicacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar la publicación "${publicacion.titulo}"?'),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _publicacionService.eliminarPublicacion(
          widget.currentUser.condominioId!,
          publicacion.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarPublicaciones();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar publicación: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cambiarEstadoPublicacion(PublicacionModel publicacion) async {
    final nuevoEstado = publicacion.estado == 'activa' ? 'inactiva' : 'activa';
    
    try {
      await _publicacionService.actualizarEstadoPublicacion(
        widget.currentUser.condominioId!,
        publicacion.id,
        nuevoEstado,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publicación ${nuevoEstado == 'activa' ? 'activada' : 'desactivada'} exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarPublicaciones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarACrearPublicacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPublicacionScreen(currentUser: widget.currentUser),
      ),
    ).then((_) => _cargarPublicaciones());
  }

  void _navegarAEditarPublicacion(PublicacionModel publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPublicacionScreen(
          currentUser: widget.currentUser,
          publicacionParaEditar: publicacion,
        ),
      ),
    ).then((_) => _cargarPublicaciones());
  }

  void _verPublicacion(PublicacionModel publicacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerPublicacionScreen(
          publicacion: publicacion,
          currentUser: widget.currentUser,
          esAdministrador: true,
        ),
      ),
    );
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return DateFormat('dd/MM/yyyy HH:mm', 'es').format(fecha);
    } catch (e) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestión de Publicaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cargarPublicaciones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navegarACrearPublicacion,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Publicación'),
      ),
      body: Column(
        children: [
          // Header con estadísticas y filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Estadísticas
                Row(
                  children: [
                    Expanded(
                      child: _buildEstadisticaCard(
                        'Total',
                        _publicaciones.length.toString(),
                        Icons.article,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEstadisticaCard(
                        'Activas',
                        _publicaciones.where((p) => p.estado == 'activa').length.toString(),
                        Icons.visibility,
                        Colors.green[100]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEstadisticaCard(
                        'Inactivas',
                        _publicaciones.where((p) => p.estado == 'inactiva').length.toString(),
                        Icons.visibility_off,
                        Colors.red[100]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filtros
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroTipo,
                      dropdownColor: Colors.blue[700],
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: 'todas',
                          child: Text('Todas las publicaciones', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'residentes',
                          child: Text('Para residentes', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'trabajadores',
                          child: Text('Para trabajadores', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroTipo = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de publicaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _publicacionesFiltradas.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargarPublicaciones,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _publicacionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final publicacion = _publicacionesFiltradas[index];
                            return _buildPublicacionCard(publicacion);
                          },
                        ),
                      ),
          ),
        ],
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
          Icon(icono, color: Colors.blue[700], size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
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
            'No hay publicaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera publicación',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navegarACrearPublicacion,
            icon: const Icon(Icons.add),
            label: const Text('Crear Publicación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicacionCard(PublicacionModel publicacion) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header de la tarjeta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: publicacion.estado == 'activa' ? Colors.green[50] : Colors.red[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: publicacion.tipoPublicacion == 'residentes' 
                        ? Colors.blue[100] 
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    publicacion.tipoPublicacion == 'residentes' 
                        ? Icons.home 
                        : Icons.work,
                    color: publicacion.tipoPublicacion == 'residentes' 
                        ? Colors.blue[700] 
                        : Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Para ${publicacion.tipoPublicacion}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: publicacion.estado == 'activa' 
                                  ? Colors.green[100] 
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              publicacion.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: publicacion.estado == 'activa' 
                                    ? Colors.green[700] 
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publicacion.contenido.length > 150
                      ? '${publicacion.contenido.substring(0, 150)}...'
                      : publicacion.contenido,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Footer con fecha y acciones
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
                    if (publicacion.additionalData?['nombreCreador'] != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        publicacion.additionalData!['nombreCreador'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    const Spacer(),
                    
                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _verPublicacion(publicacion),
                          icon: Icon(
                            Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          tooltip: 'Ver publicación',
                        ),
                        IconButton(
                          onPressed: () => _cambiarEstadoPublicacion(publicacion),
                          icon: Icon(
                            publicacion.estado == 'activa' 
                                ? Icons.visibility_off 
                                : Icons.check_circle,
                            color: publicacion.estado == 'activa' 
                                ? Colors.orange[600] 
                                : Colors.green[600],
                          ),
                          tooltip: publicacion.estado == 'activa' 
                              ? 'Desactivar' 
                              : 'Activar',
                        ),
                        IconButton(
                          onPressed: () => _navegarAEditarPublicacion(publicacion),
                          icon: Icon(
                            Icons.edit,
                            color: Colors.blue[600],
                          ),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          onPressed: () => _eliminarPublicacion(publicacion),
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red[600],
                          ),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}