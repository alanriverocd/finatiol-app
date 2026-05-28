import 'package:equatable/equatable.dart';

class LoginRequest extends Equatable {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  @override
  List<Object> get props => [username, password];
}

class AuthResponse extends Equatable {
  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.username,
    required this.roles,
    required this.permisos,
    this.tenantId,
  });

  final String accessToken;
  final String? refreshToken;
  final String username;
  final List<String> roles;
  final List<String> permisos;
  final String? tenantId;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        username: json['username'] as String? ?? '',
        roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? [],
        permisos: (json['permisos'] as List<dynamic>?)?.cast<String>() ?? [],
        tenantId: json['tenantId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'username': username,
        'roles': roles,
        'permisos': permisos,
        'tenantId': tenantId,
      };

  @override
  List<Object?> get props => [accessToken, username, roles, permisos, tenantId];
}
