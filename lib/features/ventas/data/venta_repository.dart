import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/venta_model.dart';

class VentaRepository {
  const VentaRepository(this._dio);

  final Dio _dio;

  /// GET /ventas/ordenadas — lista de ventas, más reciente primero
  Future<List<Venta>> listar() async {
    final response =
        await _dio.get('${AppConstants.ventasEndpoint}/ordenadas');
    final List<dynamic> data =
        response.data['data'] as List<dynamic>;
    return data
        .map((e) => Venta.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final response = await _dio.get('${AppConstants.ventasEndpoint}/total');
    return (response.data['data'] as num).toDouble();
  }
}
