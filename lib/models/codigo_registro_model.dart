import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioRegistrado {
  final String id;
  final String nombre;
  final String uidUsuario;
  final String fecha;

  UsuarioRegistrado({
    required this.id,
    required this.nombre,
    required this.uidUsuario,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'uidUsuario': uidUsuario,
      'fecha': fecha,
    };
  }

  factory UsuarioRegistrado.fromMap(Map<String, dynamic> map) {
    return UsuarioRegistrado(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      uidUsuario: map['uidUsuario'] ?? '',
      fecha: map['fecha'] ?? '',
    );
  }
}

class CodigoRegistroModel {
  final String id;
  final String codigo;
  final String tipoUsuario;
  final String cantUsuarios;
  final String fechaIngreso;
  final String estado;
  final List<UsuarioRegistrado> usuariosRegistrados;

  CodigoRegistroModel({
    required this.id,
    required this.codigo,
    required this.tipoUsuario,
    required this.cantUsuarios,
    required this.fechaIngreso,
    required this.estado,
    this.usuariosRegistrados = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'tipoUsuario': tipoUsuario,
      'cantUsuarios': cantUsuarios,
      'fechaIngreso': fechaIngreso,
      'estado': estado,
      'usuariosRegistrados': usuariosRegistrados.map((usuario) => usuario.toMap()).toList(),
    };
  }

  factory CodigoRegistroModel.fromMap(Map<String, dynamic> map) {
    List<UsuarioRegistrado> usuarios = [];
    if (map['usuariosRegistrados'] != null) {
      usuarios = (map['usuariosRegistrados'] as List)
          .map((usuario) => UsuarioRegistrado.fromMap(usuario))
          .toList();
    }

    return CodigoRegistroModel(
      id: map['id'] ?? '',
      codigo: map['codigo'] ?? '',
      tipoUsuario: map['tipoUsuario'] ?? '',
      cantUsuarios: map['cantUsuarios'] ?? '',
      fechaIngreso: map['fechaIngreso'] ?? '',
      estado: map['estado'] ?? '',
      usuariosRegistrados: usuarios,
    );
  }

  factory CodigoRegistroModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CodigoRegistroModel.fromMap(data);
  }

  CodigoRegistroModel copyWith({
    String? id,
    String? codigo,
    String? tipoUsuario,
    String? cantUsuarios,
    String? fechaIngreso,
    String? estado,
    List<UsuarioRegistrado>? usuariosRegistrados,
  }) {
    return CodigoRegistroModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      cantUsuarios: cantUsuarios ?? this.cantUsuarios,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      estado: estado ?? this.estado,
      usuariosRegistrados: usuariosRegistrados ?? this.usuariosRegistrados,
    );
  }

  // Método para verificar si el código está activo
  bool get isActivo => estado == 'activo';

  // Método para verificar si el código está lleno
  bool get isLleno {
    int cantidadMaxima = int.tryParse(cantUsuarios) ?? 0;
    return usuariosRegistrados.length >= cantidadMaxima;
  }

  // Método para obtener espacios disponibles
  int get espaciosDisponibles {
    int cantidadMaxima = int.tryParse(cantUsuarios) ?? 0;
    return cantidadMaxima - usuariosRegistrados.length;
  }
}

// Modelo para la validación global de códigos
class CodigoGlobalModel {
  final String id;
  final String codigo;
  final String idCondominio;
  final String fecha;

  CodigoGlobalModel({
    required this.id,
    required this.codigo,
    required this.idCondominio,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'idCondominio': idCondominio,
      'fecha': fecha,
    };
  }

  factory CodigoGlobalModel.fromMap(Map<String, dynamic> map) {
    return CodigoGlobalModel(
      id: map['id'] ?? '',
      codigo: map['codigo'] ?? '',
      idCondominio: map['idCondominio'] ?? '',
      fecha: map['fecha'] ?? '',
    );
  }

  factory CodigoGlobalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CodigoGlobalModel.fromMap(data);
  }
}