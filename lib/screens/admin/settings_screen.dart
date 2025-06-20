import 'package:comunidad_activa/screens/admin/config_viviendas_screen.dart';
import 'package:flutter/material.dart';
import '../../models/condominio_model.dart';
import '../../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  final String condominioId;
  
  const SettingsScreen({super.key, required this.condominioId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  CondominioModel? _condominio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCondominioData();
  }

  Future<void> _loadCondominioData() async {
    try {
      final condominio = await _firestoreService.getCondominioData(widget.condominioId);
      if (mounted) {
        setState(() {
          _condominio = condominio;
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

  String _getConfiguracionInfo() {
    if (_condominio?.tipoCondominio == null) {
      return 'Sin configurar';
    }

    final tipo = _condominio!.tipoCondominio!;
    final total = _condominio!.calcularTotalInmuebles();
    
    switch (tipo) {
      case TipoCondominio.casas:
        return 'Casas • $total viviendas';
      case TipoCondominio.edificio:
        return 'Edificios • $total departamentos';
      case TipoCondominio.mixto:
        int casas = _condominio!.numeroCasas ?? 0;
        int deptos = total - casas;
        return 'Mixto • $casas casas, $deptos deptos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(
              _condominio?.tipoCondominio != null 
                  ? Icons.check_circle 
                  : Icons.warning,
              color: _condominio?.tipoCondominio != null 
                  ? Colors.green 
                  : Colors.orange,
            ),
            title: const Text('Configuraion Viviendas del Condominio'),
            subtitle: _isLoading 
                ? const Text('Cargando...')
                : Text(_getConfiguracionInfo()),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViviendasScreen(condominioId: widget.condominioId),
                ),
              ).then((_) => _loadCondominioData()); // Recargar al volver
            },
          )
        ]
      ),
    );
  }
}