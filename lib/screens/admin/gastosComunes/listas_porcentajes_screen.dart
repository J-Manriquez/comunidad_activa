import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/lista_porcentajes_model.dart';
import '../../../services/gastos_comunes_service.dart';
import 'lista_porcentaje_form_screen.dart';

class ListasPorcentajesScreen extends StatefulWidget {
  final UserModel currentUser;

  const ListasPorcentajesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  _ListasPorcentajesScreenState createState() => _ListasPorcentajesScreenState();
}

class _ListasPorcentajesScreenState extends State<ListasPorcentajesScreen> {
  final GastosComunesService _gastosService = GastosComunesService();
  List<ListaPorcentajesModel> _listas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarListas();
  }

  Future<void> _cargarListas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final listas = await _gastosService.obtenerListasPorcentajes(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      setState(() {
        _listas = listas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar listas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de Porcentajes'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarListas,
              child: _listas.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _listas.length,
                      itemBuilder: (context, index) {
                        final lista = _listas[index];
                        return _buildListaCard(lista);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearNuevaLista,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay listas de porcentajes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera lista para gestionar\nla distribución de gastos por vivienda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _crearNuevaLista,
            icon: const Icon(Icons.add),
            label: const Text('Crear Lista'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCard(ListaPorcentajesModel lista) {
    final totalPorcentaje = lista.totalPorcentaje;
    final esValida = lista.esValida;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (totalPorcentaje == 100) {
      statusColor = Colors.green;
      statusText = '100% repartido correctamente';
      statusIcon = Icons.check_circle;
    } else if (totalPorcentaje < 100) {
      statusColor = Colors.orange;
      statusText = 'Falta repartir ${100 - totalPorcentaje}%';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = '${totalPorcentaje - 100}% repartido en exceso';
      statusIcon = Icons.error;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editarLista(lista),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lista.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _editarLista(lista);
                      } else if (value == 'eliminar') {
                        _confirmarEliminar(lista);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Estado de la lista
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Información adicional
              Row(
                children: [
                  Icon(
                    Icons.home,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${lista.viviendas.length} viviendas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Creada: ${lista.fechaCreacion.day}/${lista.fechaCreacion.month}/${lista.fechaCreacion.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _crearNuevaLista() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaPorcentajeFormScreen(
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (result == true) {
      _cargarListas();
    }
  }

  void _editarLista(ListaPorcentajesModel lista) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaPorcentajeFormScreen(
          currentUser: widget.currentUser,
          lista: lista,
        ),
      ),
    );

    if (result == true) {
      _cargarListas();
    }
  }

  void _confirmarEliminar(ListaPorcentajesModel lista) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la lista "${lista.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarLista(lista);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _eliminarLista(ListaPorcentajesModel lista) async {
    try {
      await _gastosService.eliminarListaPorcentajes(
        condominioId: widget.currentUser.condominioId.toString(),
        listaId: lista.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      _cargarListas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar lista: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}