import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Interceptor que agrega el Bearer token a cada request
/// y refresca el token automáticamente si expira (401).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expirado — limpiar y dejar que go_router redirija a login
      try {
        await _storage.clearTokens();
      } catch (_) {
        // flutter_secure_storage_web puede lanzar FormatException en Chrome
      }
    }
    handler.next(err);
  }
}
