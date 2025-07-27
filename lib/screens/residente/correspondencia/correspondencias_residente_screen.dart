import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/residente_model.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../services/correspondencia_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/modal_entrega_correspondencia.dart';
import 'historial_correspondencias_residente_screen.dart';

class CorrespondenciasResidenteScreen extends StatefulWidget {
  final String condominioId;

  const CorrespondenciasResidenteScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<CorrespondenciasResidenteScreen> createState() => _CorrespondenciasResidenteScreenState();
}

class _CorrespondenciasResidenteScreenState extends State<CorrespondenciasResidenteScreen> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  ResidenteModel? _residente;
  bool _isLoading = true;
  String? _error;
  bool _mostrarRecibidas = true; // Toggle para correspondencias activas recibidas/enviadas
  
  @override
  void initState() {
    super.initState();
    _loadResidenteData();
  }
  
  Future<void> _loadResidenteData() async {
    try {
      final user = _authService.currentUser;
      print('DEBUG: Usuario actual: ${user?.uid}');
      
      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        print('DEBUG: Datos del residente obtenidos: $residente');
        
        setState(() {
          _residente = residente;
          _isLoading = false;
        });
        
        print('DEBUG: Residente cargado en estado: $_residente');
      } else {
        print('DEBUG: Usuario no autenticado');
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error al cargar datos del residente: $e');
      setState(() {
        _error = 'Error al cargar datos del residente: $e';
        _isLoading = false;
      });
    }
  }
  
  String _getViviendaResidente() {
    print('DEBUG: _residente: $_residente');
    
    if (_residente == null) {
      print('DEBUG: _residente es null');
      return '';
    }
    
    print('DEBUG: descripcionVivienda: ${_residente?.descripcionVivienda}');
    
    if (_residente?.descripcionVivienda != null && 
        _residente!.descripcionVivienda!.isNotEmpty) {
      final vivienda = _residente!.descripcionVivienda!;
      print('DEBUG: Usando descripcionVivienda: $vivienda');
      return vivienda;
    }
    
    // Construir la descripción de la vivienda similar a como se hace en el modelo
    String descripcion = '';
    
    print('DEBUG: tipoVivienda: ${_residente!.tipoVivienda}');
    print('DEBUG: numeroVivienda: ${_residente!.numeroVivienda}');
    print('DEBUG: etiquetaEdificio: ${_residente!.etiquetaEdificio}');
    print('DEBUG: numeroDepartamento: ${_residente!.numeroDepartamento}');
    
    if (_residente!.tipoVivienda?.isNotEmpty == true) {
      descripcion += _residente!.tipoVivienda!;
    }
    
    if (_residente!.numeroVivienda?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ' ';
      descripcion += _residente!.numeroVivienda!;
    }
    
    if (_residente!.etiquetaEdificio?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ', ';
      descripcion += _residente!.etiquetaEdificio!;
    }
    
    if (_residente!.numeroDepartamento?.isNotEmpty == true) {
      if (descripcion.isNotEmpty) descripcion += ' ';
      descripcion += _residente!.numeroDepartamento!;
    }
    
    print('DEBUG: Descripción construida: $descripcion');
    
    return descripcion;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Correspondencias'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadResidenteData();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _residente == null
                  ? const Center(
                      child: Text('No se encontraron datos del residente'),
                    )
                  : _buildCorrespondenciasList(),
    );
  }
  
  Widget _buildCorrespondenciasList() {
    final viviendaResidente = _getViviendaResidente();
    
    if (viviendaResidente.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se pudo determinar la vivienda del residente',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Sección de notificaciones de entrega pendientes
        _buildNotificacionesEntrega(),
        // Card para navegar al historial
        _buildHistorialNavigationCard(),
        // Toggle para correspondencias activas
        _buildToggleSection(),
        // Sección de correspondencias
        Expanded(child: _buildCorrespondenciasStream(viviendaResidente)),
      ],
    );
  }
  
  Widget _buildHistorialNavigationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            Icons.history,
            color: Colors.green.shade600,
            size: 28,
          ),
          title: const Text(
            'Historial de Correspondencias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: const Text(
            'Ver correspondencias entregadas',
            style: TextStyle(fontSize: 14),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistorialCorrespondenciasResidenteScreen(
                  condominioId: widget.condominioId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildToggleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mostrarRecibidas = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mostrarRecibidas ? Colors.green.shade600 : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Recibidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mostrarRecibidas ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mostrarRecibidas = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_mostrarRecibidas ? Colors.green.shade600 : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Enviadas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_mostrarRecibidas ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificacionesEntrega() {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox.shrink();
    
    return FutureBuilder(
      future: _notificationService.getNotificationsForUser(
        user.uid,
        widget.condominioId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al obtener notificaciones de entrega: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          );
        }
        
        final notifications = snapshot.data ?? [];
        final pendingNotifications = notifications.where(
          (n) => n.isRead == null
        ).toList();
        
        if (pendingNotifications.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmaciones de Entrega Pendientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ...pendingNotifications.map((notification) => 
                _buildNotificationCard(notification)
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNotificationCard(dynamic notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarEntrega(notification, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarEntrega(notification, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmarEntrega(dynamic notification, bool aceptada) async {
    try {
      await _notificationService.markNotificationAsRead(
        condominioId: widget.condominioId,
        notificationId: notification.id,
        userId: _residente!.uid,
        userType: 'residentes',
      );
      
      // Actualizar el estado de la notificación
      await _notificationService.updateNotificationStatus(
        condominioId: widget.condominioId,
        notificationId: notification.id,
        newStatus: aceptada ? 'aceptada' : 'rechazada',
        userId: _residente!.uid,
        userType: 'residentes',
      );
      
      // Mostrar mensaje de confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aceptada 
                ? 'Entrega confirmada exitosamente'
                : 'Entrega rechazada',
            ),
            backgroundColor: aceptada ? Colors.green : Colors.orange,
          ),
        );
        
        // Refrescar la pantalla
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la confirmación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildCorrespondenciasStream(String viviendaResidente) {
    final residenteId = _residente?.uid ?? '';
    
    print('DEBUG: viviendaResidente: $viviendaResidente');
    print('DEBUG: residenteId: $residenteId');
    print('DEBUG: condominioId: ${widget.condominioId}');
    
    return StreamBuilder<List<CorrespondenciaModel>>(
      stream: _correspondenciaService.getCorrespondencias(widget.condominioId),
      builder: (context, snapshot) {
        print('DEBUG: condominioId: ${widget.condominioId}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('DEBUG: Error en StreamBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar correspondencias: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          );
        }
        
        print('DEBUG: Correspondencias obtenidas: ${snapshot.data?.length ?? 0}');
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('DEBUG: No hay correspondencias en la consulta');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay correspondencias activas',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        // Filtrar correspondencias según el toggle (recibidas/enviadas)
        print('DEBUG: Iniciando filtrado. Mostrar recibidas: $_mostrarRecibidas');
         
         // Primero filtrar solo correspondencias activas (sin fecha de entrega)
         final correspondenciasActivas = snapshot.data!.where((c) => 
           c.fechaHoraEntrega == null || c.fechaHoraEntrega!.isEmpty).toList();
         
         print('DEBUG: Correspondencias activas: ${correspondenciasActivas.length}');
         
         final correspondenciasFiltradas = correspondenciasActivas.where((correspondencia) {
          print('DEBUG: Procesando correspondencia ${correspondencia.id}');
          print('DEBUG: fechaHoraEntrega: ${correspondencia.fechaHoraEntrega}');
          print('DEBUG: fechaHoraRecepcion: ${correspondencia.fechaHoraRecepcion}');
          
          if (_mostrarRecibidas) {
            // Correspondencias recibidas: el residente es el destinatario (datosEntrega o residenteIdEntrega)
            final datosEntrega = correspondencia.datosEntrega;
            final residenteIdEntrega = correspondencia.residenteIdEntrega ?? '';
            
            print('DEBUG: datosEntrega: "$datosEntrega"');
            print('DEBUG: residenteIdEntrega: "$residenteIdEntrega"');
            print('DEBUG: viviendaResidente para comparar: "$viviendaResidente"');
            print('DEBUG: residenteId para comparar: "$residenteId"');
            
            final matchDatosEntrega = datosEntrega.contains(viviendaResidente);
            final matchResidenteId = residenteIdEntrega == residenteId;
            
            print('DEBUG: Match datosEntrega: $matchDatosEntrega');
            print('DEBUG: Match residenteId: $matchResidenteId');
            print('DEBUG: Resultado final para recibidas: ${matchDatosEntrega || matchResidenteId}');
            
            return matchDatosEntrega || matchResidenteId;
          } else {
            // Correspondencias enviadas: el residente es quien envía (viviendaRecepcion o residenteIdRecepcion)
            final viviendaRecepcion = correspondencia.viviendaRecepcion ?? '';
            final residenteIdRecepcion = correspondencia.residenteIdRecepcion ?? '';
            
            print('DEBUG: viviendaRecepcion: "$viviendaRecepcion"');
            print('DEBUG: residenteIdRecepcion: "$residenteIdRecepcion"');
            print('DEBUG: viviendaResidente para comparar: "$viviendaResidente"');
            print('DEBUG: residenteId para comparar: "$residenteId"');
            
            final matchViviendaRecepcion = viviendaRecepcion.contains(viviendaResidente);
            final matchResidenteIdRecepcion = residenteIdRecepcion == residenteId;
            
            print('DEBUG: Match viviendaRecepcion: $matchViviendaRecepcion');
            print('DEBUG: Match residenteIdRecepcion: $matchResidenteIdRecepcion');
            print('DEBUG: Resultado final para enviadas: ${matchViviendaRecepcion || matchResidenteIdRecepcion}');
            
            return matchViviendaRecepcion || matchResidenteIdRecepcion;
        }
        }).toList();
        
        print('DEBUG: Total de correspondencias después del filtrado: ${correspondenciasFiltradas.length}');
        
        // Ordenar por fecha de recepción (más recientes primero)
        correspondenciasFiltradas.sort((a, b) {
          // fechaHoraRecepcion es String en el modelo
          DateTime? fechaA = _parseDateTime(a.fechaHoraRecepcion);
          DateTime? fechaB = _parseDateTime(b.fechaHoraRecepcion);
          
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          
          return fechaB.compareTo(fechaA); // Orden descendente
        });
        
        if (correspondenciasFiltradas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _mostrarRecibidas 
                      ? 'No hay correspondencias recibidas'
                      : 'No hay correspondencias enviadas',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: correspondenciasFiltradas.length,
          itemBuilder: (context, index) {
            final correspondencia = correspondenciasFiltradas[index];
            
            return _buildCorrespondenciaCard(correspondencia);
          },
        );
      },
    );
  }
  
  Widget _buildCorrespondenciaCard(CorrespondenciaModel correspondencia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showCorrespondenciaModal(correspondencia),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCorrespondenciaIcon(correspondencia.tipoCorrespondencia),
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correspondencia.tipoCorrespondencia,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        correspondencia.tipoEntrega,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pendiente',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              _mostrarRecibidas ? 'Destinatario:' : 'Remitente:', 
              _mostrarRecibidas ? correspondencia.datosEntrega : (correspondencia.viviendaRecepcion ?? 'No especificado')
            ),
            if (!_mostrarRecibidas)
              _buildInfoRow('Destinatario:', correspondencia.datosEntrega),
            _buildInfoRow(
              'Fecha de recepción:',
              _formatDateTime(correspondencia.fechaHoraRecepcion),
            ),
            // Observaciones no están disponibles en el modelo actual
            
            // Mostrar mensajes adicionales si existen
            if (correspondencia.infAdicional?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Mensajes adicionales:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...correspondencia.infAdicional!.map((mensaje) {
                final mensajeTexto = mensaje['mensaje'] as String? ?? '';
                final timestamp = mensaje['timestamp'] as Timestamp?;
                final fechaFormateada = timestamp != null 
                    ? _formatDateTime(timestamp)
                    : 'Fecha no disponible';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensajeTexto,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fechaFormateada,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ));
  }
  
  void _showCorrespondenciaModal(CorrespondenciaModel correspondencia) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCorrespondenciaIcon(correspondencia.tipoCorrespondencia),
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              correspondencia.tipoCorrespondencia,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              correspondencia.tipoEntrega,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        _buildModalSection(
                          'Información General',
                          [
                            _buildModalInfoRow('Tipo de correspondencia:', correspondencia.tipoCorrespondencia),
                            _buildModalInfoRow('Tipo de entrega:', correspondencia.tipoEntrega),
                            _buildModalInfoRow('Fecha de recepción:', _formatDateTime(correspondencia.fechaHoraRecepcion)),
                            if (correspondencia.fechaHoraEntrega != null && correspondencia.fechaHoraEntrega!.isNotEmpty)
                              _buildModalInfoRow('Fecha de entrega:', _formatDateTime(correspondencia.fechaHoraEntrega!)),
                            _buildModalInfoRow(
                              _mostrarRecibidas ? 'Destinatario:' : 'Remitente:',
                              _mostrarRecibidas ? correspondencia.datosEntrega : (correspondencia.viviendaRecepcion ?? 'No especificado')
                            ),
                            if (!_mostrarRecibidas)
                              _buildModalInfoRow('Destinatario:', correspondencia.datosEntrega),
                          ],
                        ),
                        
                        // Adjuntos
                        if (correspondencia.adjuntos.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildModalSection(
                            'Adjuntos',
                            correspondencia.adjuntos.entries.map((entry) {
                              return _buildAdjuntoItem(entry.key, entry.value);
                            }).toList(),
                          ),
                        ],
                        
                        // Mensajes adicionales
                        if (correspondencia.infAdicional?.isNotEmpty == true) ...[
                          const SizedBox(height: 20),
                          _buildModalSection(
                            'Mensajes Adicionales',
                            correspondencia.infAdicional!.map((mensaje) {
                              return _buildMensajeItem(mensaje);
                            }).toList(),
                          ),
                        ],
                        
                        // Firma (si está entregado)
                        if (correspondencia.firma != null && correspondencia.firma!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildModalSection(
                            'Firma de Entrega',
                            [_buildFirmaItem(correspondencia.firma!)],
                          ),
                        ],
                        
                        // Notificaciones de entrega (si está entregado)
                        if (correspondencia.fechaHoraEntrega != null && 
                            correspondencia.fechaHoraEntrega!.isNotEmpty &&
                            correspondencia.notificacionEntrega.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildModalSection(
                            'Notificación de Entrega',
                            [_buildNotificacionEntregaItem(correspondencia.notificacionEntrega)],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuntoItem(String key, dynamic value) {
    // Verificar si el valor es una imagen Base64
    bool isImage = value is String && 
                   value.isNotEmpty && 
                   (value.startsWith('data:image/') || 
                    value.startsWith('/9j/') || 
                    value.startsWith('iVBOR'));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImage ? Icons.image : Icons.attachment,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isImage)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageFromBase64(value as String),
              ),
            )
          else if (value is String && value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      // Extraer solo la parte Base64 según la guía
      String base64Data = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  Text('Error al cargar imagen'),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red),
              Text('Formato de imagen inválido'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMensajeItem(Map<String, dynamic> mensaje) {
    final mensajeTexto = mensaje['mensaje'] as String? ?? '';
    final timestamp = mensaje['timestamp'];
    final fechaFormateada = timestamp != null 
        ? _formatDateTime(timestamp)
        : 'Fecha no disponible';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: Colors.amber.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                fechaFormateada,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mensajeTexto,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmaItem(String firma) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.draw,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Firma digital registrada',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.verified,
                color: Colors.green.shade600,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageFromBase64(firma),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionEntregaItem(dynamic notificaciones) {
    print('=== DEBUG NOTIFICACIONES ENTREGA ===');
    print('Tipo de notificaciones: ${notificaciones.runtimeType}');
    print('Valor de notificaciones: $notificaciones');
    
    // Manejar diferentes tipos de estructura de notificaciones
    if (notificaciones == null) {
      print('DEBUG: notificaciones es null');
      return const Text('No hay notificaciones de entrega');
    }
    
    Map<String, dynamic> notificacionesMap = {};
    
    // Convertir a Map si es necesario
    if (notificaciones is Map<String, dynamic>) {
      notificacionesMap = notificaciones;
      print('DEBUG: Convertido a Map<String, dynamic> con ${notificacionesMap.length} entradas');
    } else if (notificaciones is Map<String, Map<String, dynamic>>) {
      notificacionesMap = notificaciones.cast<String, dynamic>();
      print('DEBUG: Convertido desde Map<String, Map<String, dynamic>> con ${notificacionesMap.length} entradas');
    } else {
      print('DEBUG: Formato no soportado: ${notificaciones.runtimeType}');
      return Text('Formato de notificaciones no soportado: ${notificaciones.runtimeType}');
    }
    
    if (notificacionesMap.isEmpty) {
      print('DEBUG: notificacionesMap está vacío');
      return const Text('No hay notificaciones de entrega');
    }
    
    print('DEBUG: Claves disponibles: ${notificacionesMap.keys.toList()}');
    
    // Crear lista de notificaciones con fechas parseadas
    List<Map<String, dynamic>> notificacionesList = [];
    
    for (var entry in notificacionesMap.entries) {
      String timestampKey = entry.key;
      dynamic notifData = entry.value;
      
      print('DEBUG: Procesando entrada - Clave: $timestampKey, Valor: $notifData');
      
      // Intentar parsear el timestamp de la clave
      DateTime? fecha = _parseDateTime(timestampKey);
      print('DEBUG: Fecha parseada de clave "$timestampKey": $fecha');
      
      // Si no se puede parsear la clave, intentar con fechaEnvio del valor
      if (fecha == null && notifData is Map<String, dynamic>) {
        String? fechaEnvio = notifData['fechaEnvio'] as String?;
        print('DEBUG: Intentando parsear fechaEnvio: $fechaEnvio');
        if (fechaEnvio != null) {
          fecha = _parseDateTime(fechaEnvio);
          print('DEBUG: Fecha parseada de fechaEnvio: $fecha');
        }
      }
      
      if (fecha != null) {
        String respuesta = 'pendiente';
        String? fechaRespuesta;
        
        if (notifData is Map<String, dynamic>) {
          respuesta = notifData['respuesta'] as String? ?? 'pendiente';
          fechaRespuesta = notifData['fechaRespuesta'] as String?;
        }
        
        notificacionesList.add({
          'timestamp': timestampKey,
          'fecha': fecha,
          'respuesta': respuesta,
          'fechaRespuesta': fechaRespuesta,
          'data': notifData,
        });
        
        print('DEBUG: Notificación agregada - Fecha: $fecha, Estado: $respuesta');
      } else {
        print('DEBUG: No se pudo parsear fecha para entrada: $timestampKey');
      }
    }
    
    if (notificacionesList.isEmpty) {
      print('DEBUG: No se pudieron parsear fechas de ninguna notificación');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudieron procesar las notificaciones de entrega'),
          const SizedBox(height: 8),
          Text(
            'Datos disponibles: ${notificacionesMap.keys.join(", ")}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.grey.shade100,
               borderRadius: BorderRadius.circular(4),
               border: Border.all(color: Colors.grey.shade300),
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Datos de notificaciones disponibles:',
                   style: TextStyle(
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                     color: Colors.grey.shade700,
                   ),
                 ),
                 const SizedBox(height: 6),
                 ...notificacionesMap.entries.map((entry) {
                   final timestamp = entry.key;
                   final data = entry.value;
                   
                   String fechaEnvio = 'No disponible';
                   String fechaRespuesta = 'No disponible';
                   String respuesta = 'No disponible';
                   
                   if (data is Map<String, dynamic>) {
                      fechaEnvio = data['fechaEnvio']?.toString() ?? 'No disponible';
                      fechaRespuesta = data['fechaRespuesta']?.toString() ?? 'No disponible';
                      respuesta = data['respuesta']?.toString() ?? 'No disponible';
                      
                      // Debug: Imprimir valores recibidos
                      print('DEBUG CORRESPONDENCIAS: fechaEnvio recibida: $fechaEnvio');
                      print('DEBUG CORRESPONDENCIAS: fechaRespuesta recibida: $fechaRespuesta');
                      print('DEBUG CORRESPONDENCIAS: respuesta recibida: $respuesta');
                    }
                    
                    // Formatear fechas con detalle
                    final envioDetalle = _formatDateTimeDetailed(fechaEnvio);
                    final respuestaDetalle = _formatDateTimeDetailed(fechaRespuesta);
                    
                    // Debug: Imprimir fechas formateadas
                    print('DEBUG CORRESPONDENCIAS: envioDetalle: $envioDetalle');
                    print('DEBUG CORRESPONDENCIAS: respuestaDetalle: $respuestaDetalle');
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.send,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Envío:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha: ${envioDetalle['fecha']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Hora: ${envioDetalle['hora']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Respuesta:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha: ${respuestaDetalle['fecha']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Hora: ${respuestaDetalle['hora']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                respuesta == 'aceptada' ? Icons.check_circle : 
                                respuesta == 'rechazada' ? Icons.cancel : Icons.help,
                                size: 14,
                                color: respuesta == 'aceptada' ? Colors.green.shade700 : 
                                       respuesta == 'rechazada' ? Colors.red.shade700 : 
                                       Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Estado: $respuesta',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: respuesta == 'aceptada' ? Colors.green.shade700 : 
                                         respuesta == 'rechazada' ? Colors.red.shade700 : 
                                         Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                 }).toList(),
               ],
             ),
           ),
        ],
      );
    }
    
    // Ordenar por fecha (más reciente primero)
    notificacionesList.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    
    print('DEBUG: Lista final ordenada con ${notificacionesList.length} notificaciones');
    
    // Mostrar todas las notificaciones ordenadas
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.purple.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Historial de Notificaciones de Entrega (${notificacionesList.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.purple.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...notificacionesList.map((notif) {
            final fecha = notif['fecha'] as DateTime;
            final respuesta = notif['respuesta'] as String;
            final fechaRespuesta = notif['fechaRespuesta'] as String?;
            final timestamp = notif['timestamp'] as String;
            
            // Debug: Verificar datos de la notificación
            print('DEBUG CORRESPONDENCIAS: Procesando notificación - respuesta: $respuesta, fechaRespuesta: $fechaRespuesta');
            
            final fechaFormateada = _formatDateTime(fecha);
            
            String mensaje;
            Color estadoColor;
            IconData estadoIcon;
            
            if (respuesta == 'pendiente') {
              mensaje = 'Esperando confirmación';
              estadoColor = Colors.orange;
              estadoIcon = Icons.schedule;
            } else if (respuesta == 'entregado') {
              final fechaRespuestaFormateada = fechaRespuesta != null ? _formatDateTime(_parseDateTime(fechaRespuesta)) : 'Fecha no disponible';
              mensaje = 'Confirmada el $fechaRespuestaFormateada';
              estadoColor = Colors.green;
              estadoIcon = Icons.check_circle;
            } else if (respuesta == 'no_entregado') {
              final fechaRespuestaFormateada = fechaRespuesta != null ? _formatDateTime(_parseDateTime(fechaRespuesta)) : 'Fecha no disponible';
              mensaje = 'Rechazada el $fechaRespuestaFormateada';
              estadoColor = Colors.red;
              estadoIcon = Icons.cancel;
            } else {
              mensaje = 'Estado: $respuesta';
              estadoColor = Colors.grey;
              estadoIcon = Icons.help;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: estadoColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        estadoIcon,
                        color: estadoColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          mensaje,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: estadoColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enviada: $fechaFormateada',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (fechaRespuesta != null && fechaRespuesta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Respuesta: ${_formatDateTime(_parseDateTime(fechaRespuesta))}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCorrespondenciaIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'carta':
        return Icons.mail;
      case 'paquete':
        return Icons.inventory_2;
      case 'documento':
        return Icons.description;
      case 'sobre':
        return Icons.mail_outline;
      default:
        return Icons.mail;
    }
  }
  
  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime is DateTime) {
      return dateTime;
    } else if (dateTime is Timestamp) {
      return dateTime.toDate();
    } else if (dateTime is String) {
      if (dateTime.isEmpty) return null;
      
      try {
        // Intentar formato ISO estándar primero
        return DateTime.parse(dateTime);
      } catch (e) {
        try {
          // Intentar formato DD-MM-YYYY-HH-MM-SS (con guiones)
          if (dateTime.contains('-') && dateTime.split('-').length == 6) {
            final parts = dateTime.split('-');
            if (parts.length == 6) {
              return DateTime(
                int.parse(parts[2]), // año
                int.parse(parts[1]), // mes
                int.parse(parts[0]), // día
                int.parse(parts[3]), // hora
                int.parse(parts[4]), // minuto
                int.parse(parts[5]), // segundo
              );
            }
          }
          // Intentar formato dd-MM-yyyy HH:mm:ss (con espacio)
          else if (dateTime.contains('-') && dateTime.contains(' ') && dateTime.contains(':')) {
            final parts = dateTime.split(' ');
            if (parts.length == 2) {
              final datePart = parts[0].split('-');
              final timePart = parts[1].split(':');
              if (datePart.length == 3 && timePart.length == 3) {
                return DateTime(
                  int.parse(datePart[2]), // año
                  int.parse(datePart[1]), // mes
                  int.parse(datePart[0]), // día
                  int.parse(timePart[0]), // hora
                  int.parse(timePart[1]), // minuto
                  int.parse(timePart[2]), // segundo
                );
              }
            }
          } else {
            // Intentar otros formatos
            return DateTime.tryParse(dateTime.replaceAll('/', '-'));
          }
        } catch (e2) {
          return null;
        }
      }
    } else if (dateTime is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  String _formatDateTime(dynamic dateTime) {
    final parsedDate = _parseDateTime(dateTime);
    
    if (parsedDate == null) {
      return dateTime?.toString() ?? 'Fecha no disponible';
    }
    
    return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
  }
  
  Map<String, String> _formatDateTimeDetailed(dynamic dateTime) {
    if (dateTime == null) {
      return {'fecha': 'No disponible', 'hora': 'No disponible'};
    }
    
    DateTime? parsedDate = _parseDateTime(dateTime);
    if (parsedDate == null) {
      return {'fecha': 'No disponible', 'hora': 'No disponible'};
    }
    
    String fecha = '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
    String hora = '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}';
    
    return {'fecha': fecha, 'hora': hora};
  }
}