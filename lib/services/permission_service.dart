import 'package:flutter/material.dart';
import 'package:comunidad_activa/models/user_model.dart';
import 'package:comunidad_activa/models/condominio_model.dart';
import 'package:comunidad_activa/models/trabajador_model.dart';
import 'package:comunidad_activa/models/comite_model.dart';
import 'package:comunidad_activa/services/firestore_service.dart';

/// Resultado de la verificación de permisos
class PermissionResult {
  final bool hasAccess;
  final String? blockMessage;
  final UserModel? user;
  final CondominioModel? condominio;
  final String? error;

  const PermissionResult({
    required this.hasAccess,
    this.blockMessage,
    this.user,
    this.condominio,
    this.error,
  });

  /// Constructor para acceso concedido
  factory PermissionResult.granted({
    required UserModel user,
    required CondominioModel condominio,
  }) {
    return PermissionResult(
      hasAccess: true,
      user: user,
      condominio: condominio,
    );
  }

  /// Constructor para acceso denegado
  factory PermissionResult.denied({
    required String message,
    UserModel? user,
    CondominioModel? condominio,
  }) {
    return PermissionResult(
      hasAccess: false,
      blockMessage: message,
      user: user,
      condominio: condominio,
    );
  }

  /// Constructor para error
  factory PermissionResult.error({
    required String error,
  }) {
    return PermissionResult(
      hasAccess: false,
      error: error,
    );
  }
}

/// Servicio para verificación de permisos de pantallas
class PermissionService {
  static final FirestoreService _firestoreService = FirestoreService();

  /// Verifica los permisos de acceso a una pantalla
  /// 
  /// [primaryPermission] - Permiso de primer grado requerido
  /// [specificPermissions] - Lista de permisos específicos (opcional)
  /// [customBlockMessage] - Mensaje personalizado cuando se bloquea (opcional)
  static Future<PermissionResult> checkScreenPermissions({
    required String primaryPermission,
    List<String>? specificPermissions,
    String? customBlockMessage,
  }) async {
    try {
      // Obtener datos del usuario actual
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) {
        return PermissionResult.error(
          error: 'No se pudo obtener información del usuario',
        );
      }

      // Obtener datos del condominio
      final condominio = await _firestoreService.getCondominioData(user.condominioId!);
      if (condominio == null) {
        return PermissionResult.error(
          error: 'No se pudo obtener información del condominio',
        );
      }

      // Verificar permiso de primer grado
      final hasPrimaryPermission = _checkPrimaryPermission(condominio, primaryPermission);
      
      if (!hasPrimaryPermission) {
        // Si no tiene permiso de primer grado, bloquear para todos
        return PermissionResult.denied(
          message: customBlockMessage ?? 'No tienes permisos para acceder a esta pantalla',
          user: user,
          condominio: condominio,
        );
      }

      // Si tiene permiso de primer grado, verificar permisos específicos según el tipo de usuario
      if (user.tipoUsuario == UserType.administrador || user.tipoUsuario == UserType.residente) {
        // Administradores y residentes solo necesitan permiso de primer grado
        return PermissionResult.granted(
          user: user,
          condominio: condominio,
        );
      } else {
        // Trabajadores y comité necesitan permisos específicos
        final hasSpecificPermission = await _checkSpecificPermissions(
          user,
          specificPermissions ?? [],
        );

        if (hasSpecificPermission) {
          return PermissionResult.granted(
            user: user,
            condominio: condominio,
          );
        } else {
          return PermissionResult.denied(
            message: customBlockMessage ?? 'No tienes los permisos específicos necesarios para esta pantalla',
            user: user,
            condominio: condominio,
          );
        }
      }
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      return PermissionResult.error(
        error: 'Error al verificar permisos: $e',
      );
    }
  }

  /// Verifica si un usuario tiene un permiso específico
  /// 
  /// Útil para verificaciones puntuales en la UI
  static Future<bool> hasPermission({
    required String primaryPermission,
    List<String>? specificPermissions,
  }) async {
    final result = await checkScreenPermissions(
      primaryPermission: primaryPermission,
      specificPermissions: specificPermissions,
    );
    return result.hasAccess;
  }

  /// Verifica si un usuario tiene acceso a una funcionalidad específica
  /// 
  /// [functionName] - Nombre de la función a verificar
  /// Retorna true si el usuario tiene acceso, false en caso contrario
  static Future<bool> canAccessFunction(String functionName) async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) return false;

      final condominio = await _firestoreService.getCondominioData(user.condominioId!);
      if (condominio == null) return false;

      // Verificar permiso de primer grado
      final hasPrimaryPermission = _checkPrimaryPermission(condominio, functionName);
      if (!hasPrimaryPermission) return false;

      // Si es admin o residente, solo necesita permiso de primer grado
      if (user.tipoUsuario == UserType.administrador || user.tipoUsuario == UserType.residente) {
        return true;
      }

      // Para trabajadores y comité, verificar permisos específicos
      return await _checkSpecificPermissions(user, [functionName]);
    } catch (e) {
      debugPrint('Error al verificar función: $e');
      return false;
    }
  }

  /// Obtiene todos los permisos de primer grado del condominio
  static Future<Map<String, bool>?> getPrimaryPermissions() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) return null;

      final condominio = await _firestoreService.getCondominioData(user.condominioId!);
      if (condominio == null) return null;

      // Convertir Map<String, dynamic> a Map<String, bool>
      final gestionFuncionesMap = condominio.gestionFunciones.toMap();
      return gestionFuncionesMap.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      debugPrint('Error al obtener permisos primarios: $e');
      return null;
    }
  }

  /// Stream para escuchar cambios en permisos de primer grado en tiempo real
  static Stream<Map<String, bool>?> getPrimaryPermissionsStream() async* {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) {
        yield null;
        return;
      }

      await for (final condominio in _firestoreService.getCondominioStream(user.condominioId!)) {
        if (condominio == null) {
          yield null;
          continue;
        }

        // Convertir Map<String, dynamic> a Map<String, bool>
        final gestionFuncionesMap = condominio.gestionFunciones.toMap();
        yield gestionFuncionesMap.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      debugPrint('Error en stream de permisos primarios: $e');
      yield null;
    }
  }

  /// Obtiene los permisos específicos del usuario actual
  static Future<Map<String, bool>?> getSpecificPermissions() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) return null;

      if (user.tipoUsuario == UserType.administrador || user.tipoUsuario == UserType.residente) {
        // Admins y residentes no tienen permisos específicos
        return <String, bool>{};
      }

      return await _getSpecificPermissionsForUser(user);
    } catch (e) {
      debugPrint('Error al obtener permisos específicos: $e');
      return null;
    }
  }

  /// Obtiene información completa de permisos del usuario
  static Future<Map<String, dynamic>?> getUserPermissionsInfo() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) return null;

      final condominio = await _firestoreService.getCondominioData(user.condominioId!);
      if (condominio == null) return null;

      final primaryPermissions = condominio.gestionFunciones.toMap();
      final specificPermissions = await _getSpecificPermissionsForUser(user);

      return {
        'user': user.toMap(),
        'userType': user.tipoUsuario.toString(),
        'primaryPermissions': primaryPermissions,
        'specificPermissions': specificPermissions,
        'condominioId': user.condominioId,
      };
    } catch (e) {
      debugPrint('Error al obtener información de permisos: $e');
      return null;
    }
  }

  /// Verifica múltiples permisos de una vez
  /// 
  /// [permissions] - Lista de permisos a verificar
  /// Retorna un Map con el resultado de cada permiso
  static Future<Map<String, bool>> checkMultiplePermissions(List<String> permissions) async {
    final results = <String, bool>{};
    
    for (final permission in permissions) {
      results[permission] = await hasPermission(primaryPermission: permission);
    }
    
    return results;
  }

  /// Verifica si el usuario actual es administrador
  static Future<bool> isAdmin() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      return user?.tipoUsuario == UserType.administrador;
    } catch (e) {
      debugPrint('Error al verificar si es admin: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual es residente
  static Future<bool> isResident() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      return user?.tipoUsuario == UserType.residente;
    } catch (e) {
      debugPrint('Error al verificar si es residente: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual es trabajador
  static Future<bool> isWorker() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      return user?.tipoUsuario == UserType.trabajador;
    } catch (e) {
      debugPrint('Error al verificar si es trabajador: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual es miembro del comité
  static Future<bool> isCommittee() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      return user?.tipoUsuario == UserType.comite;
    } catch (e) {
      debugPrint('Error al verificar si es comité: $e');
      return false;
    }
  }

  /// Obtiene el tipo de usuario actual
  static Future<UserType?> getCurrentUserType() async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      return user?.tipoUsuario;
    } catch (e) {
      debugPrint('Error al obtener tipo de usuario: $e');
      return null;
    }
  }

  /// Verifica si una función específica está habilitada en el condominio
  /// 
  /// [functionName] - Nombre de la función a verificar
  /// Retorna true si la función está habilitada, false en caso contrario
  static Future<bool> isFunctionEnabled(String functionName) async {
    try {
      final user = await _firestoreService.getCurrentUserData();
      if (user == null) return false;

      final condominio = await _firestoreService.getCondominioData(user.condominioId!);
      if (condominio == null) return false;

      return _checkPrimaryPermission(condominio, functionName);
    } catch (e) {
      debugPrint('Error al verificar función habilitada: $e');
      return false;
    }
  }

  // MÉTODOS PRIVADOS

  /// Verifica el permiso de primer grado en el condominio
  static bool _checkPrimaryPermission(CondominioModel condominio, String permission) {
    final gestionFunciones = condominio.gestionFunciones.toMap();
    return gestionFunciones[permission] ?? false;
  }

  /// Verifica los permisos específicos del usuario
  static Future<bool> _checkSpecificPermissions(
    UserModel user,
    List<String> specificPermissions,
  ) async {
    if (specificPermissions.isEmpty) {
      return false; // Si no hay permisos específicos definidos, denegar acceso
    }

    try {
      final userSpecificPermissions = await _getSpecificPermissionsForUser(user);
      
      // Verificar si al menos uno de los permisos específicos está activo
      for (String permission in specificPermissions) {
        if (userSpecificPermissions[permission] == true) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error al verificar permisos específicos: $e');
      return false;
    }
  }

  /// Obtiene los permisos específicos según el tipo de usuario
  static Future<Map<String, bool>> _getSpecificPermissionsForUser(UserModel user) async {
    if (user.tipoUsuario == UserType.administrador || user.tipoUsuario == UserType.residente) {
      return <String, bool>{}; // No tienen permisos específicos
    }

    if (user.tipoUsuario == UserType.trabajador) {
      return await _getTrabajadorPermissions(user.condominioId!, user);
    } else if (user.tipoUsuario == UserType.comite) {
      return await _getComitePermissions(user.condominioId!, user);
    }

    return <String, bool>{};
  }

  /// Obtiene los permisos específicos de un trabajador
  static Future<Map<String, bool>> _getTrabajadorPermissions(
    String condominioId,
    UserModel user,
  ) async {
    try {
      // Obtener trabajadores del condominio
      final trabajadores = await _firestoreService.obtenerTrabajadoresCondominio(condominioId);
      final trabajador = trabajadores.firstWhere(
        (t) => t.uid == user.uid,
        orElse: () => throw Exception('Trabajador no encontrado'),
      );

      return trabajador.funcionesDisponibles;
    } catch (e) {
      debugPrint('Error al obtener permisos de trabajador: $e');
      return <String, bool>{};
    }
  }

  /// Obtiene los permisos específicos de un miembro del comité
  static Future<Map<String, bool>> _getComitePermissions(
    String condominioId,
    UserModel user,
  ) async {
    try {
      // Obtener miembros del comité del condominio
      final comiteMembers = await _firestoreService.obtenerMiembrosComite(condominioId);
      final comiteMember = comiteMembers.firstWhere(
        (c) => c.uid == user.uid,
        orElse: () => throw Exception('Miembro del comité no encontrado'),
      );

      return comiteMember.funcionesDisponibles;
    } catch (e) {
      debugPrint('Error al obtener permisos de comité: $e');
      return <String, bool>{};
    }
  }
}