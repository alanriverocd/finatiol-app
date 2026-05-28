import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> getStats() async {
    final response = await _dio.get('${AppConstants.dashboardEndpoint}/resumen');
    return DashboardStats.fromJson(response.data as Map<String, dynamic>);
  }
}
