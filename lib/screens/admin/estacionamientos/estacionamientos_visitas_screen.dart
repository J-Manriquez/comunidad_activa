import 'package:flutter/material.dart';
import '../../../services/estacionamiento_service.dart';
import '../../../models/estacionamiento_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

class EstacionamientosVisitasScreen extends StatefulWidget {
  final String? condominioId;
  final bool modoResidente;
  final Map<String, dynamic>? datosResidente;

  const EstacionamientosVisitasScreen({
    super.key, 
    this.condominioId,
    this.modoResidente = false,
    this.datosResidente,
  });

  @override
  State<EstacionamientosVisitasScreen> createState() => _EstacionamientosVisitasScreenState();
}

class _EstacionamientosVisitasScreenState extends State<EstacionamientosVisitasScreen> {
  final EstacionamientoService _estacionamientoService = EstacionamientoService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  List<EstacionamientoModel> _estacionamientosVisitas = [];
  bool _isLoading = true;
  Set<String> _expandedCards = {};
  Set<String> _processingEstacionamientos = {}; // Para controlar qué estacionamientos están siendo procesados
  String? _condominioId;
  EstacionamientoConfigModel? _configuracion;

  @override
  void initState() {
    super.initState();
    print('🟡 [ESTACIONAMIENTOS_VISITAS] Iniciando pantalla');
    print('🟡 [ESTACIONAMIENTOS_VISITAS] Modo residente: ${widget.modoResidente}');
    print('🟡 [ESTACIONAMIENTOS_VISITAS] Datos residente: ${widget.datosResidente}');
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    try {
      print('🟡 [ESTACIONAMIENTOS_VISITAS] Inicializando datos en modo: ${widget.modoResidente ? "Residente" : "Administrador"}');
      
      if (widget.modoResidente) {
        // En modo residente, obtener condominio del usuario actual
        print('🟡 [ESTACIONAMIENTOS_VISITAS] Modo residente: obteniendo datos del usuario actual');
        final userData = await _authService.getCurrentResidenteData();
        if (userData != null) {
          _condominioId = userData.condominioId;
          print('🟢 [ESTACIONAMIENTOS_VISITAS] Usuario cargado: ${userData.nombre} - ${userData.descripcionVivienda}');
          print('🟢 [ESTACIONAMIENTOS_VISITAS] Condominio obtenido del usuario: $_condominioId');
        } else {
          print('🔴 [ESTACIONAMIENTOS_VISITAS] No se pudo obtener datos del usuario');
          throw Exception('No se pudo obtener datos del usuario');
        }
      } else {
        // En modo admin, usar el condominio pasado como parámetro
        _condominioId = widget.condominioId;
        print('🟢 [ESTACIONAMIENTOS_VISITAS] Modo admin: usando condominio proporcionado: $_condominioId');
      }
      
      if (_condominioId == null) {
        print('🔴 [ESTACIONAMIENTOS_VISITAS] ID del condominio es nulo');
        throw Exception('No se pudo obtener el ID del condominio');
      }
      
      // Obtener configuración de estacionamientos
      print('🟡 [ESTACIONAMIENTOS_VISITAS] Obteniendo configuración de estacionamientos');
      final configuracionData = await _estacionamientoService.obtenerConfiguracion(_condominioId!);
      if (configuracionData != null) {
        _configuracion = EstacionamientoConfigModel.fromFirestore(configuracionData);
        print('🟢 [ESTACIONAMIENTOS_VISITAS] Configuración cargada:');
        print('   - Permitir reservas: ${_configuracion?.permitirReservas}');
        print('   - Activo: ${_configuracion?.activo}');
      } else {
        print('🔴 [ESTACIONAMIENTOS_VISITAS] No se encontró configuración de estacionamientos');
      }
      
      print('🟡 [ESTACIONAMIENTOS_VISITAS] Iniciando carga de estacionamientos de visitas');
      await _cargarEstacionamientosVisitas();
    } catch (e) {
      print('🔴 [ESTACIONAMIENTOS_VISITAS] Error al inicializar datos: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarEstacionamientosVisitas() async {
    print('🟣 [LOAD] Iniciando _cargarEstacionamientosVisitas');
    setState(() {
      _isLoading = true;
    });

    try {
      print('🟣 [LOAD] Llamando a obtenerEstacionamientos...');
      final estacionamientos = await _estacionamientoService.obtenerEstacionamientos(
        _condominioId!,
        soloVisitas: true, // Obtener solo estacionamientos de visitas
      );
      
      print('🟣 [LOAD] Estacionamientos obtenidos: ${estacionamientos.length}');
      
      // Log de cada estacionamiento para debug
      for (int i = 0; i < estacionamientos.length; i++) {
        final est = estacionamientos[i];
        print('🟣 [LOAD] Estacionamiento $i: ${est.nroEstacionamiento}');
        print('🟣 [LOAD] - prestado: ${est.prestado}');
        print('🟣 [LOAD] - viviendaAsignada: ${est.viviendaAsignada}');
        print('🟣 [LOAD] - fechaHoraInicio: ${est.fechaHoraInicio}');
        print('🟣 [LOAD] - fechaHoraFin: ${est.fechaHoraFin}');
        print('🟣 [LOAD] - idSolicitante: ${est.idSolicitante}');
        print('🟣 [LOAD] - nombreSolicitante: ${est.nombreSolicitante}');
      }
      
      // Ordenar por número de estacionamiento
      estacionamientos.sort((a, b) {
        final numA = int.tryParse(a.nroEstacionamiento) ?? 0;
        final numB = int.tryParse(b.nroEstacionamiento) ?? 0;
        return numA.compareTo(numB);
      });
      
      print('🟣 [LOAD] Actualizando estado con ${estacionamientos.length} estacionamientos');
      setState(() {
        _estacionamientosVisitas = estacionamientos;
        _isLoading = false;
      });
      print('🟢 [LOAD SUCCESS] Carga completada exitosamente');
    } catch (e) {
      print('🔴 [LOAD ERROR] Error al cargar estacionamientos: $e');
      print('🔴 [LOAD ERROR] Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar estacionamientos de visitas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _obtenerEstadoEstacionamiento(EstacionamientoModel estacionamiento) {
    if (estacionamiento.estadoSolicitud != null) {
      return 'Solicitado';
    } else if (estacionamiento.prestado == true || 
               (estacionamiento.fechaHoraInicio != null && estacionamiento.fechaHoraFin != null)) {
      return 'Usando';
    } else {
      return 'Disponible';
    }
  }

  Color _obtenerColorCard(String estado) {
    switch (estado) {
      case 'Solicitado':
        return Colors.orange.shade100;
      case 'Usando':
        return Colors.red.shade100;
      case 'Disponible':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Solicitado':
        return Colors.orange;
      case 'Usando':
        return Colors.red;
      case 'Disponible':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _toggleExpansion(String estacionamientoId, String estado) {
    if (estado == 'Disponible') return; // No expandir si está disponible
    
    setState(() {
      if (_expandedCards.contains(estacionamientoId)) {
        _expandedCards.remove(estacionamientoId);
      } else {
        _expandedCards.add(estacionamientoId);
      }
    });
  }

  void _mostrarModalEditar(EstacionamientoModel estacionamiento) {
    print('🟡 [MODAL_EDITAR] Abriendo modal para estacionamiento ${estacionamiento.nroEstacionamiento}');
    print('🟡 [MODAL_EDITAR] Modo residente: ${widget.modoResidente}');
    
    final estado = _obtenerEstadoEstacionamiento(estacionamiento);
    print('🟡 [MODAL_EDITAR] Estado del estacionamiento: $estado');
    
    if (widget.modoResidente) {
      // En modo residente, solo permitir solicitar nuevos usos
      if (estado == 'Disponible') {
        _mostrarModalSolicitudResidente(estacionamiento);
      } else {
        // Mostrar información de que está en uso pero sin permitir terminarlo
        _mostrarInfoUsoActual(estacionamiento);
      }
    } else {
      // En modo admin, permitir todas las acciones
      if (estado == 'Solicitado') {
        _mostrarModalGestionarSolicitud(estacionamiento);
      } else if (estado == 'Usando') {
        _mostrarModalTerminarUso(estacionamiento);
      } else {
        _mostrarModalNuevoUso(estacionamiento);
      }
    }
  }

  void _mostrarModalGestionarSolicitud(EstacionamientoModel estacionamiento) {
    print('🟡 [MODAL_GESTIONAR_SOLICITUD] Abriendo modal para gestionar solicitud');
    print('🟡 [MODAL_GESTIONAR_SOLICITUD] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
    print('🟡 [MODAL_GESTIONAR_SOLICITUD] Solicitante: ${estacionamiento.nombreSolicitante}');
    print('🟡 [MODAL_GESTIONAR_SOLICITUD] Vivienda: ${estacionamiento.viviendaSolicitante}');
    
    final TextEditingController motivoRechazoController = TextEditingController();
    bool isProcessing = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Solicitud de Estacionamiento de Visitas N° ${estacionamiento.nroEstacionamiento}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la Solicitud:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Solicitante:', estacionamiento.nombreSolicitante?.first ?? 'No especificado'),
                    _buildInfoRow('Vivienda:', estacionamiento.viviendaSolicitante?.first ?? 'No especificada'),
                    _buildInfoRow('Fecha de solicitud:', estacionamiento.fechaHoraSolicitud != null 
                        ? _formatearFecha(estacionamiento.fechaHoraSolicitud!) 
                        : 'No especificada'),
                    if (estacionamiento.fechaHoraInicio != null)
                      _buildInfoRow('Fecha inicio:', _formatearFecha(estacionamiento.fechaHoraInicio!)),
                    if (estacionamiento.fechaHoraFin != null)
                      _buildInfoRow('Fecha fin:', _formatearFecha(estacionamiento.fechaHoraFin!)),
                    const SizedBox(height: 16),
                    const Text(
                      'Motivo de rechazo (opcional):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: motivoRechazoController,
                      decoration: const InputDecoration(
                        hintText: 'Ingrese el motivo del rechazo...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !isProcessing,
                    ),
                    if (isProcessing) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Procesando...'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    setDialogState(() {
                      isProcessing = true;
                    });
                    
                    try {
                      await _rechazarSolicitudVisita(estacionamiento, motivoRechazoController.text.trim());
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('🔴 [MODAL_GESTIONAR_SOLICITUD] Error al rechazar: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al rechazar solicitud: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setDialogState(() {
                          isProcessing = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    setDialogState(() {
                      isProcessing = true;
                    });
                    
                    try {
                      await _aprobarSolicitudVisita(estacionamiento);
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('🔴 [MODAL_GESTIONAR_SOLICITUD] Error al aprobar: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al aprobar solicitud: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setDialogState(() {
                          isProcessing = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Aprobar'),
                ),
              ],
            );
          },
        );
      },
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _mostrarModalTerminarUso(EstacionamientoModel estacionamiento) {
    // Verificar si ya se está procesando este estacionamiento
    if (_processingEstacionamientos.contains(estacionamiento.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya se está procesando este estacionamiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Evitar cerrar el modal accidentalmente
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isProcessing = _processingEstacionamientos.contains(estacionamiento.id);
            
            return AlertDialog(
              title: const Text('Terminar Uso'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'El estacionamiento ${estacionamiento.nroEstacionamiento} está actualmente en uso. '
                    '¿Desea terminar el uso actual?',
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Terminando uso...'),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    // Marcar como procesando
                    setState(() {
                      _processingEstacionamientos.add(estacionamiento.id);
                    });
                    setDialogState(() {});
                    
                    try {
                      final usuario = _authService.currentUser;
                      final nombreUsuario = usuario?.displayName ?? 'Administrador';
                      
                      final success = await _estacionamientoService.limpiarEstacionamientoVisita(
                        _condominioId!,
                        estacionamiento.nroEstacionamiento,
                        creadoPor: '$nombreUsuario (Admin)',
                        motivoFinalizacion: 'Finalización manual por administrador',
                      );
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Uso terminado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Actualización automática de la pantalla
                        await _cargarEstacionamientosVisitas();
                        // Forzar actualización del estado
                        if (mounted) {
                          setState(() {});
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al terminar el uso'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al terminar el uso: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      // Remover del conjunto de procesamiento
                      setState(() {
                        _processingEstacionamientos.remove(estacionamiento.id);
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Terminar Uso'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _mostrarModalNuevoUso(EstacionamientoModel estacionamiento) {
    // Verificar si ya se está procesando este estacionamiento
    if (_processingEstacionamientos.contains(estacionamiento.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya se está procesando este estacionamiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController viviendaController = TextEditingController();
    final TextEditingController fechaFinController = TextEditingController();
    DateTime? fechaFin;
    TimeOfDay? horaFin;
    bool datosCompletos = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isProcessing = _processingEstacionamientos.contains(estacionamiento.id);
            
            // Función para verificar si los datos están completos
            void verificarDatos() {
              final nuevoDatosCompletos = viviendaController.text.trim().isNotEmpty && fechaFin != null;
              if (nuevoDatosCompletos != datosCompletos) {
                setDialogState(() {
                  datosCompletos = nuevoDatosCompletos;
                });
              }
            }

            return AlertDialog(
              title: Text('Nuevo Uso - Estacionamiento ${estacionamiento.nroEstacionamiento}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: viviendaController,
                      enabled: !isProcessing,
                      decoration: const InputDecoration(
                        labelText: 'Usado por',
                        hintText: 'Ej: Juan Pérez, María González',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => verificarDatos(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fechaFinController,
                      readOnly: true,
                      enabled: !isProcessing,
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora de fin',
                        hintText: 'Seleccionar fecha y hora',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: isProcessing ? null : () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(hours: 2)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        
                        if (fecha != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          
                          if (hora != null) {
                            fechaFin = DateTime(
                              fecha.year,
                              fecha.month,
                              fecha.day,
                              hora.hour,
                              hora.minute,
                            );
                            horaFin = hora;
                            
                            setDialogState(() {
                              fechaFinController.text = 
                                  '${fecha.day}/${fecha.month}/${fecha.year} ${hora.hour}:${hora.minute.toString().padLeft(2, '0')}';
                            });
                            verificarDatos();
                          }
                        }
                      },
                    ),
                    if (isProcessing) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Creando uso...'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: (datosCompletos && !isProcessing)
                      ? () async {
                          // Marcar como procesando
                          setState(() {
                            _processingEstacionamientos.add(estacionamiento.id);
                          });
                          setDialogState(() {});
                          
                          try {
                            await _crearNuevoUso(
                              estacionamiento,
                              viviendaController.text.trim(),
                              fechaFin!,
                            );
                          } finally {
                            // Remover del conjunto de procesamiento
                            setState(() {
                              _processingEstacionamientos.remove(estacionamiento.id);
                            });
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : null,
                  ),
                  child: isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Crear Uso'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _crearNuevoUso(
    EstacionamientoModel estacionamiento,
    String vivienda,
    DateTime fechaFin,
  ) async {
    print('🔵 [DEBUG] Iniciando _crearNuevoUso');
    print('🔵 [DEBUG] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
    print('🔵 [DEBUG] Vivienda/Persona: $vivienda');
    print('🔵 [DEBUG] Fecha fin: $fechaFin');
    print('🔵 [DEBUG] Condominio ID: ${widget.condominioId}');
    
    try {
      final usuario = _authService.currentUser;
      print('🔵 [DEBUG] Usuario obtenido: ${usuario?.uid}');
      print('🔵 [DEBUG] Nombre usuario: ${usuario?.displayName}');
      
      if (usuario == null) {
        print('🔴 [ERROR] Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      final ahora = DateTime.now();
      print('🔵 [DEBUG] Fecha inicio (ahora): $ahora');
      
      print('🔵 [DEBUG] Llamando a crearUsoEstacionamientoVisita...');
      final success = await _estacionamientoService.crearUsoEstacionamientoVisita(
        _condominioId!,
        estacionamiento.nroEstacionamiento,
        vivienda,
        ahora,
        fechaFin,
        usuario.uid,
        usuario.displayName ?? 'Administrador',
      );
      
      print('🔵 [DEBUG] Resultado del servicio: $success');
      
      if (success) {
        print('🟢 [SUCCESS] Uso creado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uso creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        print('🔵 [DEBUG] Recargando datos...');
        await _cargarEstacionamientosVisitas();
        // Forzar actualización del estado
        if (mounted) {
          setState(() {});
        }
      } else {
        print('🔴 [ERROR] El servicio retornó false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el uso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('🔴 [EXCEPTION] Error en _crearNuevoUso: $e');
      print('🔴 [EXCEPTION] Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear uso: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _construirCardEstacionamiento(EstacionamientoModel estacionamiento) {
    final estado = _obtenerEstadoEstacionamiento(estacionamiento);
    final colorCard = _obtenerColorCard(estado);
    final colorEstado = _obtenerColorEstado(estado);
    final isExpanded = _expandedCards.contains(estacionamiento.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: colorCard,
      child: Column(
        children: [
          // Encabezado principal
          ListTile(
            title: Text(
              'Estacionamiento ${estacionamiento.nroEstacionamiento}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorEstado,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de expansión (solo si no está disponible)
                if (estado != 'Disponible')
                  IconButton(
                    onPressed: () => _toggleExpansion(estacionamiento.id, estado),
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue,
                    ),
                    tooltip: isExpanded ? 'Contraer' : 'Expandir',
                  ),
                // Icono de edición o indicador de carga
                if (_processingEstacionamientos.contains(estacionamiento.id))
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _mostrarModalEditar(estacionamiento),
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.orange,
                    ),
                    tooltip: 'Editar',
                  ),
              ],
            ),
          ),
          
          // Contenido expandido
          if (isExpanded && estado != 'Disponible') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _construirContenidoExpandido(estacionamiento, estado),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirContenidoExpandido(EstacionamientoModel estacionamiento, String estado) {
    if (estado == 'Solicitado') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Solicitud:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (estacionamiento.fechaHoraSolicitud != null) ...[
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Fecha de solicitud: ${_formatearFecha(estacionamiento.fechaHoraSolicitud!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (estacionamiento.nombreSolicitante != null && estacionamiento.nombreSolicitante!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Solicitante: ${estacionamiento.nombreSolicitante!.first}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (estacionamiento.viviendaSolicitante != null && estacionamiento.viviendaSolicitante!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.home, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Vivienda: ${estacionamiento.viviendaSolicitante!.first}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      );
    } else if (estado == 'Usando') {
      final esSolicitadoPorResidente = estacionamiento.estadoSolicitud != null;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esSolicitadoPorResidente ? 'Uso por Residente:' : _obtenerTextoUsoTrabajador(estacionamiento),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (estacionamiento.fechaHoraInicio != null) ...[
            Row(
              children: [
                const Icon(Icons.play_arrow, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Inicio: ${_formatearFecha(estacionamiento.fechaHoraInicio!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (estacionamiento.fechaHoraFin != null) ...[
            Row(
              children: [
                const Icon(Icons.stop, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Fin: ${_formatearFecha(estacionamiento.fechaHoraFin!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (estacionamiento.viviendaAsignada != null) ...[
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Usado por: ${estacionamiento.viviendaAsignada}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (esSolicitadoPorResidente && estacionamiento.nombreSolicitante != null && estacionamiento.nombreSolicitante!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Solicitante: ${estacionamiento.nombreSolicitante!.first}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  String _obtenerTextoUsoTrabajador(EstacionamientoModel estacionamiento) {
    // Obtener información del usuario actual
    final usuario = _authService.currentUser;
    final nombreUsuario = usuario?.displayName ?? 'Administrador';
    final cargo = 'Admin'; // Por ahora solo admin, se puede expandir en el futuro
    
    return 'Uso creado por trabajador: $nombreUsuario, $cargo';
  }

  String _formatearFecha(String fechaString) {
    try {
      final fecha = DateTime.parse(fechaString);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estacionamientos de Visitas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              await _cargarEstacionamientosVisitas();
              if (mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estacionamientosVisitas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_parking,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay estacionamientos de visitas configurados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumen
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Estacionamientos de Visitas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _construirEstadistica(
                                'Total',
                                _estacionamientosVisitas.length.toString(),
                                Colors.blue,
                              ),
                              _construirEstadistica(
                                'Disponibles',
                                _estacionamientosVisitas.where((e) => _obtenerEstadoEstacionamiento(e) == 'Disponible').length.toString(),
                                Colors.green,
                              ),
                              _construirEstadistica(
                                'En Uso',
                                _estacionamientosVisitas.where((e) => _obtenerEstadoEstacionamiento(e) == 'Usando').length.toString(),
                                Colors.red,
                              ),
                              _construirEstadistica(
                                'Solicitados',
                                _estacionamientosVisitas.where((e) => _obtenerEstadoEstacionamiento(e) == 'Solicitado').length.toString(),
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de estacionamientos
                    Expanded(
                      child: ListView.builder(
                        itemCount: _estacionamientosVisitas.length,
                        itemBuilder: (context, index) {
                          return _construirCardEstacionamiento(_estacionamientosVisitas[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _construirEstadistica(String titulo, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Método para mostrar modal de solicitud de estacionamiento para residentes
  void _mostrarModalSolicitudResidente(EstacionamientoModel estacionamiento) {
    print('🟡 [MODAL_SOLICITUD_RESIDENTE] Abriendo modal para estacionamiento ${estacionamiento.nroEstacionamiento}');
    print('🟡 [MODAL_SOLICITUD_RESIDENTE] Datos residente: ${widget.datosResidente}');
    
    final TextEditingController fechaInicioController = TextEditingController();
    final TextEditingController fechaFinController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    bool datosCompletos = false;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Función para verificar si los datos están completos
            void verificarDatos() {
              bool nuevoDatosCompletos;
              if (_configuracion?.permitirReservas == true) {
                nuevoDatosCompletos = fechaInicio != null && fechaFin != null;
              } else {
                nuevoDatosCompletos = fechaFin != null;
              }
              
              if (nuevoDatosCompletos != datosCompletos) {
                setDialogState(() {
                  datosCompletos = nuevoDatosCompletos;
                });
              }
            }

            return AlertDialog(
              title: Text('Solicitar Estacionamiento ${estacionamiento.nroEstacionamiento}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de vivienda (solo lectura)
                    TextField(
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Vivienda',
                        hintText: widget.datosResidente?['vivienda'] ?? 'No asignada',
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: widget.datosResidente?['vivienda'] ?? ''),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de fecha y hora de inicio (solo si permitirReservas es true)
                    if (_configuracion?.permitirReservas == true) ...[
                      TextField(
                        controller: fechaInicioController,
                        readOnly: true,
                        enabled: !isProcessing,
                        decoration: const InputDecoration(
                          labelText: 'Fecha y hora de inicio',
                          hintText: 'Seleccionar fecha y hora de inicio',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: isProcessing ? null : () async {
                          print('🟡 [MODAL_SOLICITUD_RESIDENTE] Seleccionando fecha de inicio');
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          
                          if (fecha != null) {
                            final hora = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            
                            if (hora != null) {
                              fechaInicio = DateTime(
                                fecha.year,
                                fecha.month,
                                fecha.day,
                                hora.hour,
                                hora.minute,
                              );
                              
                              setDialogState(() {
                                fechaInicioController.text = 
                                    '${fecha.day}/${fecha.month}/${fecha.year} ${hora.hour}:${hora.minute.toString().padLeft(2, '0')}';
                              });
                              verificarDatos();
                              print('🟡 [MODAL_SOLICITUD_RESIDENTE] Fecha inicio seleccionada: $fechaInicio');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Campo de fecha y hora de fin (obligatorio)
                    TextField(
                      controller: fechaFinController,
                      readOnly: true,
                      enabled: !isProcessing,
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora de fin',
                        hintText: 'Seleccionar fecha y hora de fin',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: isProcessing ? null : () async {
                        print('🟡 [MODAL_SOLICITUD_RESIDENTE] Seleccionando fecha de fin');
                        final fechaMinima = fechaInicio ?? DateTime.now();
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMinima.add(const Duration(hours: 2)),
                          firstDate: fechaMinima,
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        
                        if (fecha != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(fechaMinima.add(const Duration(hours: 2))),
                          );
                          
                          if (hora != null) {
                            fechaFin = DateTime(
                              fecha.year,
                              fecha.month,
                              fecha.day,
                              hora.hour,
                              hora.minute,
                            );
                            
                            setDialogState(() {
                              fechaFinController.text = 
                                  '${fecha.day}/${fecha.month}/${fecha.year} ${hora.hour}:${hora.minute.toString().padLeft(2, '0')}';
                            });
                            verificarDatos();
                            print('🟡 [MODAL_SOLICITUD_RESIDENTE] Fecha fin seleccionada: $fechaFin');
                          }
                        }
                      },
                    ),
                    
                    if (isProcessing) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Enviando solicitud...'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: (datosCompletos && !isProcessing)
                      ? () async {
                          setDialogState(() {
                            isProcessing = true;
                          });
                          
                          try {
                            await _enviarSolicitudEstacionamientoVisita(
                              estacionamiento,
                              fechaInicio,
                              fechaFin!,
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            print('🔴 [MODAL_SOLICITUD_RESIDENTE] Error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al enviar solicitud: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isProcessing = false;
                              });
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing ? Colors.grey : Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Enviar Solicitud'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para enviar solicitud de estacionamiento de visita
  Future<void> _enviarSolicitudEstacionamientoVisita(
    EstacionamientoModel estacionamiento,
    DateTime? fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      print('🟡 [ENVIAR_SOLICITUD] Enviando solicitud de estacionamiento de visita');
      print('🟡 [ENVIAR_SOLICITUD] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('🟡 [ENVIAR_SOLICITUD] Fecha inicio: $fechaInicio');
      print('🟡 [ENVIAR_SOLICITUD] Fecha fin: $fechaFin');
      print('🟡 [ENVIAR_SOLICITUD] Datos residente: ${widget.datosResidente}');
      
      final ahora = DateTime.now();
      final datosActualizacion = {
        'estadoSolicitud': 'pendiente',
        'fechaHoraSolicitud': ahora.toIso8601String(),
        'idSolicitante': [widget.datosResidente!['id']],
        'nombreSolicitante': [widget.datosResidente!['nombre']],
        'viviendaSolicitante': [widget.datosResidente!['vivienda']],
        'fechaHoraInicio': fechaInicio?.toIso8601String(),
        'fechaHoraFin': fechaFin.toIso8601String(),
        'viviendaAsignada': widget.datosResidente!['vivienda'],
      };
      
      print('🟡 [ENVIAR_SOLICITUD] Datos a actualizar: $datosActualizacion');
      
      final success = await _estacionamientoService.actualizarEstacionamiento(
        _condominioId!,
        estacionamiento.id,
        datosActualizacion,
      );
      
      if (success) {
        print('🟢 [ENVIAR_SOLICITUD] Solicitud enviada exitosamente');
        
        // Enviar notificación al administrador
        print('🟡 [ENVIAR_SOLICITUD] Enviando notificación al administrador');
        await _notificationService.createCondominioNotification(
          condominioId: _condominioId!,
          tipoNotificacion: 'solicitud_estacionamiento_visita',
          contenido: '${widget.datosResidente!['nombre']} (${widget.datosResidente!['vivienda']}) solicita el estacionamiento de visitas N° ${estacionamiento.nroEstacionamiento}',
          additionalData: {
            'estacionamientoId': estacionamiento.id,
            'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
            'solicitanteId': widget.datosResidente!['id'],
            'solicitanteNombre': widget.datosResidente!['nombre'],
            'solicitanteVivienda': widget.datosResidente!['vivienda'],
            'fechaInicio': fechaInicio?.toIso8601String(),
            'fechaFin': fechaFin.toIso8601String(),
            'tipoEstacionamiento': 'visita',
          },
        );
        print('🟢 [ENVIAR_SOLICITUD] Notificación enviada al administrador');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente. Recibirás una notificación con la respuesta.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar datos
        await _cargarEstacionamientosVisitas();
        if (mounted) {
          setState(() {});
        }
      } else {
        throw Exception('Error al actualizar el estacionamiento');
      }
    } catch (e) {
      print('🔴 [ENVIAR_SOLICITUD] Error: $e');
      throw e;
    }
  }

  // Método para aprobar solicitud de estacionamiento de visitas
  Future<void> _aprobarSolicitudVisita(EstacionamientoModel estacionamiento) async {
    try {
      print('🟡 [APROBAR_SOLICITUD_VISITA] Iniciando aprobación de solicitud');
      print('🟡 [APROBAR_SOLICITUD_VISITA] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('🟡 [APROBAR_SOLICITUD_VISITA] Solicitante: ${estacionamiento.nombreSolicitante?.first}');
      
      // Actualizar el estacionamiento aprobando la solicitud
      final datosActualizacion = {
        'estadoSolicitud': null, // Limpiar estado de solicitud
        'prestado': true,
        'fechaHoraSolicitud': null,
        // Mantener los datos de asignación y fechas
      };
      
      final success = await _estacionamientoService.actualizarEstacionamiento(
        _condominioId!,
        estacionamiento.id,
        datosActualizacion,
      );
      
      if (success) {
        // Enviar notificación al residente
        await _notificationService.createUserNotification(
          condominioId: _condominioId!,
          userId: estacionamiento.idSolicitante!.first,
          userType: 'residentes',
          tipoNotificacion: 'estacionamiento_visita_aprobado',
          contenido: 'Su solicitud del estacionamiento de visitas N° ${estacionamiento.nroEstacionamiento} ha sido aprobada.',
          additionalData: {
            'estacionamientoId': estacionamiento.id,
            'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
            'fechaAprobacion': DateTime.now().toIso8601String(),
            'tipoEstacionamiento': 'visita',
          },
        );
        
        print('🟢 [APROBAR_SOLICITUD_VISITA] Solicitud aprobada exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud aprobada para ${estacionamiento.nombreSolicitante!.first}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar datos
        await _cargarEstacionamientosVisitas();
        if (mounted) {
          setState(() {});
        }
      } else {
        throw Exception('Error al actualizar el estacionamiento');
      }
    } catch (e) {
      print('🔴 [APROBAR_SOLICITUD_VISITA] Error: $e');
      throw e;
    }
  }

  // Método para rechazar solicitud de estacionamiento de visitas
  Future<void> _rechazarSolicitudVisita(EstacionamientoModel estacionamiento, String motivo) async {
    try {
      print('🟡 [RECHAZAR_SOLICITUD_VISITA] Iniciando rechazo de solicitud');
      print('🟡 [RECHAZAR_SOLICITUD_VISITA] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
      print('🟡 [RECHAZAR_SOLICITUD_VISITA] Motivo: $motivo');
      
      // Actualizar el estacionamiento rechazando la solicitud
      final datosActualizacion = {
        'estadoSolicitud': null,
        'fechaHoraSolicitud': null,
        'idSolicitante': null,
        'nombreSolicitante': null,
        'viviendaSolicitante': null,
        'fechaHoraInicio': null,
        'fechaHoraFin': null,
        'viviendaAsignada': null, // Limpiar vivienda asignada
      };
      
      final success = await _estacionamientoService.actualizarEstacionamiento(
        _condominioId!,
        estacionamiento.id,
        datosActualizacion,
      );
      
      if (success) {
        // Enviar notificación al residente
        final Map<String, dynamic> notificationData = {
          'estacionamientoId': estacionamiento.id,
          'numeroEstacionamiento': estacionamiento.nroEstacionamiento,
          'fechaRechazo': DateTime.now().toIso8601String(),
          'tipoEstacionamiento': 'visita',
        };
        
        if (motivo.isNotEmpty) {
          notificationData['motivoRechazo'] = motivo;
        }
        
        await _notificationService.createUserNotification(
          condominioId: _condominioId!,
          userId: estacionamiento.idSolicitante!.first,
          userType: 'residentes',
          tipoNotificacion: 'estacionamiento_visita_rechazado',
          contenido: motivo.isNotEmpty 
              ? 'Su solicitud del estacionamiento de visitas N° ${estacionamiento.nroEstacionamiento} ha sido rechazada. Motivo: $motivo'
              : 'Su solicitud del estacionamiento de visitas N° ${estacionamiento.nroEstacionamiento} ha sido rechazada.',
          additionalData: notificationData,
        );
        
        print('🟢 [RECHAZAR_SOLICITUD_VISITA] Solicitud rechazada exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud rechazada para ${estacionamiento.nombreSolicitante!.first}'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Recargar datos
        await _cargarEstacionamientosVisitas();
        if (mounted) {
          setState(() {});
        }
      } else {
        throw Exception('Error al actualizar el estacionamiento');
      }
    } catch (e) {
      print('🔴 [RECHAZAR_SOLICITUD_VISITA] Error: $e');
      throw e;
    }
  }



  // Método para mostrar información de uso actual (solo lectura para residentes)
  void _mostrarInfoUsoActual(EstacionamientoModel estacionamiento) {
    print('🟡 [INFO_USO_ACTUAL] Mostrando información de uso actual');
    print('🟡 [INFO_USO_ACTUAL] Estacionamiento: ${estacionamiento.nroEstacionamiento}');
    
    final estado = _obtenerEstadoEstacionamiento(estacionamiento);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Estacionamiento ${estacionamiento.nroEstacionamiento}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _obtenerColorEstado(estado),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: $estado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _obtenerColorEstado(estado),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (estado == 'Solicitado') ...[
                const Text(
                  'Este estacionamiento tiene una solicitud pendiente de aprobación.',
                  style: TextStyle(fontSize: 14),
                ),
              ] else if (estado == 'Usando') ...[
                const Text(
                  'Este estacionamiento está actualmente en uso.',
                  style: TextStyle(fontSize: 14),
                ),
                if (estacionamiento.fechaHoraInicio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Inicio: ${_formatearFecha(estacionamiento.fechaHoraInicio!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (estacionamiento.fechaHoraFin != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Fin programado: ${_formatearFecha(estacionamiento.fechaHoraFin!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}