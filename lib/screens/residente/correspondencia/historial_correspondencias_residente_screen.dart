import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/correspondencia_service.dart';
import '../../../models/residente_model.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../widgets/image_carousel_widget.dart';
import '../../../utils/image_display_widget.dart';

class HistorialCorrespondenciasResidenteScreen extends StatefulWidget {
  final String condominioId;

  const HistorialCorrespondenciasResidenteScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<HistorialCorrespondenciasResidenteScreen> createState() =>
      _HistorialCorrespondenciasResidenteScreenState();
}

class _HistorialCorrespondenciasResidenteScreenState
    extends State<HistorialCorrespondenciasResidenteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final CorrespondenciaService _correspondenciaService =
      CorrespondenciaService();

  ResidenteModel? _residente;
  bool _isLoading = true;
  String? _error;
  bool _mostrarRecibidas = true; // Toggle para recibidas/enviadas

  @override
  void initState() {
    super.initState();
    _loadResidenteData();
  }

  Future<void> _loadResidenteData() async {
    try {
      final user = _authService.currentUser;
      print('DEBUG HISTORIAL: Usuario actual: ${user?.uid}');

      if (user != null) {
        final residente = await _firestoreService.getResidenteData(user.uid);
        print('DEBUG HISTORIAL: Residente cargado: $residente');

        setState(() {
          _residente = residente;
          _isLoading = false;
        });
      } else {
        print('DEBUG HISTORIAL: Usuario no autenticado');
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG HISTORIAL: Error al cargar datos del residente: $e');
      setState(() {
        _error = 'Error al cargar datos del residente: $e';
        _isLoading = false;
      });
    }
  }

  String _getViviendaResidente() {
    print('DEBUG HISTORIAL: _residente: $_residente');
    print(
      'DEBUG HISTORIAL: descripcionVivienda: ${_residente?.descripcionVivienda}',
    );

    if (_residente?.descripcionVivienda != null &&
        _residente!.descripcionVivienda!.isNotEmpty) {
      final vivienda = _residente!.descripcionVivienda!;
      print('DEBUG HISTORIAL: Usando descripcionVivienda: $vivienda');
      return vivienda;
    }

    // Fallback: construir descripción desde otros campos
    if (_residente == null) {
      print('DEBUG HISTORIAL: _residente es null');
      return '';
    }

    // Construir la descripción de la vivienda
    String descripcion = '';

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

    print('DEBUG HISTORIAL: Descripción construida: $descripcion');
    return descripcion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Correspondencias'),
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
          ? const Center(child: Text('No se encontraron datos del residente'))
          : Column(
              children: [
                _buildToggleSection(),
                Expanded(child: _buildHistorialList()),
              ],
            ),
    );
  }

  Widget _buildToggleSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
                  color: _mostrarRecibidas
                      ? Colors.green.shade600
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Recibidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mostrarRecibidas
                        ? Colors.white
                        : Colors.grey.shade700,
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
                  color: !_mostrarRecibidas
                      ? Colors.green.shade600
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Enviadas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_mostrarRecibidas
                        ? Colors.white
                        : Colors.grey.shade700,
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

  Widget _buildHistorialList() {
    final viviendaResidente = _getViviendaResidente();
    final residenteId = _residente?.uid ?? '';

    print('DEBUG HISTORIAL: viviendaResidente: $viviendaResidente');
    print('DEBUG HISTORIAL: residenteId: $residenteId');
    print('DEBUG HISTORIAL: condominioId: ${widget.condominioId}');

    if (viviendaResidente.isEmpty) {
      print('DEBUG HISTORIAL: viviendaResidente está vacía');
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

    return StreamBuilder<List<CorrespondenciaModel>>(
      stream: _correspondenciaService.getCorrespondencias(widget.condominioId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('DEBUG HISTORIAL: Error en StreamBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar historial: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          );
        }

        // Filtrar solo correspondencias entregadas
        final correspondenciasEntregadas = snapshot.data!.where((
          correspondencia,
        ) {
          return correspondencia.fechaHoraEntrega != null &&
              correspondencia.fechaHoraEntrega!.isNotEmpty;
        }).toList();

        print(
          'DEBUG HISTORIAL: Correspondencias entregadas: ${correspondenciasEntregadas.length}',
        );

        if (correspondenciasEntregadas.isEmpty) {
          print('DEBUG HISTORIAL: No hay correspondencias entregadas');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No hay correspondencias entregadas',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Filtrar correspondencias según el toggle
        print(
          'DEBUG HISTORIAL: Iniciando filtrado. Mostrar recibidas: $_mostrarRecibidas',
        );

        final correspondenciasFiltradas = correspondenciasEntregadas.where((
          correspondencia,
        ) {
          print(
            'DEBUG HISTORIAL: Procesando correspondencia ${correspondencia.id}',
          );

          if (_mostrarRecibidas) {
            // Correspondencias recibidas: el residente es el destinatario (datosEntrega o residenteIdEntrega)
            final datosEntrega = correspondencia.datosEntrega ?? '';
            final residenteIdEntrega = correspondencia.residenteIdEntrega ?? '';

            print('DEBUG HISTORIAL: datosEntrega: "$datosEntrega"');
            print('DEBUG HISTORIAL: residenteIdEntrega: "$residenteIdEntrega"');

            final matchDatosEntrega = datosEntrega.contains(viviendaResidente);
            final matchResidenteId = residenteIdEntrega == residenteId;

            print('DEBUG HISTORIAL: Match datosEntrega: $matchDatosEntrega');
            print('DEBUG HISTORIAL: Match residenteId: $matchResidenteId');

            return matchDatosEntrega || matchResidenteId;
          } else {
            // Correspondencias enviadas: el residente es quien envía (viviendaRecepcion o residenteIdRecepcion)
            final viviendaRecepcion = correspondencia.viviendaRecepcion ?? '';
            final residenteIdRecepcion =
                correspondencia.residenteIdRecepcion ?? '';

            print('DEBUG HISTORIAL: viviendaRecepcion: "$viviendaRecepcion"');
            print(
              'DEBUG HISTORIAL: residenteIdRecepcion: "$residenteIdRecepcion"',
            );

            final matchViviendaRecepcion = viviendaRecepcion.contains(
              viviendaResidente,
            );
            final matchResidenteIdRecepcion =
                residenteIdRecepcion == residenteId;

            print(
              'DEBUG HISTORIAL: Match viviendaRecepcion: $matchViviendaRecepcion',
            );
            print(
              'DEBUG HISTORIAL: Match residenteIdRecepcion: $matchResidenteIdRecepcion',
            );

            return matchViviendaRecepcion || matchResidenteIdRecepcion;
          }
        }).toList();

        print(
          'DEBUG HISTORIAL: Correspondencias filtradas: ${correspondenciasFiltradas.length}',
        );

        // Ordenar por fecha de entrega (más recientes primero)
        correspondenciasFiltradas.sort((a, b) {
          final fechaA = a.fechaHoraEntrega;
          final fechaB = b.fechaHoraEntrega;

          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;

          // Comparar como strings en formato ISO
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
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
              // Primera fila: Carrusel de imágenes a la izquierda y contenido a la derecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrusel de imágenes (120x120)
                  _buildImageCarousel(correspondencia),
                  const SizedBox(width: 16),
                  // Contenido de la correspondencia
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getCorrespondenciaIcon(
                                correspondencia.tipoCorrespondencia,
                              ),
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
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Entregada',
                                style: TextStyle(
                                  color: Colors.green.shade700,
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
                          _mostrarRecibidas
                              ? correspondencia.datosEntrega
                              : (correspondencia.viviendaRecepcion ?? 'No especificado'),
                        ),
                        if (!_mostrarRecibidas)
                          _buildInfoRow('Destinatario:', correspondencia.datosEntrega),
                        _buildInfoRow(
                          'Fecha de recepción:',
                          _formatDateTime(correspondencia.fechaHoraRecepcion),
                        ),
                        if (correspondencia.fechaHoraEntrega != null)
                          _buildInfoRow(
                            'Fecha de entrega:',
                            _formatDateTime(correspondencia.fechaHoraEntrega!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Mostrar mensajes adicionales si existen
              if (correspondencia.infAdicional?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
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
      ),
    );
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
                        _getCorrespondenciaIcon(
                          correspondencia.tipoCorrespondencia,
                        ),
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
                        _buildModalSection('Información General', [
                          _buildModalInfoRow(
                            'Tipo de correspondencia:',
                            correspondencia.tipoCorrespondencia,
                          ),
                          _buildModalInfoRow(
                            'Tipo de entrega:',
                            correspondencia.tipoEntrega,
                          ),
                          _buildModalInfoRow(
                            'Fecha de recepción:',
                            _formatDateTime(correspondencia.fechaHoraRecepcion),
                          ),
                          if (correspondencia.fechaHoraEntrega != null &&
                              correspondencia.fechaHoraEntrega!.isNotEmpty)
                            _buildModalInfoRow(
                              'Fecha de entrega:',
                              _formatDateTime(
                                correspondencia.fechaHoraEntrega!,
                              ),
                            ),
                          _buildModalInfoRow(
                            _mostrarRecibidas ? 'Destinatario:' : 'Remitente:',
                            _mostrarRecibidas
                                ? correspondencia.datosEntrega
                                : (correspondencia.viviendaRecepcion ??
                                      'No especificado'),
                          ),
                          if (!_mostrarRecibidas)
                            _buildModalInfoRow(
                              'Destinatario:',
                              correspondencia.datosEntrega,
                            ),
                        ]),

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
                        if (correspondencia.infAdicional?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 20),
                          _buildModalSection(
                            'Mensajes Adicionales',
                            correspondencia.infAdicional!.map((mensaje) {
                              return _buildMensajeItem(mensaje);
                            }).toList(),
                          ),
                        ],

                        // Firma (si está entregado)
                        if (correspondencia.firma != null &&
                            correspondencia.firma!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildModalSection('Firma de Entrega', [
                            _buildFirmaItem(correspondencia.firma!),
                          ]),
                        ],

                        // Notificaciones de entrega (si está entregado)
                        if (correspondencia.fechaHoraEntrega != null &&
                            correspondencia.fechaHoraEntrega!.isNotEmpty &&
                            correspondencia.notificacionEntrega.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildModalSection('Notificaciones de Entrega', [
                            _buildNotificacionEntregaItem(
                              correspondencia.notificacionEntrega,
                            ),
                          ]),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
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
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuntoItem(String key, dynamic value) {
    // Verificar si el valor es una imagen Base64
    bool isImage =
        value is String &&
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              Icon(Icons.message, color: Colors.amber.shade600, size: 16),
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
          Text(mensajeTexto, style: const TextStyle(fontSize: 14)),
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
              Icon(Icons.draw, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Firma digital registrada',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              Icon(Icons.verified, color: Colors.green.shade600, size: 20),
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
      print(
        'DEBUG: Convertido a Map<String, dynamic> con ${notificacionesMap.length} entradas',
      );
    } else if (notificaciones is Map<String, Map<String, dynamic>>) {
      notificacionesMap = notificaciones.cast<String, dynamic>();
      print(
        'DEBUG: Convertido desde Map<String, Map<String, dynamic>> con ${notificacionesMap.length} entradas',
      );
    } else {
      print('DEBUG: Formato no soportado: ${notificaciones.runtimeType}');
      return Text(
        'Formato de notificaciones no soportado: ${notificaciones.runtimeType}',
      );
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

      print(
        'DEBUG: Procesando entrada - Clave: $timestampKey, Valor: $notifData',
      );

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

        print(
          'DEBUG: Notificación agregada - Fecha: $fecha, Estado: $respuesta',
        );
      } else {
        print('DEBUG: No se pudo parsear fecha para entrada: $timestampKey');
      }
    }

    if (notificacionesList.isEmpty) {
      print('DEBUG: No se pudieron parsear fechas de ninguna notificación');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              ...notificacionesMap.entries.map((entry) {
                final timestamp = entry.key;
                final data = entry.value;

                String fechaEnvio = 'No disponible';
                String fechaRespuesta = 'No disponible';
                String respuesta = 'No disponible';

                if (data is Map<String, dynamic>) {
                  fechaEnvio =
                      data['fechaEnvio']?.toString() ?? 'No disponible';
                  fechaRespuesta =
                      data['fechaRespuesta']?.toString() ?? 'No disponible';
                  respuesta = data['respuesta']?.toString() ?? 'No disponible';
                  
                  // Debug: Imprimir valores recibidos
                  print('DEBUG: fechaEnvio recibida: $fechaEnvio');
                  print('DEBUG: fechaRespuesta recibida: $fechaRespuesta');
                  print('DEBUG: respuesta recibida: $respuesta');
                }

                // Formatear fechas con detalle
                final envioDetalle = _formatDateTimeDetailed(fechaEnvio);
                final respuestaDetalle = _formatDateTimeDetailed(fechaRespuesta);
                
                // Debug: Imprimir fechas formateadas
                print('DEBUG: envioDetalle: $envioDetalle');
                print('DEBUG: respuestaDetalle: $respuestaDetalle');

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color:respuesta == 'aceptada'
                              ? Colors.green.shade200
                              : respuesta == 'rechazada'
                              ? Colors.red.shade200
                              : Colors.orange.shade200,),
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
                            respuesta == 'aceptada' ? Icons.check_circle :  Icons.cancel,
                            size: 14,
                            color: respuesta == 'aceptada'
                                ? Colors.green.shade700
                                : respuesta == 'rechazada'
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Estado: $respuesta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: respuesta == 'aceptada'
                                  ? Colors.green.shade700
                                  : respuesta == 'rechazada'
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
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
        ],
      );
    }

    // Ordenar por fecha (más reciente primero)
    notificacionesList.sort(
      (a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime),
    );

    print(
      'DEBUG: Lista final ordenada con ${notificacionesList.length} notificaciones',
    );

    // Mostrar todas las notificaciones ordenadas
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        ...notificacionesList.map((notif) {
          final fecha = notif['fecha'] as DateTime;
          final respuesta = notif['respuesta'] as String;
          final fechaRespuesta = notif['fechaRespuesta'] as String?;
          final timestamp = notif['timestamp'] as String;
          
          // Debug: Verificar datos de la notificación
          print('DEBUG: Procesando notificación - respuesta: $respuesta, fechaRespuesta: $fechaRespuesta');

          final fechaFormateada = _formatDateTime(fecha);

          String mensaje;
          Color estadoColor;
          IconData estadoIcon;

          if (respuesta == 'pendiente') {
            mensaje = 'Esperando confirmación';
            estadoColor = Colors.orange;
            estadoIcon = Icons.schedule;
          } else if (respuesta == 'aceptada') {
            final fechaRespuestaFormateada = fechaRespuesta != null
                ? _formatDateTime(_parseDateTime(fechaRespuesta))
                : 'Fecha no disponible';
            mensaje = 'Confirmada el $fechaRespuestaFormateada';
            estadoColor = Colors.green;
            estadoIcon = Icons.check_circle;
          } else if (respuesta == 'rechazada') {
            final fechaRespuestaFormateada = fechaRespuesta != null
                ? _formatDateTime(_parseDateTime(fechaRespuesta))
                : 'Fecha no disponible';
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
                    Icon(estadoIcon, color: estadoColor, size: 16),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (fechaRespuesta != null && fechaRespuesta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Respuesta: ${_formatDateTime(_parseDateTime(fechaRespuesta))}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
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
            child: Text(value, style: TextStyle(color: Colors.grey.shade800)),
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
          else if (dateTime.contains('-') &&
              dateTime.contains(' ') &&
              dateTime.contains(':')) {
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

  Widget _buildImageCarousel(CorrespondenciaModel correspondencia) {
    // Verificar si hay adjuntos
    if (correspondencia.adjuntos == null || correspondencia.adjuntos!.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: 40,
        ),
      );
    }

    // Filtrar todas las imágenes (normales, fragmentadas internas y externas)
    final imagenes = correspondencia.adjuntos!.entries
        .where((entry) {
          final value = entry.value;
          if (value is String) {
            // Imagen en formato Base64 directo
            return value.startsWith('data:image/');
          } else if (value is Map<String, dynamic>) {
            // Imagen fragmentada (interna o externa)
            final type = value['type'] as String?;
            return type == 'normal' || 
                   type == 'internal_fragmented' || 
                   type == 'external_fragmented';
          }
          return false;
        })
        .map((entry) {
          final value = entry.value;
          if (value is String) {
            // Convertir String a Map para compatibilidad
            return <String, dynamic>{
              'data': value,
              'type': 'base64',
            };
          } else if (value is Map<String, dynamic>) {
            // Ya es un Map, devolverlo tal como está
            return value;
          }
          return <String, dynamic>{};
        })
        .toList();

    if (imagenes.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey.shade400,
          size: 40,
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ImageDisplayWidget(
                  imageData: imagenes.first,
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
          child: ImageCarouselWidget(
            images: imagenes,
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(8),
            onImageTap: (imageData) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: ImageDisplayWidget(
                    imageData: imageData,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
