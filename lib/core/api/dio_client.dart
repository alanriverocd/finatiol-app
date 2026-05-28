import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../interceptors/auth_interceptor.dart';
import '../storage/token_storage.dart';

Dio createDio(TokenStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ),
  ]);

  return dio;
}
