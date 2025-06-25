import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/mensaje_model.dart';
import '../../models/residente_model.dart';
import '../../services/mensaje_service.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class MensajesResidenteScreen extends StatefulWidget {
  final UserModel currentUser;

  const MensajesResidenteScreen({Key? key, required this.currentUser})
    : super(key: key);

  @override
  _MensajesResidenteScreenState createState() =>
      _MensajesResidenteScreenState();
}

class _MensajesResidenteScreenState extends State<MensajesResidenteScreen> {
  final MensajeService _mensajeService = MensajeService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _comunicacionEntreResidentesHabilitada = false;
  bool _permitirMensajesResidentes = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguraciones();
  }

  Future<void> _cargarConfiguraciones() async {
    try {
      final comunicacionHabilitada = await _mensajeService
          .esComunicacionEntreResidentesHabilitada(
            widget.currentUser.condominioId.toString(),
          );

      final permiteMensajes = await _mensajeService.residentePermiteMensajes(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _comunicacionEntreResidentesHabilitada = comunicacionHabilitada;
          _permitirMensajesResidentes = permiteMensajes;
        });
      }
    } catch (e) {
      print('❌ Error al cargar configuraciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mensajes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_comunicacionEntreResidentesHabilitada)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _mostrarConfiguracionMensajes,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat grupal del condominio
          _buildChatGrupalCard(),
          const Divider(height: 1),
          // Chat con conserjería - NUEVO
          _buildChatConserjeriaCard(),
          const Divider(height: 1),
          // Lista de chats
          Expanded(
            child: StreamBuilder<List<MensajeModel>>(
              stream: _mensajeService.obtenerChatsUsuario(
                condominioId: widget.currentUser.condominioId.toString(),
                usuarioId: widget.currentUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar chats: ${snapshot.error}'),
                  );
                }

                final chats = snapshot.data ?? [];
                // CORREGIR: Incluir chats con conserjería y otros residentes
                final chatsPrivados = chats
                    .where(
                      (chat) =>
                          !chat.participantes.contains('GRUPO_CONDOMINIO') &&
                          chat.tipo != 'grupal' && chat.tipo !='conserjeria',
                    )
                    .toList();

                if (chatsPrivados.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No tienes conversaciones aún.\nUsa el botón + para iniciar una conversación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatsPrivados.length,
                  itemBuilder: (context, index) {
                    final chat = chatsPrivados[index];
                    return _buildChatCard(chat);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _comunicacionEntreResidentesHabilitada
          ? FloatingActionButton(
              onPressed: _mostrarModalBuscarResidentes,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
    );
  }

  // NUEVO: Widget para chat con conserjería
  Widget _buildChatConserjeriaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirChatConserjeria(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange[100],
                radius: 25,
                child: Icon(
                  Icons.security,
                  color: Colors.orange[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conserjería',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chat con el personal de conserjería',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVO: Método para abrir chat con conserjería
  Future<void> _abrirChatConserjeria() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatConserjeria(
        condominioId: widget.currentUser.condominioId.toString(),
        residenteId: widget.currentUser.uid,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: 'Conserjería',
              esGrupal: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat con conserjería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildChatGrupalCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirChatGrupal(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 25,
                child: Icon(Icons.group, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat General del Condominio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Comunicación con todos los residentes',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(MensajeModel chat) {
    // Chat con otro residente o administrador
    final otroParticipante = chat.participantes.firstWhere(
      (id) => id != widget.currentUser.uid,
      orElse: () => '',
    );
    print('Participantes: ${chat.participantes}');
    return FutureBuilder<String>(
      future: _obtenerNombreUsuario(otroParticipante),
      builder: (context, snapshot) {
        final nombreOtroUsuario = snapshot.data ?? 'Usuario';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _abrirChat(chat.id, nombreOtroUsuario),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    radius: 25,
                    child: Icon(
                      Icons.person,
                      color: Colors.green[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreOtroUsuario,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(chat.fechaRegistro)),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _obtenerNombreUsuario(String userId) async {
    try {
      // Intentar obtener como residente
      final residente = await _firestoreService.getResidenteData(userId);
      if (residente != null) {
        return residente.nombre;
      }

      // Intentar obtener como administrador
      final admin = await _firestoreService.getAdministradorData(
        widget.currentUser.condominioId.toString(),
      );
      if (admin != null && admin.uid == userId) {
        return '${admin.nombre} (Administrador)';
      }

      return 'Usuario';
    } catch (e) {
      return 'Usuario';
    }
  }

  Future<void> _abrirChatGrupal() async {
    try {
      final chatId = await _mensajeService.crearOObtenerChatGrupal(
        condominioId: widget.currentUser.condominioId.toString(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.currentUser,
              chatId: chatId,
              nombreChat: 'Chat General del Condominio',
              esGrupal: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat grupal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirChat(String chatId, String nombreChat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUser,
          chatId: chatId,
          nombreChat: nombreChat,
          esGrupal: false,
        ),
      ),
    );
  }

  void _mostrarModalBuscarResidentes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BuscarResidentesModal(
        currentUser: widget.currentUser,
        mensajeService: _mensajeService,
        onChatCreado: (chatId, nombreResidente) {
          Navigator.pop(context);
          _abrirChat(chatId, nombreResidente);
        },
      ),
    );
  }

  void _mostrarConfiguracionMensajes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Mensajes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Permitir mensajes de otros residentes'),
              subtitle: const Text(
                'Otros residentes podrán enviarte mensajes privados',
              ),
              value: _permitirMensajesResidentes,
              onChanged: (value) async {
                try {
                  await _mensajeService.actualizarConfiguracionMensajes(
                    condominioId: widget.currentUser.condominioId.toString(),
                    residenteId: widget.currentUser.uid,
                    permitirMensajes: value,
                  );

                  setState(() {
                    _permitirMensajesResidentes = value;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuración actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// Modal para buscar residentes
class _BuscarResidentesModal extends StatefulWidget {
  final UserModel currentUser;
  final MensajeService mensajeService;
  final Function(String chatId, String nombreResidente) onChatCreado;

  const _BuscarResidentesModal({
    Key? key,
    required this.currentUser,
    required this.mensajeService,
    required this.onChatCreado,
  }) : super(key: key);

  @override
  _BuscarResidentesModalState createState() => _BuscarResidentesModalState();
}

class _BuscarResidentesModalState extends State<_BuscarResidentesModal> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<ResidenteModel> _residentes = [];
  List<ResidenteModel> _residentesFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarResidentes();
    _searchController.addListener(_filtrarResidentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarResidentes() async {
    try {
      final residentes = await _firestoreService.obtenerResidentesCondominio(
        widget.currentUser.condominioId.toString(),
      );

      // Filtrar el usuario actual
      final residentesFiltrados = residentes
          .where((r) => r.uid != widget.currentUser.uid)
          .toList();

      if (mounted) {
        setState(() {
          _residentes = residentesFiltrados;
          _residentesFiltrados = residentesFiltrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar residentes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filtrarResidentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _residentesFiltrados = _residentes.where((residente) {
        final nombre = residente.nombre.toLowerCase();
        final vivienda = residente.descripcionVivienda.toLowerCase();
        return nombre.contains(query) || vivienda.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle del modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Título
          const Text(
            'Buscar Residente',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o vivienda...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de residentes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _residentesFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron residentes',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _residentesFiltrados.length,
                    itemBuilder: (context, index) {
                      final residente = _residentesFiltrados[index];
                      return _buildResidenteCard(residente);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenteCard(ResidenteModel residente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.person, color: Colors.blue[700]),
        ),
        title: Text(
          residente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          residente.descripcionVivienda,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => _crearChat(residente),
      ),
    );
  }

  Future<void> _crearChat(ResidenteModel residente) async {
    try {
      // Verificar si ambos usuarios permiten mensajes
      final otroResidentePermite = await widget.mensajeService
          .residentePermiteMensajes(
            condominioId: widget.currentUser.condominioId.toString(),
            residenteId: residente.uid,
          );

      if (!otroResidentePermite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este residente no permite recibir mensajes de otros residentes',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final chatId = await widget.mensajeService.crearOObtenerChatPrivado(
        condominioId: widget.currentUser.condominioId.toString(),
        usuario1Id: widget.currentUser.uid,
        usuario2Id: residente.uid,
        tipo: 'entreResidentes'
      );

      widget.onChatCreado(chatId, residente.nombre);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
