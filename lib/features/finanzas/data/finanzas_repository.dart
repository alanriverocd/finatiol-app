import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/movimiento_model.dart';

class FinanzasRepository {
  const FinanzasRepository(this._dio);

  final Dio _dio;

  /// GET /finanzas — lista de movimientos
  Future<List<Movimiento>> listar() async {
    final response = await _dio.get(AppConstants.finanzasEndpoint);
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => Movimiento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /finanzas — registra un movimiento
  Future<Movimiento> registrar(MovimientoRequest request) async {
    final response = await _dio.post(
      AppConstants.finanzasEndpoint,
      data: request.toJson(),
    );
    return Movimiento.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// GET /finanzas/total-ingresos
  Future<double> totalIngresos() async {
    final response = await _dio.get(
        '${AppConstants.finanzasEndpoint}/total-ingresos');
    return (response.data['data'] as num).toDouble();
  }

  /// GET /finanzas/total-egresos
  Future<double> totalEgresos() async {
    final response = await _dio.get(
        '${AppConstants.finanzasEndpoint}/total-egresos');
    return (response.data['data'] as num).toDouble();
  }

  /// GET /finanzas/balance
  Future<double> balance() async {
    final response =
        await _dio.get('${AppConstants.finanzasEndpoint}/balance');
    return (response.data['data'] as num).toDouble();
  }

  Future<double> resumenBalance() async {
    final response = await _dio.get('${AppConstants.finanzasEndpoint}/resumen');
    return (response.data as num).toDouble();
  }
}
