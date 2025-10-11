import 'package:comunidad_activa/models/espacio_comun_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/espacios_comunes_service.dart';
import '../../../widgets/image_carousel_widget.dart';
import 'crear_editar_espacio_screen.dart';
import '../../../utils/image_fullscreen_helper.dart';

class ListaEspaciosComunesScreen extends StatefulWidget {
  final UserModel currentUser;

  const ListaEspaciosComunesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ListaEspaciosComunesScreen> createState() => _ListaEspaciosComunesScreenState();
}

class _ListaEspaciosComunesScreenState extends State<ListaEspaciosComunesScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  List<EspacioComunModel> _espaciosComunes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEspaciosComunes();
  }

  Future<void> _cargarEspaciosComunes() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final espacios = await _espaciosComunesService.obtenerEspaciosComunes(
        widget.currentUser.condominioId!,
      );
      
      if (mounted) {
        setState(() {
          _espaciosComunes = espacios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar espacios comunes: $e')),
        );
      }
    }
  }

  Future<void> _eliminarEspacio(EspacioComunModel espacio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar el espacio "${espacio.nombre}"?'),
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
        await _espaciosComunesService.eliminarEspacioComun(
          widget.currentUser.condominioId!,
          espacio.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Espacio común eliminado exitosamente')),
          );
          _cargarEspaciosComunes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar espacio: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios Comunes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearEditarEspacioScreen(
                currentUser: widget.currentUser,
              ),
            ),
          );
          
          if (resultado == true) {
            _cargarEspaciosComunes();
          }
        },
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _espaciosComunes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay espacios comunes registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Presiona el botón + para crear uno nuevo',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarEspaciosComunes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _espaciosComunes.length,
                    itemBuilder: (context, index) {
                      final espacio = _espaciosComunes[index];
                      return _buildEspacioCard(espacio);
                    },
                  ),
                ),
    );
  }

  Widget _buildEspacioCard(EspacioComunModel espacio) {
    // Obtener todas las imágenes disponibles
    List<Map<String, dynamic>> images = [];
    
    if (espacio.additionalData != null) {
      // Buscar imagen1Data, imagen2Data, imagen3Data
      for (int i = 1; i <= 3; i++) {
        final imageKey = 'imagen${i}Data';
        if (espacio.additionalData![imageKey] != null) {
          images.add(espacio.additionalData![imageKey]);
        }
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel de imágenes a la izquierda
            Container(
              width: 120,
              height: 100,
              child: ImageCarouselWidget(
                images: images,
                width: 120,
                height: 100,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                onImageTap: (imageData) => ImageFullscreenHelper.showFullscreenImage(context, imageData),
              ),
            ),
            const SizedBox(width: 16),
            
            // Contenido de texto a la derecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          espacio.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: espacio.estado == 'activo' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          espacio.estado.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Información del espacio
                  Text(
                    'Capacidad: ${espacio.capacidad} personas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  if (espacio.precio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Precio: \$${NumberFormat('#,###').format(espacio.precio)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  if (espacio.descripcion != null && espacio.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      espacio.descripcion!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CrearEditarEspacioScreen(
                                currentUser: widget.currentUser,
                                espacio: espacio,
                              ),
                            ),
                          );
                          
                          if (resultado == true) {
                            _cargarEspaciosComunes();
                          }
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _eliminarEspacio(espacio),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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
    );
  }
}