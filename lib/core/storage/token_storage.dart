import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedUser;

  String? _normalizeToken(String? token) {
    final cleaned = token?.replaceAll(RegExp(r'\s+'), '');
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final normalizedAccess = _normalizeToken(accessToken);
    final normalizedRefresh = _normalizeToken(refreshToken);

    await _storage.write(key: AppConstants.tokenKey, value: normalizedAccess);
    _cachedAccessToken = normalizedAccess;

    if (refreshToken != null) {
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: normalizedRefresh,
      );
      _cachedRefreshToken = normalizedRefresh;
    }
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    try {
      final token = _normalizeToken(
        await _storage.read(key: AppConstants.tokenKey),
      );
      _cachedAccessToken = token;
      return token;
    } on FormatException {
      // Prevent malformed secure-storage values from crashing request pipeline.
      return _cachedAccessToken;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }
    try {
      final token = _normalizeToken(
        await _storage.read(key: AppConstants.refreshTokenKey),
      );
      _cachedRefreshToken = token;
      return token;
    } on FormatException {
      return _cachedRefreshToken;
    }
  }

  Future<void> saveUser(String userJson) async {
    _cachedUser = userJson;
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }

  Future<String?> getUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }
    try {
      final value = await _storage.read(key: AppConstants.userKey);
      _cachedUser = value;
      return value;
    } on FormatException {
      return _cachedUser;
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
