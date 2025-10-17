import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../models/user_model.dart';
import '../../../models/control_acceso_model.dart';
import '../../../services/control_acceso_service.dart';
import 'formulario_control_acceso_screen.dart';

class ControlDiarioScreen extends StatefulWidget {
  final UserModel currentUser;

  const ControlDiarioScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ControlDiarioScreen> createState() => _ControlDiarioScreenState();
}

class _ControlDiarioScreenState extends State<ControlDiarioScreen> {
  final ControlAccesoService _controlAccesoService = ControlAccesoService();
  List<ControlDiario> _registrosHoy = [];
  bool _isLoading = true;
  late StreamSubscription<List<ControlDiario>> _registrosSubscription;

  @override
  void initState() {
    super.initState();
    _cargarRegistrosHoy();
  }

  @override
  void dispose() {
    _registrosSubscription.cancel();
    super.dispose();
  }

  Future<void> _cargarRegistrosHoy() async {
    try {
      _registrosSubscription = _controlAccesoService.getControlDiarioHoy(
        widget.currentUser.condominioId!,
      ).listen((registros) {
        setState(() {
          _registrosHoy = registros;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar registros: $e');
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

  Future<void> _navegarAFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioControlAccesoScreen(
          currentUser: widget.currentUser.toResidenteModel(),
        ),
      ),
    );

    // Si se guardó un registro, no necesitamos recargar manualmente
    // ya que el Stream se actualiza automáticamente
    if (resultado == true) {
      // Opcional: mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro guardado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Control Diario',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Azul marino profesional
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Azul marino
              Color(0xFFF8FAFC), // Gris muy claro
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: RefreshIndicator(
          color: const Color(0xFF1E3A8A),
          onRefresh: () async {
            // El Stream se actualiza automáticamente, pero podemos forzar una recarga
            setState(() {
              _isLoading = true;
            });
            // Simular un pequeño delay para mostrar el indicador
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card para nuevo registro
                _buildNuevoRegistroCard(),
                const SizedBox(height: 24),
                
                // Título de registros del día
                _buildTituloRegistros(),
                const SizedBox(height: 16),
                
                // Lista de registros
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A8A),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (_registrosHoy.isEmpty)
                  _buildSinRegistros()
                else
                  ..._buildListaRegistros(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNuevoRegistroCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _navegarAFormulario,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A), // Azul marino
                Color(0xFF3B82F6), // Azul más claro
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuevo Registro de Acceso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registrar ingreso o salida de personas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTituloRegistros() {
    final hoy = DateTime.now();
    final fechaFormateada = '${hoy.day}/${hoy.month}/${hoy.year}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.today_outlined,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registros de Hoy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaFormateada,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_registrosHoy.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_registrosHoy.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSinRegistros() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay registros para hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los registros de acceso aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListaRegistros() {
    // Ordenar registros del más nuevo al más antiguo
    _registrosHoy.sort((a, b) {
      final fechaA = a.fecha.toDate();
      final fechaB = b.fecha.toDate();
      final horaA = _parseHora(a.hora);
      final horaB = _parseHora(b.hora);
      
      final dateTimeA = DateTime(fechaA.year, fechaA.month, fechaA.day, horaA.hour, horaA.minute);
      final dateTimeB = DateTime(fechaB.year, fechaB.month, fechaB.day, horaB.hour, horaB.minute);
      
      return dateTimeB.compareTo(dateTimeA); // Más nuevo primero
    });

    return _registrosHoy.map((registro) => _buildRegistroCard(registro)).toList();
  }

  Widget _buildRegistroCard(ControlDiario registro) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con nombre y hora
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTipoIngresoColor(registro.tipoIngreso),
                        _getTipoIngresoColor(registro.tipoIngreso).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getTipoIngresoColor(registro.tipoIngreso).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getTipoIngresoIcon(registro.tipoIngreso),
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
                        registro.nombre.isNotEmpty ? _formatPersonName(registro.nombre) : 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (registro.rut.isNotEmpty)
                        Text(
                          'RUT: ${registro.rut}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTipoIngresoColor(registro.tipoIngreso),
                        _getTipoIngresoColor(registro.tipoIngreso).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getTipoIngresoColor(registro.tipoIngreso).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    registro.hora,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Información adicional
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (registro.tipoIngreso.isNotEmpty)
                  _buildInfoChip('', registro.tipoIngreso, _getTipoIngresoIcon(registro.tipoIngreso)),
                if (registro.vivienda.isNotEmpty)
                  _buildInfoChip('', registro.vivienda, _getViviendaIcon(registro.vivienda)),
                if (registro.tipoTransporte.isNotEmpty)
                  _buildInfoChip('', registro.tipoTransporte, _getTipoTransporteIcon(registro.tipoTransporte)),
                if (registro.tipoAuto.isNotEmpty)
                  _buildInfoChip('', registro.tipoAuto, Icons.directions_car),
                if (registro.color.isNotEmpty)
                  _buildInfoChip('', registro.color, Icons.palette),
                if (registro.patente.isNotEmpty)
                  _buildInfoChip('', registro.patente, Icons.pin),
                if (registro.usaEstacionamiento.isNotEmpty)
                  _buildInfoChip('', 'Estacionamiento ${registro.usaEstacionamiento}', Icons.local_parking),
              ],
            ),
            
            // Campos adicionales
            if (registro.additionalData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFE5E7EB),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...registro.additionalData.entries.map((entry) {
                if (entry.value.toString().isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInfoChip(entry.key, entry.value.toString(), _getIconForAdditionalField(entry.key)),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ],
          ],
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

  Color _getTipoIngresoColor(String tipoIngreso) {
    switch (tipoIngreso.toLowerCase()) {
      case 'residente':
        return const Color(0xFF059669); // Verde esmeralda
      case 'visita':
        return const Color(0xFF3B82F6); // Azul
      case 'trabajador':
        return const Color(0xFF7C3AED); // Púrpura
      default:
        return const Color(0xFF6B7280); // Gris
    }
  }

  IconData _getIconForAdditionalField(String fieldName) {
    String lowerFieldName = fieldName.toLowerCase();
    if (lowerFieldName.contains('estacionamiento') || lowerFieldName.contains('parking')) {
      return Icons.local_parking;
    } else if (lowerFieldName.contains('numero') || lowerFieldName.contains('number')) {
      return Icons.numbers;
    } else if (lowerFieldName.contains('observacion') || lowerFieldName.contains('comentario')) {
      return Icons.comment;
    } else if (lowerFieldName.contains('telefono') || lowerFieldName.contains('phone')) {
      return Icons.phone;
    } else {
      return Icons.info_outline;
    }
  }

  DateTime _parseHora(String hora) {
    try {
      final parts = hora.split(':');
      return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return DateTime(0, 1, 1, 0, 0);
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