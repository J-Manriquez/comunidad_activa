import 'package:comunidad_activa/models/revision_uso_model.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/reserva_model.dart';
import '../../models/revision_uso_model.dart';
import '../../services/espacios_comunes_service.dart';

class RevisionesEspaciosResidenteScreen extends StatefulWidget {
  final UserModel currentUser;

  const RevisionesEspaciosResidenteScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<RevisionesEspaciosResidenteScreen> createState() =>
      _RevisionesEspaciosResidenteScreenState();
}

class _RevisionesEspaciosResidenteScreenState
    extends State<RevisionesEspaciosResidenteScreen> {
  final EspaciosComunesService _espaciosComunesService =
      EspaciosComunesService();
  List<ReservaModel> _reservasConRevision = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarReservasConRevision();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando la pantalla vuelve a ser visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarReservasConRevision();
      }
    });
  }

  Future<void> _cargarReservasConRevision() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final todasLasReservas = await _espaciosComunesService
          .obtenerReservasPorResidente(
              widget.currentUser.condominioId!, widget.currentUser.uid!);

      // Filtrar solo las reservas aprobadas que NO tienen revisión post-uso
      final reservasConRevision = todasLasReservas
          .where((reserva) {
            if (reserva.estado.toLowerCase() != 'aprobada') return false;
            
            // Si no tiene revisiones, mostrar (para que puedan crear revisiones)
            if (reserva.revisionesUso == null || reserva.revisionesUso!.isEmpty) {
              return true;
            }
            
            // Solo NO mostrar si tiene al menos una revisión de tipo 'post_uso'
            // Las reservas con solo revisión 'pre_uso' deben seguir mostrándose
            bool tienePostUso = reserva.revisionesUso!.any(
              (revision) => revision.tipoRevision == 'post_uso'
            );
            
            return !tienePostUso;
          })
          .toList();

      // Ordenar por fecha de uso (más recientes primero)
      reservasConRevision.sort((a, b) {
        if (a.fechaUso == null && b.fechaUso == null) return 0;
        if (a.fechaUso == null) return 1;
        if (b.fechaUso == null) return -1;
        return b.fechaUso!.compareTo(a.fechaUso!);
      });

      setState(() {
        _reservasConRevision = reservasConRevision;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar revisiones: $e'),
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
        title: const Text('Mis Revisiones de Espacios'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarReservasConRevision,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reservasConRevision.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes revisiones de espacios comunes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Las revisiones aparecerán aquí después de usar un espacio común',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _reservasConRevision.length,
                    itemBuilder: (context, index) {
                      final reserva = _reservasConRevision[index];
                      return _buildRevisionCard(reserva);
                    },
                  ),
      ),
    );
  }

  Widget _buildRevisionCard(ReservaModel reserva) {
    // Manejar el caso donde no hay revisiones
    if (reserva.revisionesUso == null || reserva.revisionesUso!.isEmpty) {
      return _buildReservaCard(reserva);
    }
    
    // Obtener la revisión más relevante para mostrar
    // Priorizar post_uso si existe, sino mostrar pre_uso
    final revision = reserva.revisionesUso!.firstWhere(
      (rev) => rev.tipoRevision == 'post_uso',
      orElse: () => reserva.revisionesUso!.first,
    );
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (revision.estado.toLowerCase()) {
      case 'aprobada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprobada';
        break;
      case 'rechazada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazada';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendiente';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () => _mostrarDetalleRevision(reserva, revision),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con nombre del espacio y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reserva.nombreEspacio!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Tipo de revisión
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: revision.tipoRevision == 'pre_uso' ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: revision.tipoRevision == 'pre_uso' ? Colors.blue.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  revision.tipoRevision == 'pre_uso' ? 'Revisión Pre Uso' : 'Revisión Post Uso',
                  style: TextStyle(
                    color: revision.tipoRevision == 'pre_uso' ? Colors.blue.shade700 : Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Información de la reserva
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fecha de uso: ${reserva.fechaUso!.day}/${reserva.fechaUso!.month}/${reserva.fechaUso!.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Horario: ${reserva.horaInicio} - ${reserva.horaFin}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.rate_review,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Revisión: ${DateTime.parse(revision.fecha).day}/${DateTime.parse(revision.fecha).month}/${DateTime.parse(revision.fecha).year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Descripción de la revisión
              if (revision.descripcion.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comentarios de la revisión:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        revision.descripcion,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

              // Costo adicional si existe
              if (revision.costo != null && revision.costo! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Costo adicional: \$${revision.costo!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Toca para ver detalles',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservaCard(ReservaModel reserva) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre del espacio y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    reserva.nombreEspacio!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Pendiente de Revisión',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información de la reserva
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Fecha de uso: ${reserva.fechaUso!.day}/${reserva.fechaUso!.month}/${reserva.fechaUso!.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Horario: ${reserva.horaInicio} - ${reserva.horaFin}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mensaje informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta reserva está pendiente de revisión por parte del administrador.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleRevision(ReservaModel reserva, RevisionUsoModel revision) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle de Revisión',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Información del espacio
                _buildInfoRow('Espacio:', reserva.nombreEspacio!),
                _buildInfoRow('Fecha de uso:', '${reserva.fechaUso!.day}/${reserva.fechaUso!.month}/${reserva.fechaUso!.year}'),
                _buildInfoRow('Horario:', '${reserva.horaInicio} - ${reserva.horaFin}'),
                _buildInfoRow('Fecha de revisión:', '${DateTime.parse(revision.fecha).day}/${DateTime.parse(revision.fecha).month}/${DateTime.parse(revision.fecha).year}'),
                _buildInfoRow('Estado:', revision.estado),
                _buildInfoRow('Tipo de revisión:', revision.tipoRevision == 'pre_uso' ? 'Pre Uso' : 'Post Uso'),
                
                if (revision.costo != null && revision.costo! > 0)
                  _buildInfoRow('Costo adicional:', '\$${revision.costo!.toStringAsFixed(0)}'),

                const SizedBox(height: 16),

                // Descripción
                if (revision.descripcion.isNotEmpty) ...[
                  const Text(
                    'Comentarios:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(revision.descripcion),
                  ),
                  const SizedBox(height: 16),
                ],

                // Imágenes si existen
                if (revision.additionalData != null &&
                    revision.additionalData!['imagenes'] != null) ...[
                  const Text(
                    'Evidencia fotográfica:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildImagenesRevision(revision.additionalData!['imagenes']),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenesRevision(List<dynamic> imagenes) {
    if (imagenes.isEmpty) {
      return const Text('No hay imágenes disponibles');
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagenes.length,
        itemBuilder: (context, index) {
          final imagenBase64 = imagenes[index] as String;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                Uri.parse(imagenBase64).data!.contentAsBytes(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}