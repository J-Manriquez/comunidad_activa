import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/control_acceso_model.dart';
import '../../../services/control_acceso_service.dart';

class HistorialControlAccesoScreen extends StatefulWidget {
  final UserModel? currentUser;
  
  const HistorialControlAccesoScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  State<HistorialControlAccesoScreen> createState() => _HistorialControlAccesoScreenState();
}

class _HistorialControlAccesoScreenState extends State<HistorialControlAccesoScreen> {
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  Map<String, List<ControlDiario>> _registrosAgrupados = {};
  bool _isLoading = true;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  Map<String, bool> _cardVisibility = {}; // Estado de visibilidad para cada card

  @override
  void initState() {
    super.initState();
    _cargarRegistrosHistoricos();
  }

  Future<void> _cargarRegistrosHistoricos() async {
    if (widget.currentUser?.condominioId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final registros = await _controlAccesoService.getRegistrosHistoricosPorFecha(
        widget.currentUser!.condominioId!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Control de Acceso'),
        backgroundColor: const Color(0xFF4A5568),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A5568),
              Color(0xFFF7FAFC),
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

  Widget _buildFiltrosActivos() {
    if (_fechaInicio == null && _fechaFin == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: Color(0xFF4A5568),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtrado: ${_fechaInicio != null ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}' : ''} - ${_fechaFin != null ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
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
              'No se encontraron registros de control de acceso para el período seleccionado',
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
      // Convertir fechas en formato dd/mm/yyyy a DateTime para comparar
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
        List<ControlDiario> registrosDia = _registrosAgrupados[fecha]!;
        return _buildCardDia(fecha, registrosDia);
      },
    );
  }

  Widget _buildCardDia(String fecha, List<ControlDiario> registros) {
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
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                children: registros.map((registro) => _buildRegistroItem(registro)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistroItem(ControlDiario registro) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTipoIngresoColor(registro.tipoIngreso),
                      _getTipoIngresoColor(registro.tipoIngreso).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTipoIngresoIcon(registro.tipoIngreso),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registro.nombre.isNotEmpty ? _formatPersonName(registro.nombre) : 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (registro.rut.isNotEmpty)
                      Text(
                        'RUT: ${registro.rut}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTipoIngresoColor(registro.tipoIngreso),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  registro.hora,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (registro.tipoIngreso.isNotEmpty)
                _buildInfoChip('', registro.tipoIngreso, _getTipoIngresoIcon(registro.tipoIngreso)),
              if (registro.tipoTransporte.isNotEmpty)
                _buildInfoChip('', registro.tipoTransporte, _getTipoTransporteIcon(registro.tipoTransporte)),
              if (registro.vivienda.isNotEmpty)
                _buildInfoChip('', registro.vivienda, _getViviendaIcon(registro.vivienda)),
              if (registro.tipoAuto.isNotEmpty)
                _buildInfoChip('', registro.tipoAuto, Icons.car_rental),
              if (registro.color.isNotEmpty)
                _buildInfoChip('', registro.color, Icons.palette),
              if (registro.patente.isNotEmpty)
                _buildInfoChip('', registro.patente, Icons.pin),
              if (registro.usaEstacionamiento.isNotEmpty)
                _buildInfoChip('', 'Estacionamiento ${registro.usaEstacionamiento}', Icons.local_parking),
              // Campos adicionales
              ...registro.additionalData.entries.map((entry) {
                if (entry.value.toString().isNotEmpty) {
                  return _buildInfoChip(entry.key, entry.value.toString(), _getIconForAdditionalField(entry.key));
                }
                return const SizedBox.shrink();
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            size: 14,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            label.isEmpty ? _formatContent(value) : '${_formatLabel(label)}: ${_formatContent(value)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    List<String> partes = fecha.split('/');
    if (partes.length == 3) {
      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int anio = int.parse(partes[2]);
      
      List<String> meses = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      
      return '$dia de ${meses[mes]} de $anio';
    }
    return fecha;
  }

  Color _getTipoIngresoColor(String tipoIngreso) {
    switch (tipoIngreso.toLowerCase()) {
      case 'residente':
        return const Color(0xFF10B981); // Verde esmeralda
      case 'visita':
        return const Color(0xFF3B82F6); // Azul
      case 'trabajador':
        return const Color(0xFF8B5CF6); // Púrpura
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
      case 'pie':
        return Icons.directions_walk;
      case 'vehiculo':
        return Icons.directions_car;
      case 'bicicleta':
        return Icons.directions_bike;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getViviendaIcon(String vivienda) {
    if (vivienda.toLowerCase().contains('casa')) {
      return Icons.house;
    } else {
      return Icons.apartment;
    }
  }

  IconData _getIconForAdditionalField(String fieldName) {
    String lowerFieldName = fieldName.toLowerCase();
    
    if (lowerFieldName.contains('estacionamiento') || lowerFieldName.contains('parking')) {
      return Icons.local_parking;
    } else if (lowerFieldName.contains('numero') || lowerFieldName.contains('number')) {
      return Icons.numbers;
    } else if (lowerFieldName.contains('observacion') || lowerFieldName.contains('observation')) {
      return Icons.note;
    } else if (lowerFieldName.contains('telefono') || lowerFieldName.contains('phone')) {
      return Icons.phone;
    } else {
      return Icons.info_outline;
    }
  }

  String _formatLabel(String label) {
    // Convert 'ejemplo_etiqueta' to 'Ejemplo etiqueta'
    return label
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  String _formatPersonName(String name) {
    // Format person name with initials in uppercase for all names and surnames
    return name
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  String _formatContent(String content) {
    // Capitalize the first letter of the first word
    if (content.isEmpty) return content;
    return '${content[0].toUpperCase()}${content.substring(1).toLowerCase()}';
  }
}