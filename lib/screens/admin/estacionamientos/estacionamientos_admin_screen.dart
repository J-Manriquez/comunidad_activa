import 'package:flutter/material.dart';
import 'configuracion_estacionamientos_screen.dart';
import '../../../services/estacionamiento_service.dart';
import 'asignar_estacionamientos_screen.dart';
import 'lista_estacionamientos_screen.dart';
import 'estacionamientos_visitas_screen.dart';
import 'solicitudes_estacionamiento_admin_screen.dart';
import '../../../models/trabajador_model.dart';
import '../../../models/comite_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class EstacionamientosAdminScreen extends StatefulWidget {
  final String condominioId;
  final UserModel? currentUser;

  const EstacionamientosAdminScreen({super.key, required this.condominioId, this.currentUser});

  @override
  State<EstacionamientosAdminScreen> createState() => _EstacionamientosAdminScreenState();
}

class _EstacionamientosAdminScreenState extends State<EstacionamientosAdminScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _permitirSeleccion = true;
  bool _autoAsignacion = false; // Variable para controlar si requiere aprobación
  bool _isLoading = true;
  
  // Variables para permisos de estacionamientos
  bool _puedeConfigurarEstacionamientos = false;
  bool _puedeSolicitudesEstacionamientos = false;
  bool _puedeListaEstacionamientos = false;
  bool _puedeEstacionamientosVisitas = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    print('🔍 Verificando permisos para usuario: ${widget.currentUser?.tipoUsuario}');
    print('🔍 Es comité: ${widget.currentUser?.esComite}');
    
    // Si es administrador, tiene todos los permisos
    if (widget.currentUser?.tipoUsuario == UserType.administrador) {
      print('✅ Usuario es administrador - otorgando todos los permisos');
      setState(() {
        _puedeConfigurarEstacionamientos = true;
        _puedeSolicitudesEstacionamientos = true;
        _puedeListaEstacionamientos = true;
        _puedeEstacionamientosVisitas = true;
      });
      await _cargarConfiguracion();
      return;
    }

    // Para trabajadores, verificar permisos específicos
    if (widget.currentUser?.tipoUsuario == UserType.trabajador) {
      print('👷 Usuario es trabajador - verificando permisos específicos');
      try {
        final trabajador = await _firestoreService.getTrabajadorData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid
        );
        if (trabajador != null) {
          print('📋 Funciones disponibles del trabajador: ${trabajador.funcionesDisponibles}');
          setState(() {
            _puedeConfigurarEstacionamientos = trabajador.funcionesDisponibles['configuracionEstacionamientos'] ?? false;
            _puedeSolicitudesEstacionamientos = trabajador.funcionesDisponibles['solicitudesEstacionamientos'] ?? false;
            _puedeListaEstacionamientos = trabajador.funcionesDisponibles['listaEstacionamientos'] ?? false;
            _puedeEstacionamientosVisitas = trabajador.funcionesDisponibles['estacionamientosVisitas'] ?? false;
          });
          print('🔐 Permisos asignados - Config: $_puedeConfigurarEstacionamientos, Solicitudes: $_puedeSolicitudesEstacionamientos, Lista: $_puedeListaEstacionamientos, Visitas: $_puedeEstacionamientosVisitas');
        } else {
          print('❌ No se encontraron datos del trabajador');
        }
      } catch (e) {
        print('❌ Error al obtener permisos del trabajador: $e');
      }
    } 
    // Para comité, verificar permisos específicos (puede ser UserType.comite o UserType.residente con esComite = true)
    else if (widget.currentUser?.tipoUsuario == UserType.comite || 
             (widget.currentUser?.tipoUsuario == UserType.residente && widget.currentUser?.esComite == true)) {
      print('🏛️ Usuario es comité - verificando permisos específicos');
      try {
        final comite = await _firestoreService.getComiteData(
          widget.currentUser!.condominioId!,
          widget.currentUser!.uid
        );
        if (comite != null) {
          print('📋 Funciones disponibles del comité: ${comite.funcionesDisponibles}');
          setState(() {
            _puedeConfigurarEstacionamientos = comite.funcionesDisponibles['configuracionEstacionamientos'] ?? false;
            _puedeSolicitudesEstacionamientos = comite.funcionesDisponibles['solicitudesEstacionamientos'] ?? false;
            _puedeListaEstacionamientos = comite.funcionesDisponibles['listaEstacionamientos'] ?? false;
            _puedeEstacionamientosVisitas = comite.funcionesDisponibles['estacionamientosVisitas'] ?? false;
          });
          print('🔐 Permisos asignados - Config: $_puedeConfigurarEstacionamientos, Solicitudes: $_puedeSolicitudesEstacionamientos, Lista: $_puedeListaEstacionamientos, Visitas: $_puedeEstacionamientosVisitas');
        } else {
          print('❌ No se encontraron datos del comité');
        }
      } catch (e) {
        print('❌ Error al obtener permisos del comité: $e');
      }
    }

    await _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final configuracion = await _estacionamientoService.obtenerConfiguracion(widget.condominioId);
      if (mounted) {
        setState(() {
          _permitirSeleccion = configuracion?['permitirSeleccion'] ?? true;
          _autoAsignacion = configuracion?['autoAsignacion'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Estacionamientos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo.shade50, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header principal con configuración
                if (_puedeConfigurarEstacionamientos)
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfiguracionEstacionamientosScreen(
                            condominioId: widget.condominioId,
                          ),
                        ),
                      );
                      // Recargar configuración al regresar
                      if (result == true) {
                        _cargarConfiguracion();
                      }
                    },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade600,
                          Colors.indigo.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_parking,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estacionamientos',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gestiona los estacionamientos del condominio',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  ),
                const SizedBox(height: 20),
                
                // Card condicional para asignar estacionamientos (solo cuando _permitirSeleccion es false y tiene permisos)
                if (!_permitirSeleccion && !_isLoading && _puedeConfigurarEstacionamientos) ...[
                  _buildNavigationCard(
                    context,
                    icon: Icons.assignment_ind,
                    title: 'Asignar Estacionamientos',
                    subtitle: 'Asignar manualmente estacionamientos a viviendas',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AsignarEstacionamientosScreen(
                            condominioId: widget.condominioId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Cards de navegación (solo visible cuando _permitirSeleccion está activa, _autoAsignacion está activa y tiene permisos)
                if (_permitirSeleccion && _autoAsignacion && !_isLoading && _puedeSolicitudesEstacionamientos) ...[
                  _buildNavigationCardWithBadgeRegular(
                    context,
                    icon: Icons.assignment,
                    title: 'Solicitudes de Estacionamientos',
                    subtitle: 'Revisar y aprobar solicitudes de residentes',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SolicitudesEstacionamientoAdminScreen(
                            condominioId: widget.condominioId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Cards de navegación condicionados por permisos
                if (_puedeListaEstacionamientos) ...[
                  _buildNavigationCard(
                    context,
                    icon: Icons.list,
                    title: 'Lista de Estacionamientos',
                    subtitle: 'Visualizar información por estacionamiento',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListaEstacionamientosScreen(
                            condominioId: widget.condominioId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_puedeEstacionamientosVisitas) ...[
                  _buildNavigationCardWithBadge(
                    context,
                    icon: Icons.car_rental,
                    title: 'Estacionamientos de Visitas',
                    subtitle: 'Gestionar espacios para visitantes',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EstacionamientosVisitasScreen(
                            condominioId: widget.condominioId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Mostrar mensaje si no tiene permisos
                if (!_puedeConfigurarEstacionamientos && 
                    !_puedeSolicitudesEstacionamientos && 
                    !_puedeListaEstacionamientos && 
                    !_puedeEstacionamientosVisitas && 
                    !_isLoading)
                  _buildSinPermisos(),

                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCardWithBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              StreamBuilder<int>(
                stream: _estacionamientoService.contarSolicitudesVisitasPendientes(widget.condominioId),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCardWithBadgeRegular(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              StreamBuilder<int>(
                stream: _estacionamientoService.contarSolicitudesEstacionamientosPendientes(widget.condominioId),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinPermisos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin permisos de acceso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes permisos para acceder a las funciones de gestión de estacionamientos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
