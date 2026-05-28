import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

/// Interceptor que agrega el Bearer token a cada request
/// y refresca el token automáticamente si expira (401).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  bool _isPublicPath(String path) {
    return path.startsWith(AppConstants.loginEndpoint) ||
        path.startsWith(AppConstants.registerEndpoint) ||
        path.startsWith(AppConstants.refreshEndpoint);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.trim().isNotEmpty) {
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
