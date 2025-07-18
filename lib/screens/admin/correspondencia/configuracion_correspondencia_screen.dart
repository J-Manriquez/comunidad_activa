import 'package:flutter/material.dart';
import '../../../models/correspondencia_config_model.dart';
import '../../../services/correspondencia_service.dart';

class ConfiguracionCorrespondenciaScreen extends StatefulWidget {
  final String condominioId;

  const ConfiguracionCorrespondenciaScreen({
    super.key,
    required this.condominioId,
  });

  @override
  State<ConfiguracionCorrespondenciaScreen> createState() =>
      _ConfiguracionCorrespondenciaScreenState();
}

class _ConfiguracionCorrespondenciaScreenState
    extends State<ConfiguracionCorrespondenciaScreen> {
  final CorrespondenciaService _correspondenciaService = CorrespondenciaService();
  
  CorrespondenciaConfigModel? _config;
  bool _isLoading = true;
  bool _isSaving = false;

  // Opciones para el dropdown de tipo de firma
  final List<String> _tipoFirmaOpciones = [
    'foto',
    'firmar en la app',
    'no solicitar firma',
  ];

  // Opciones para el slider de tiempo máximo de retención
  final List<String> _tiempoRetencionOpciones = [
    '3 dias',
    '1 semana',
    '2 semanas',
    '3 semanas',
    '1 mes',
    '2 meses',
    'indefinido',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _correspondenciaService.getCorrespondenciaConfig(
        widget.condominioId,
      );
      
      if (mounted) {
        setState(() {
          _config = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error al cargar configuración: $e');
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _correspondenciaService.saveCorrespondenciaConfig(
        widget.condominioId,
        _config!,
      );
      
      if (mounted) {
        _showSuccessSnackBar('Configuración guardada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al guardar configuración: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.blue.shade600,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.blue.shade600,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de Firma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Método de firma requerido para entregas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _config?.tipoFirma,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _tipoFirmaOpciones.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null && _config != null) {
                        setState(() {
                          _config = _config!.copyWith(tipoFirma: newValue);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoRetencionCard() {
    final currentIndex = _tiempoRetencionOpciones.indexOf(
      _config?.tiempoMaximoRetencion ?? '3 dias',
    );
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiempo Máximo de Retención',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tiempo que se mantiene la correspondencia antes de ser devuelta',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Seleccionado: ${_config?.tiempoMaximoRetencion ?? '3 dias'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (_tiempoRetencionOpciones.length - 1).toDouble(),
              divisions: _tiempoRetencionOpciones.length - 1,
              activeColor: Colors.blue.shade600,
              onChanged: (double value) {
                if (_config != null) {
                  setState(() {
                    _config = _config!.copyWith(
                      tiempoMaximoRetencion: _tiempoRetencionOpciones[value.round()],
                    );
                  });
                }
              },
            ),
            // Mostrar todas las opciones
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tiempoRetencionOpciones.asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                final isSelected = index == currentIndex;
                
                return Chip(
                  label: Text(
                    opcion,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? Colors.blue.shade600 
                      : Colors.blue.shade50,
                  side: BorderSide(
                    color: Colors.blue.shade300,
                    width: 1,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración Correspondencia',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && _config != null)
            IconButton(
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? const Center(
                  child: Text('Error al cargar la configuración'),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // Foto Obligatoria
                      _buildSwitchCard(
                        title: 'Foto Obligatoria',
                        subtitle: 'Requerir foto al registrar correspondencia',
                        value: _config!.fotoObligatoria,
                        onChanged: (value) {
                          setState(() {
                            _config = _config!.copyWith(fotoObligatoria: value);
                          });
                        },
                        icon: Icons.camera_alt,
                      ),
                      
                      // Aceptación del Residente
                      _buildSwitchCard(
                        title: 'Aceptación del Residente',
                        subtitle: 'El residente debe confirmar recepción desde la app',
                        value: _config!.aceptacionResidente,
                        onChanged: (value) {
                          setState(() {
                            _config = _config!.copyWith(aceptacionResidente: value);
                          });
                        },
                        icon: Icons.check_circle,
                      ),
                      
                      // Tipo de Firma
                      _buildDropdownCard(),
                      
                      // Tiempo Máximo de Retención
                      _buildTiempoRetencionCard(),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}