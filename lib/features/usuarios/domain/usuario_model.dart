import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final bool activo;
  final List<String> roles;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.activo,
    required this.roles,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        activo: json['activo'] as bool,
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Usuario copyWith({
    int? id,
    String? nombre,
    String? username,
    String? email,
    bool? activo,
    List<String>? roles,
  }) =>
      Usuario(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        username: username ?? this.username,
        email: email ?? this.email,
        activo: activo ?? this.activo,
        roles: roles ?? this.roles,
      );

  @override
  List<Object?> get props => [id, nombre, username, email, activo, roles];
}

class UsuarioRequest {
  final String nombre;
  final String username;
  final String email;
  final String? password;

  const UsuarioRequest({
    required this.nombre,
    required this.username,
    required this.email,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'username': username,
      'email': email,
    };
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }
}
