// Constantes globales de la aplicación Finatiol
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  // URL base del API Gateway — varía por plataforma
  // Web (Chrome): localhost | Android emulator: 10.0.2.2 | Dispositivo físico: IP local
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  // Endpoints — prefijo requerido por Spring Cloud Gateway Discovery Locator
  static const String loginEndpoint    = '/finatiol-autenticacion-ms/auth/login';
  static const String registerEndpoint = '/finatiol-usuarios-ms/usuarios/registro';
  static const String solicitudesEndpoint = '/finatiol-usuarios-ms/usuarios/solicitudes';
  static const String refreshEndpoint  = '/finatiol-autenticacion-ms/auth/refresh';
  static const String productosEndpoint = '/finatiol-productos-ms/productos';
  static const String ventasEndpoint    = '/finatiol-ventas-ms/ventas';
  static const String usuariosEndpoint  = '/finatiol-usuarios-ms/usuarios';
  static const String finanzasEndpoint  = '/finatiol-finanzas-ms/finanzas';
  static const String dashboardEndpoint = '/finatiol-dashboard-ms/dashboard';
  static const String ahorrosEndpoint   = '/finatiol-caja-ahorro-ms/ahorros';

  // Storage keys
  static const String tokenKey = 'finatiol_access_token';
  static const String refreshTokenKey = 'finatiol_refresh_token';
  static const String userKey = 'finatiol_user';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
