import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/comite_model.dart';
import '../../../models/trabajador_model.dart';
import '../../../services/espacios_comunes_service.dart';
import '../../../services/firestore_service.dart';
import 'lista_espacios_comunes_screen.dart';
import 'solicitudes_reservas_screen.dart';
import 'revisiones_post_uso_screen.dart';
import 'historial_revisiones_screen.dart';
import 'solicitudes_rechazadas_screen.dart';

class EspaciosComunesScreen extends StatefulWidget {
  final UserModel currentUser;

  const EspaciosComunesScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<EspaciosComunesScreen> createState() => _EspaciosComunesScreenState();
}

class _EspaciosComunesScreenState extends State<EspaciosComunesScreen> {
  final EspaciosComunesService _espaciosComunesService = EspaciosComunesService();
  final FirestoreService _firestoreService = FirestoreService();
  int _solicitudesPendientesCount = 0;
  bool _isLoadingCount = true;
  
  // Variables para permisos
  bool _tieneGestionEspaciosComunes = false;
  bool _tieneSolicitudesReservas = false;
  bool _tieneRevisionesPrePostUso = false;
  bool _tieneSolicitudesRechazadas = false;
  bool _tieneHistorialRevisiones = false;
  bool _isLoadingPermisos = true;

  @override
  void initState() {
    super.initState();
    _cargarContadorSolicitudesPendientes();
    _verificarPermisos();
  }

  Future<void> _cargarContadorSolicitudesPendientes() async {
    try {
      final reservas = await _espaciosComunesService.obtenerReservas(
        widget.currentUser.condominioId!,
      );
      
      final solicitudesPendientes = reservas
          .where((reserva) => reserva.estado == 'pendiente')
          .length;
      
      if (mounted) {
        setState(() {
          _solicitudesPendientesCount = solicitudesPendientes;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCount = false;
        });
      }
    }
  }

  Future<void> _verificarPermisos() async {
    try {
      print('DEBUG: Verificando permisos para usuario ${widget.currentUser.tipoUsuario}');
      
      // Si es administrador, tiene todos los permisos
      if (widget.currentUser.tipoUsuario == UserType.administrador) {
        setState(() {
          _tieneGestionEspaciosComunes = true;
          _tieneSolicitudesReservas = true;
          _tieneRevisionesPrePostUso = true;
          _tieneSolicitudesRechazadas = true;
          _tieneHistorialRevisiones = true;
          _isLoadingPermisos = false;
        });
        return;
      }

      // Para trabajadores
      if (widget.currentUser.tipoUsuario == UserType.trabajador) {
        final trabajadorData = await _firestoreService.getTrabajadorData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        );
        
        if (trabajadorData != null) {
          setState(() {
            _tieneGestionEspaciosComunes = trabajadorData.funcionesDisponibles['gestionEspaciosComunes'] ?? false;
            _tieneSolicitudesReservas = trabajadorData.funcionesDisponibles['solicitudesReservas'] ?? false;
            _tieneRevisionesPrePostUso = trabajadorData.funcionesDisponibles['revisionesPrePostUso'] ?? false;
            _tieneSolicitudesRechazadas = trabajadorData.funcionesDisponibles['solicitudesRechazadas'] ?? false;
            _tieneHistorialRevisiones = trabajadorData.funcionesDisponibles['historialRevisiones'] ?? false;
            _isLoadingPermisos = false;
          });
        }
      }
      
      // Para comité
      if (widget.currentUser.tipoUsuario == UserType.comite || 
          (widget.currentUser.tipoUsuario == UserType.residente && widget.currentUser.esComite == true)) {
        final comiteData = await _firestoreService.getComiteData(
          widget.currentUser.condominioId!,
          widget.currentUser.uid,
        );
        
        if (comiteData != null) {
          setState(() {
            _tieneGestionEspaciosComunes = comiteData.funcionesDisponibles['gestionEspaciosComunes'] ?? false;
            _tieneSolicitudesReservas = comiteData.funcionesDisponibles['solicitudesReservas'] ?? false;
            _tieneRevisionesPrePostUso = comiteData.funcionesDisponibles['revisionesPrePostUso'] ?? false;
            _tieneSolicitudesRechazadas = comiteData.funcionesDisponibles['solicitudesRechazadas'] ?? false;
            _tieneHistorialRevisiones = comiteData.funcionesDisponibles['historialRevisiones'] ?? false;
            _isLoadingPermisos = false;
          });
        }
      }
      
      print('DEBUG: Permisos cargados - Gestión: $_tieneGestionEspaciosComunes, Solicitudes: $_tieneSolicitudesReservas, Revisiones: $_tieneRevisionesPrePostUso, Rechazadas: $_tieneSolicitudesRechazadas, Historial: $_tieneHistorialRevisiones');
      
    } catch (e) {
      print('ERROR: Error al verificar permisos: $e');
      if (mounted) {
        setState(() {
          _isLoadingPermisos = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermisos) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Espacios Comunes'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios Comunes'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card para gestión de espacios comunes
            if (_tieneGestionEspaciosComunes)
              _buildNavigationCard(
                context,
                title: 'Gestión de Espacios Comunes',
                subtitle: 'Crear, editar y eliminar espacios comunes',
                icon: Icons.business,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListaEspaciosComunesScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
            if (_tieneGestionEspaciosComunes) const SizedBox(height: 16),
            
            // Card para solicitudes de reservas
            if (_tieneSolicitudesReservas)
              _buildNavigationCardWithCounter(
                context,
                title: 'Solicitudes de Reservas',
                subtitle: 'Aprobar o rechazar reservas de espacios comunes',
                icon: Icons.event_available,
                color: Colors.orange,
                counter: _solicitudesPendientesCount,
                isLoadingCounter: _isLoadingCount,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolicitudesReservasScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                  // Recargar contador al regresar
                  if (result != null || mounted) {
                    _cargarContadorSolicitudesPendientes();
                  }
                },
              ),
            if (_tieneSolicitudesReservas) const SizedBox(height: 16),
            
            // Card para revisiones pre y post uso
            if (_tieneRevisionesPrePostUso)
              _buildNavigationCard(
                context,
                title: 'Revisiones Pre y Post Uso',
                subtitle: 'Realizar revisiones antes o después del uso de espacios',
                icon: Icons.rate_review,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RevisionesUsoScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
            if (_tieneRevisionesPrePostUso) const SizedBox(height: 16),
            
            // Card para solicitudes rechazadas
            if (_tieneSolicitudesRechazadas)
              _buildNavigationCard(
                context,
                title: 'Solicitudes Rechazadas',
                subtitle: 'Ver reservas que han sido rechazadas',
                icon: Icons.cancel,
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolicitudesRechazadasScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
            if (_tieneSolicitudesRechazadas) const SizedBox(height: 16),
            
            // Card para historial de revisiones
            if (_tieneHistorialRevisiones)
              _buildNavigationCard(
                context,
                title: 'Historial de Revisiones',
                subtitle: 'Ver todas las revisiones realizadas',
                icon: Icons.history,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistorialRevisionesScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
            
            // Mensaje si no tiene permisos
            if (!_tieneGestionEspaciosComunes && 
                !_tieneSolicitudesReservas && 
                !_tieneRevisionesPrePostUso && 
                !_tieneSolicitudesRechazadas && 
                !_tieneHistorialRevisiones)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes permisos para acceder a las funciones de espacios comunes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contacta al administrador para solicitar acceso',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCardWithCounter(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int counter,
    required bool isLoadingCounter,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isLoadingCounter)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else if (counter > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              counter.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}