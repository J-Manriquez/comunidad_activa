import 'package:flutter/material.dart';
import 'package:comunidad_activa/widgets/screen_navigator_widget.dart';

/// Ejemplos de uso del ScreenNavigatorWidget
/// 
/// Este archivo muestra diferentes formas de implementar el control de permisos
/// en las pantallas de la aplicación.

// EJEMPLO 1: Pantalla simple con solo permiso de primer grado
class CorrespondenciaScreen extends StatelessWidget {
  const CorrespondenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenNavigator(
      primaryPermission: 'correspondencia',
      customBlockMessage: 'No tienes permisos para gestionar correspondencia',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Correspondencia'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de correspondencia'),
        ),
      ),
    );
  }
}

// EJEMPLO 2: Pantalla con permisos específicos para trabajadores/comité
class ControlAccesoScreen extends StatelessWidget {
  const ControlAccesoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'controlAcceso',
      specificPermissions: [
        'crearRegistroAcceso',
        'controlDiario',
        'historialControlAcceso',
      ],
      customBlockMessage: 'No tienes permisos para acceder al control de acceso',
      blockIcon: Icons.security,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Control de Acceso'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de control de acceso'),
        ),
      ),
    );
  }
}

// EJEMPLO 3: Pantalla con múltiples permisos específicos
class GestionEstacionamientosScreen extends StatelessWidget {
  const GestionEstacionamientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'gestionEstacionamientos',
      specificPermissions: [
        'configuracionEstacionamientos',
        'solicitudesEstacionamientos',
        'listaEstacionamientos',
        'estacionamientosVisitas',
      ],
      customBlockMessage: 'No tienes permisos para gestionar estacionamientos',
      blockIcon: Icons.local_parking,
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red.shade700,
      iconColor: Colors.red.shade600,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Estacionamientos'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de estacionamientos'),
        ),
      ),
    );
  }
}

// EJEMPLO 4: Pantalla de espacios comunes
class EspaciosComunesScreen extends StatelessWidget {
  const EspaciosComunesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'espaciosComunes',
      specificPermissions: [
        'gestionEspaciosComunes',
        'solicitudesReservas',
        'revisionesPrePostUso',
      ],
      customBlockMessage: 'No tienes acceso a la gestión de espacios comunes',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Espacios Comunes'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de espacios comunes'),
        ),
      ),
    );
  }
}

// EJEMPLO 5: Pantalla de multas
class MultasScreen extends StatelessWidget {
  const MultasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'multas',
      specificPermissions: [
        'crearMulta',
        'gestionadorMultas',
        'historialMultas',
      ],
      customBlockMessage: 'No tienes permisos para gestionar multas',
      blockIcon: Icons.gavel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Multas'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de multas'),
        ),
      ),
    );
  }
}

// EJEMPLO 6: Pantalla de gastos comunes (solo administradores y residentes)
class GastosComunesScreen extends StatelessWidget {
  const GastosComunesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenNavigator(
      primaryPermission: 'gastosComunes',
      customBlockMessage: 'No tienes acceso a la información de gastos comunes',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gastos Comunes'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de gastos comunes'),
        ),
      ),
    );
  }
}

// EJEMPLO 7: Pantalla de chat con permisos específicos
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenNavigatorWidget(
      primaryPermission: 'chatEntreRes',
      specificPermissions: [
        'chatEntreRes',
        'chatGrupal',
        'chatAdministrador',
        'chatConserjeria',
        'chatPrivado',
      ],
      customBlockMessage: 'No tienes permisos para acceder al chat',
      blockIcon: Icons.chat,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Text('Contenido de la pantalla de chat'),
        ),
      ),
    );
  }
}

/// GUÍA DE IMPLEMENTACIÓN:
/// 
/// 1. PERMISOS DE PRIMER GRADO DISPONIBLES:
///    - 'correspondencia'
///    - 'controlAcceso'
///    - 'gestionEstacionamientos'
///    - 'espaciosComunes'
///    - 'multas'
///    - 'reclamos'
///    - 'publicaciones'
///    - 'registroDiario'
///    - 'bloqueoVisitas'
///    - 'gastosComunes'
///    - 'turnosTrabajadores'
///    - 'chatEntreRes'
///    - 'chatGrupal'
///    - 'chatAdministrador'
///    - 'chatConserjeria'
///    - 'chatPrivado'
/// 
/// 2. PERMISOS ESPECÍFICOS COMUNES:
///    
///    CORRESPONDENCIA:
///    - 'configuracionCorrespondencias'
///    - 'ingresarCorrespondencia'
///    - 'correspondenciasActivas'
///    - 'historialCorrespondencias'
///    
///    CONTROL DE ACCESO:
///    - 'gestionCamposAdicionales'
///    - 'gestionCamposActivos'
///    - 'crearRegistroAcceso'
///    - 'controlDiario'
///    - 'historialControlAcceso'
///    
///    ESTACIONAMIENTOS:
///    - 'configuracionEstacionamientos'
///    - 'solicitudesEstacionamientos'
///    - 'listaEstacionamientos'
///    - 'estacionamientosVisitas'
///    
///    ESPACIOS COMUNES:
///    - 'gestionEspaciosComunes'
///    - 'solicitudesReservas'
///    - 'revisionesPrePostUso'
///    - 'solicitudesRechazadas'
///    - 'historialRevisiones'
///    
///    GASTOS COMUNES:
///    - 'verTotalGastos'
///    - 'porcentajesPorResidentes'
///    - 'gastosFijos'
///    - 'gastosVariables'
///    - 'gastosAdicionales'
///    
///    MULTAS:
///    - 'crearMulta'
///    - 'gestionadorMultas'
///    - 'historialMultas'
///    
///    RECLAMOS:
///    - 'gestionTiposReclamos'
///    - 'gestionReclamos'
///    
///    PUBLICACIONES:
///    - 'gestionPublicaciones'
///    - 'verPublicaciones'
///    - 'publicacionesTrabajadores'
///    
///    REGISTRO DIARIO:
///    - 'crearNuevoRegistro'
///    - 'registrosDelDia'
///    - 'historialRegistros'
///    
///    BLOQUEO DE VISITAS:
///    - 'crearBloqueoVisitas'
///    - 'visualizarVisitasBloqueadas'
///    
///    TURNOS:
///    - 'crearEditarTurno'
///    - 'registroTurnosRealizados'
///    
///    MENSAJES:
///    - 'chatEntreRes'
///    - 'chatGrupal'
///    - 'chatAdministrador'
///    - 'chatConserjeria'
///    - 'chatPrivado'
/// 
/// 3. REGLAS DE ACCESO:
///    - ADMINISTRADORES: Solo necesitan permiso de primer grado
///    - RESIDENTES: Solo necesitan permiso de primer grado
///    - TRABAJADORES: Necesitan permiso de primer grado Y al menos uno específico
///    - COMITÉ: Necesitan permiso de primer grado Y al menos uno específico
/// 
/// 4. PERSONALIZACIÓN:
///    - customBlockMessage: Mensaje personalizado cuando se bloquea
///    - blockIcon: Icono personalizado para el bloqueo
///    - backgroundColor, textColor, iconColor: Colores personalizados