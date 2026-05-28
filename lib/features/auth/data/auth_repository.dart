import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      AppConstants.loginEndpoint,
      data: request.toJson(),
    );
    final rawAuth = AuthResponse.fromJson(response.data['data'] as Map<String, dynamic>);
    final auth = _enrichAuthFromToken(rawAuth);
    await _storage.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    await _storage.saveUser(jsonEncode(auth.toJson()));
    return auth;
  }

  Future<void> logout() => _storage.clearTokens();

  Future<bool> isAuthenticated() => _storage.hasToken();

  Future<AuthResponse?> getStoredAuth() async {
    final storedUser = await _storage.getUser();
    if (storedUser != null && storedUser.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(storedUser);
        if (decoded is Map<String, dynamic>) {
          final token = await _storage.getAccessToken();
          final refresh = await _storage.getRefreshToken();
          final authFromStorage = AuthResponse.fromJson(decoded);
          return AuthResponse(
            accessToken: token ?? authFromStorage.accessToken,
            refreshToken: refresh ?? authFromStorage.refreshToken,
            username: authFromStorage.username,
            roles: authFromStorage.roles,
            permisos: authFromStorage.permisos,
            tenantId: authFromStorage.tenantId,
          );
        }
      } catch (_) {}
    }

    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final payload = _decodeJwtPayload(token);
    if (payload == null) {
      return null;
    }

    final username = _firstString(payload, const [
      'username',
      'preferred_username',
      'user_name',
      'sub',
    ]);

    final realmAccess = payload['realm_access'];
    final realmRoles = realmAccess is Map<String, dynamic>
        ? _stringList(realmAccess['roles'])
        : const <String>[];
    final roleList = {
      ..._stringList(payload['roles'] ?? payload['rol']),
      ...realmRoles,
    }.toList();
    final permisoList = {
      ..._stringList(payload['permisos'] ?? payload['permissions'] ?? payload['scopes']),
      ..._stringList(payload['authorities']),
    }.toList();

    return AuthResponse(
      accessToken: token,
      refreshToken: await _storage.getRefreshToken(),
      username: username,
      roles: roleList,
      permisos: permisoList,
      tenantId: _firstString(payload, const ['tenantId', 'tenant', 'tid']),
    );
  }

  AuthResponse _enrichAuthFromToken(AuthResponse source) {
    final payload = _decodeJwtPayload(source.accessToken);
    if (payload == null) {
      return source;
    }

    final username = source.username.trim().isNotEmpty
        ? source.username
        : _firstString(payload, const [
            'username',
            'preferred_username',
            'user_name',
            'sub',
          ]);

    final realmAccess = payload['realm_access'];
    final realmRoles = realmAccess is Map<String, dynamic>
        ? _stringList(realmAccess['roles'])
        : const <String>[];
    final roles = {
      ...source.roles,
      ..._stringList(payload['roles'] ?? payload['rol']),
      ...realmRoles,
    }.toList();
    final permisos = {
      ...source.permisos,
      ..._stringList(payload['permisos'] ?? payload['permissions'] ?? payload['scopes']),
      ..._stringList(payload['authorities']),
    }.toList();

    return AuthResponse(
      accessToken: source.accessToken,
      refreshToken: source.refreshToken,
      username: username,
      roles: roles,
      permisos: permisos,
      tenantId: source.tenantId ?? _firstString(payload, const ['tenantId', 'tenant', 'tid']),
    );
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _firstString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      if (raw.contains(',')) {
        return raw
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return [raw.trim()];
    }
    return const [];
  }
}
