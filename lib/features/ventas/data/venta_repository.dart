import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/venta_model.dart';
class VentaRepository {
  const VentaRepository(this._dio);

  final Dio _dio;

  List<Venta> _parseVentas(Response<dynamic> response) {
    final payload = response.data as Map<String, dynamic>;
    final List<dynamic> data = payload['data'] as List<dynamic>;
    return data
        .map((e) => Venta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /ventas/ordenadas — lista de ventas, más reciente primero
  Future<List<Venta>> listar() async {
    try {
      final response =
          await _dio.get('${AppConstants.ventasEndpoint}/ordenadas');
      return _parseVentas(response);
    } on DioException {
      // Fallback to generic list endpoint when /ordenadas is unavailable.
      final fallback = await _dio.get(AppConstants.ventasEndpoint);
      return _parseVentas(fallback);
    }
  }

  /// GET /ventas — lista completa sin orden garantizado
  Future<List<Venta>> listarTodas() async {
    final response = await _dio.get(AppConstants.ventasEndpoint);
    return _parseVentas(response);
  }

  /// GET /ventas/usuario/{usuario}
  Future<List<Venta>> listarPorUsuario(String usuario) async {
    final encoded = Uri.encodeComponent(usuario);
    final response = await _dio.get(
      '${AppConstants.ventasEndpoint}/usuario/$encoded',
    );
    return _parseVentas(response);
  }

  /// GET /ventas/{id}
  Future<Venta> obtener(int id) async {
    final response =
        await _dio.get('${AppConstants.ventasEndpoint}/$id');
    return Venta.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// POST /ventas — crea una nueva venta (JSON)
  Future<Venta> crear(VentaRequest request) async {
    final response = await _dio.post(
      AppConstants.ventasEndpoint,
      data: request.toJson(),
    );
    return Venta.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// DELETE /ventas/{id}
  Future<void> eliminar(int id) async {
    await _dio.delete('${AppConstants.ventasEndpoint}/$id');
  }

  /// GET /productos/activos — productos disponibles para armar el carrito
  Future<List<ProductoResumen>> productosActivos() async {
    final response = await _dio.get(
        '${AppConstants.productosEndpoint}/activos');
    final List<dynamic> data =
        response.data['data'] as List<dynamic>;
    return data
        .map((e) => ProductoResumen.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<double> totalVentas() async {
    try {
      final response = await _dio.get('${AppConstants.ventasEndpoint}/total');
      return (response.data['data'] as num).toDouble();
    } on DioException {
      final response = await _dio.get('${AppConstants.ventasEndpoint}/resumen');
      return (response.data as num).toDouble();
    }
  }

  /// GET /ventas/resumen — total plano (sin envoltura SuccessResponse)
  Future<double> resumenTotal() async {
    final response = await _dio.get('${AppConstants.ventasEndpoint}/resumen');
    return (response.data as num).toDouble();
  }

  // ---- pagos ---------------------------------------------------------------

  /// POST /ventas/{id}/pagos
  Future<PagoVenta> registrarPago(int ventaId, PagoVentaRequest request) async {
    final response = await _dio.post(
      '${AppConstants.ventasEndpoint}/$ventaId/pagos',
      data: request.toJson(),
    );
    return PagoVenta.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /ventas/{id}/pagos
  Future<List<PagoVenta>> listarPagos(int ventaId) async {
    final response =
        await _dio.get('${AppConstants.ventasEndpoint}/$ventaId/pagos');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => PagoVenta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /ventas/{id}/saldo
  Future<SaldoVenta> obtenerSaldo(int ventaId) async {
    final response =
        await _dio.get('${AppConstants.ventasEndpoint}/$ventaId/saldo');
    return SaldoVenta.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /ventas/con-pendientes
  Future<List<SaldoVenta>> ventasConPendiente() async {
    final response =
        await _dio.get('${AppConstants.ventasEndpoint}/con-pendientes');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => SaldoVenta.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

