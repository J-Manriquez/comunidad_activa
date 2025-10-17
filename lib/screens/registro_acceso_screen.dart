import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/control_acceso_model.dart';
import '../models/residente_model.dart';
import '../services/control_acceso_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'crear_editar_accesos_predeterminados_screen.dart';
import 'admin/controlAcceso/formulario_control_acceso_screen.dart';

class RegistroAccesoScreen extends StatefulWidget {
  const RegistroAccesoScreen({Key? key}) : super(key: key);

  @override
  State<RegistroAccesoScreen> createState() => _RegistroAccesoScreenState();
}

class _RegistroAccesoScreenState extends State<RegistroAccesoScreen> {
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<AccesoPredeterminado> _accesosPredeterminados = [];
  bool _isLoading = true;
  ResidenteModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  void _editarAcceso(AccesoPredeterminado acceso) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrearEditarAccesosPredeterminadosScreen(
          accesoToEdit: acceso,
        ),
      ),
    ).then((_) {
      // Recargar los accesos después de editar
      _loadAccesosPredeterminados();
    });
  }

  Future<void> _eliminarAcceso(AccesoPredeterminado acceso) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Acceso'),
        content: Text(
          '¿Está seguro de eliminar el acceso de ${acceso.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (_currentUser?.condominioId == null) return;

      final condominioId = _currentUser!.condominioId!;

      bool success = await _controlAccesoService.deleteAccesoPredeterminado(
        condominioId,
        acceso.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso eliminado exitosamente')),
        );
        _loadAccesosPredeterminados();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el acceso')),
        );
      }
    }
  }

  Future<void> _loadUserAndData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        setState(() {
          _currentUser = residente;
        });
        await _loadAccesosPredeterminados();
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    }
  }

  Future<void> _loadAccesosPredeterminados() async {
    if (_currentUser == null) return;
    
    try {
      final uid = _currentUser!.uid;
      final condominioId = _currentUser!.condominioId;
      
      if (uid.isNotEmpty && condominioId!.isNotEmpty) {
        final accesos = await _controlAccesoService.getAccesosPredeterminados(
          condominioId,
          uid,
        );
        
        setState(() {
          _accesosPredeterminados = accesos;
        });
      }
    } catch (e) {
      print('Error al cargar accesos predeterminados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registrarAcceso(AccesoPredeterminado acceso) async {
    if (_currentUser == null) return;

    try {
      final controlDiario = ControlDiario(
        id: '',
        nombre: acceso.nombre,
        rut: acceso.rut,
        fecha: Timestamp.now(),
        hora: TimeOfDay.now().format(context),
        tipoIngreso: acceso.tipoIngreso,
        tipoTransporte: acceso.tipoTransporte,
        tipoAuto: acceso.tipoAuto,
        color: acceso.color,
        vivienda: acceso.vivienda,
        usaEstacionamiento: acceso.usaEstacionamiento ? 'Sí' : 'No',
        patente: '', // AccesoPredeterminado no tiene campo patente, se deja vacío
        additionalData: acceso.additionalData,
      );

      await _controlAccesoService.addControlDiario(_currentUser!.condominioId!, controlDiario);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acceso registrado para ${acceso.nombre}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar acceso: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Acceso'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de accesos predeterminados
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accesos Predeterminados',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      // Solo mostrar el botón gestionar si hay menos de 3 accesos
                      if (_accesosPredeterminados.length < 3)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CrearEditarAccesosPredeterminadosScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadAccesosPredeterminados();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Gestionar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de accesos predeterminados
                  Expanded(
                    child: _accesosPredeterminados.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _accesosPredeterminados.length,
                            itemBuilder: (context, index) {
                              final acceso = _accesosPredeterminados[index];
                              return _buildAccesoCard(acceso);
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Botón para nuevo registro
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FormularioControlAccesoScreen(
                              currentUser: _currentUser!,
                              esDesdeRegistroAcceso: true,
                            ),
                          ),
                        );
                        if (result == true) {
                          Navigator.of(context).pop(); // Volver después de registrar
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo Registro de Visita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
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
            Icons.person_add_disabled,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay accesos predeterminados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea hasta 3 perfiles de acceso para registros rápidos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccesoCard(AccesoPredeterminado acceso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _registrarAcceso(acceso),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con nombre y opciones
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getTipoIngresoColor(acceso.tipoIngreso),
                          _getTipoIngresoColor(acceso.tipoIngreso).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getTipoIngresoColor(acceso.tipoIngreso).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTipoIngresoIcon(acceso.tipoIngreso),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acceso.nombre.isNotEmpty ? _formatPersonName(acceso.nombre) : 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (acceso.rut.isNotEmpty)
                          Text(
                            'RUT: ${acceso.rut}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _editarAcceso(acceso);
                      } else if (value == 'eliminar') {
                        _eliminarAcceso(acceso);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
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
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información en chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('', acceso.tipoIngreso, _getTipoIngresoIcon(acceso.tipoIngreso)),
                  _buildInfoChip('', acceso.vivienda, Icons.home_outlined),
                  if (acceso.tipoTransporte.isNotEmpty)
                    _buildInfoChip('', acceso.tipoTransporte, _getTipoTransporteIcon(acceso.tipoTransporte)),
                  if (acceso.tipoAuto.isNotEmpty)
                    _buildInfoChip('', acceso.tipoAuto, Icons.directions_car),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 16, 
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            label.isNotEmpty ? '${_formatLabel(label)}: ${_formatContent(value)}' : _formatContent(value),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para el diseño
  Color _getTipoIngresoColor(String tipoIngreso) {
    switch (tipoIngreso.toLowerCase()) {
      case 'residente':
        return const Color(0xFF059669); // Verde
      case 'visita':
        return const Color(0xFF3B82F6); // Azul
      case 'trabajador':
        return const Color(0xFFDC2626); // Rojo
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  IconData _getTipoIngresoIcon(String tipoIngreso) {
    switch (tipoIngreso.toLowerCase()) {
      case 'residente':
        return Icons.home;
      case 'visita':
        return Icons.person;
      case 'trabajador':
        return Icons.work;
      default:
        return Icons.login;
    }
  }

  IconData _getTipoTransporteIcon(String tipoTransporte) {
    switch (tipoTransporte.toLowerCase()) {
      case 'auto':
      case 'automóvil':
        return Icons.directions_car;
      case 'moto':
      case 'motocicleta':
        return Icons.motorcycle;
      case 'bicicleta':
        return Icons.pedal_bike;
      case 'caminando':
      case 'a pie':
        return Icons.directions_walk;
      default:
        return Icons.commute;
    }
  }

  String _formatPersonName(String name) {
    return name.split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : word
    ).join(' ');
  }

  String _formatLabel(String label) {
    return label
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  String _formatContent(String content) {
    return content.isNotEmpty 
        ? '${content[0].toUpperCase()}${content.substring(1).toLowerCase()}'
        : content;
  }
}