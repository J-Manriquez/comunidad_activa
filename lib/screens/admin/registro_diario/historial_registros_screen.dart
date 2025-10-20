import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/registro_diario_model.dart';
import '../../../services/registro_diario_service.dart';
import '../../../widgets/image_carousel_widget.dart';
import '../../../utils/image_fullscreen_helper.dart';
import '../../../utils/image_display_widget.dart';

class HistorialRegistrosScreen extends StatefulWidget {
  final String condominioId;

  const HistorialRegistrosScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<HistorialRegistrosScreen> createState() => _HistorialRegistrosScreenState();
}

class _HistorialRegistrosScreenState extends State<HistorialRegistrosScreen> {
  final RegistroDiarioService _registroDiarioService = RegistroDiarioService();
  Map<String, List<RegistroDiario>> _registrosAgrupados = {};
  bool _isLoading = true;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  Map<String, bool> _cardVisibility = {}; // Estado de visibilidad para cada card

  @override
  void initState() {
    super.initState();
    // Inicializar con un rango de fechas por defecto (últimos 30 días)
    _fechaFin = DateTime.now();
    _fechaInicio = DateTime.now().subtract(Duration(days: 30));
    _cargarRegistrosHistoricos();
  }

  Future<void> _cargarRegistrosHistoricos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final registros = await _registroDiarioService.obtenerTodosLosRegistros(
        condominioId: widget.condominioId,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      setState(() {
        _registrosAgrupados = registros;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar registros históricos: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar el historial de registros');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaInicio != null && _fechaFin != null
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
      locale: const Locale('es', 'ES'),
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
      });
      _cargarRegistrosHistoricos();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _cargarRegistrosHistoricos();
  }

  Widget _buildFiltrosActivos() {
    if (_fechaInicio == null && _fechaFin == null) {
      return Container();
    }

    String textoFiltro = '';
    if (_fechaInicio != null && _fechaFin != null) {
      textoFiltro = 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    } else if (_fechaInicio != null) {
      textoFiltro = 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}';
    } else if (_fechaFin != null) {
      textoFiltro = 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8C00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: Color(0xFFFF8C00),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              textoFiltro,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF8C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinRegistros() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No hay registros históricos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No se encontraron registros diarios para el período seleccionado',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaRegistros() {
    // Ordenar las fechas de más reciente a más antigua
    List<String> fechasOrdenadas = _registrosAgrupados.keys.toList();
    fechasOrdenadas.sort((a, b) {
      // Convertir fechas en formato dd/MM/yyyy a DateTime para comparar
      List<String> partesA = a.split('/');
      List<String> partesB = b.split('/');
      DateTime fechaA = DateTime(int.parse(partesA[2]), int.parse(partesA[1]), int.parse(partesA[0]));
      DateTime fechaB = DateTime(int.parse(partesB[2]), int.parse(partesB[1]), int.parse(partesB[0]));
      return fechaB.compareTo(fechaA); // Más reciente primero
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fechasOrdenadas.length,
      itemBuilder: (context, index) {
        String fecha = fechasOrdenadas[index];
        List<RegistroDiario> registrosDia = _registrosAgrupados[fecha]!;
        return _buildCardDia(fecha, registrosDia);
      },
    );
  }

  Widget _buildCardDia(String fecha, List<RegistroDiario> registros) {
    // Inicializar visibilidad si no existe
    if (!_cardVisibility.containsKey(fecha)) {
      _cardVisibility[fecha] = true; // Por defecto visible
    }
    
    bool isVisible = _cardVisibility[fecha]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del día
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF6B35)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: isVisible 
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )
                : BorderRadius.circular(16), // Todas las esquinas redondeadas cuando está oculto
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatearFecha(fecha),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${registros.length} registro${registros.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de visibilidad en la esquina superior derecha
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _cardVisibility[fecha] = !_cardVisibility[fecha]!;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de registros del día (solo visible si isVisible es true)
          if (isVisible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: registros.map<Widget>((registro) => _buildRegistroItem(registro)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistroItem(RegistroDiario registro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesModal(registro),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Imagen del registro - Lado izquierdo
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: _buildImageCarousel(registro),
            ),
            const SizedBox(width: 12),
            // Información del registro - Lado derecho
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con hora y usuario
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        registro.hora,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTipoUsuarioColor(registro.tipoUsuario),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          registro.tipoUsuario.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Nombre del usuario
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          registro.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Comentario (preview)
                  Text(
                    registro.comentario,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _obtenerImagenesRegistro(RegistroDiario registro) {
    List<Map<String, dynamic>> imagenes = [];
    
    if (registro.additionalData != null) {
      if (registro.additionalData!['imagen1'] != null) {
        imagenes.add(registro.additionalData!['imagen1']);
      }
      if (registro.additionalData!['imagen2'] != null) {
        imagenes.add(registro.additionalData!['imagen2']);
      }
    }
    
    return imagenes;
  }

  Widget _buildImageCarousel(RegistroDiario registro) {
    final imagenes = _obtenerImagenesRegistro(registro);
    
    if (imagenes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
              SizedBox(height: 2),
              Text('Sin imágenes', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: ImageCarouselWidget(
          images: imagenes,
          height: 60,
          borderRadius: BorderRadius.circular(8.0),
          onImageTap: (imageData) {
            ImageFullscreenHelper.showFullscreenImage(context, imageData);
          },
        ),
      ),
    );
  }

  Color _getTipoUsuarioColor(String tipoUsuario) {
    switch (tipoUsuario.toLowerCase()) {
      case 'administrador':
        return Colors.red.shade600;
      case 'trabajador':
        return Colors.orange.shade600;
      case 'residente':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _mostrarDetallesModal(RegistroDiario registro) {
    showDialog(
      context: context,
      builder: (context) => _DetalleRegistroModal(
        registro: registro,
        condominioId: widget.condominioId,
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      List<String> partes = fecha.split('/');
      DateTime fechaDateTime = DateTime(int.parse(partes[2]), int.parse(partes[1]), int.parse(partes[0]));
      
      // Obtener el nombre del día de la semana en español
      List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      String diaSemana = diasSemana[fechaDateTime.weekday - 1];
      
      // Obtener el nombre del mes en español
      List<String> meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                           'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      String mes = meses[fechaDateTime.month - 1];
      
      return '$diaSemana, ${fechaDateTime.day} de $mes ${fechaDateTime.year}';
    } catch (e) {
      return fecha; // Retornar fecha original si hay error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Registros'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarRangoFechas,
            tooltip: 'Filtrar por fechas',
          ),
          if (_fechaInicio != null || _fechaFin != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade600,
              const Color(0xFFF7FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFiltrosActivos(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _registrosAgrupados.isEmpty
                        ? _buildSinRegistros()
                        : _buildListaRegistros(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal para mostrar detalles del registro
class _DetalleRegistroModal extends StatelessWidget {
  final RegistroDiario registro;
  final String condominioId;

  const _DetalleRegistroModal({
    required this.registro,
    required this.condominioId,
  });

  List<Map<String, dynamic>> _obtenerImagenesRegistro() {
    List<Map<String, dynamic>> imagenes = [];
    
    if (registro.additionalData != null) {
      if (registro.additionalData!['imagen1'] != null) {
        imagenes.add(registro.additionalData!['imagen1']);
      }
      if (registro.additionalData!['imagen2'] != null) {
        imagenes.add(registro.additionalData!['imagen2']);
      }
    }
    
    return imagenes;
  }

  Widget _buildImagenesGrid(BuildContext context) {
    final imagenes = _obtenerImagenesRegistro();
    
    if (imagenes.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('No hay imágenes disponibles', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imagenes.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ImageFullscreenHelper.showFullscreenImage(context, imagenes[index]);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageDisplayWidget(
                imageData: imagenes[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_note,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Hora del Registro',
                      value: registro.hora,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'Usuario',
                      value: registro.nombre,
                    ),
                    
                    _buildDetailRow(
                      icon: Icons.badge,
                      label: 'Tipo de Usuario',
                      value: registro.tipoUsuario.toUpperCase(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Comentario del registro
                    const Text(
                      'Comentario:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        registro.comentario,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Imágenes en formato grid
                    const Text(
                      'Imágenes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImagenesGrid(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}