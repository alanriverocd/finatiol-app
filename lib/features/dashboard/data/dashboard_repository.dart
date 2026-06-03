import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardStats> getStats() async {
    final responses = await Future.wait<dynamic>([
      _dio.get('${AppConstants.dashboardEndpoint}/resumen'),
      _dio.get('${AppConstants.ventasEndpoint}/ordenadas'),
      _dio.get('${AppConstants.finanzasEndpoint}/total-ingresos'),
      _dio.get('${AppConstants.finanzasEndpoint}/total-egresos'),
    ]);

    final dashboardPayload =
        (responses[0] as Response<dynamic>).data as Map<String, dynamic>;
    final ventasPayload =
        (responses[1] as Response<dynamic>).data as Map<String, dynamic>;
    final ventasData = ventasPayload['data'] as List<dynamic>? ?? const [];

    var ingresos = _readWrappedNumber((responses[2] as Response<dynamic>).data);
    final egresos = _readWrappedNumber((responses[3] as Response<dynamic>).data);
    final ventasPorMes = _aggregateVentasPorMes(ventasData);
    final totalVentasMonto = _toDouble(dashboardPayload['ventasTotales']);

    if (ingresos == 0 && egresos == 0 && ventasData.isNotEmpty) {
      ingresos = ventasData
          .whereType<Map<String, dynamic>>()
          .map((item) => _toDouble(item['total']))
          .fold<double>(0, (sum, value) => sum + value);
    }

    return DashboardStats(
      totalVentas: ventasData.length,
      totalProductos: _toInt(dashboardPayload['productosActivos']),
      totalUsuarios: _toInt(dashboardPayload['usuarios']),
      ingresos: ingresos,
      egresos: egresos,
      ventasPorMes: ventasPorMes,
      ventasTotalesMonto: totalVentasMonto,
      balanceCalculado: _toDouble(dashboardPayload['balance']),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  double _readWrappedNumber(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      return _toDouble(data);
    }
    return _toDouble(payload);
  }

  List<VentaMes> _aggregateVentasPorMes(List<dynamic> ventasData) {
    final totals = <String, double>{};
    for (final item in ventasData) {
      if (item is! Map<String, dynamic>) continue;
      final rawDate = item['fecha'];
      final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;
      if (parsed == null) continue;
      final key = _monthLabel(parsed.month);
      final total = _toDouble(item['total']);
      totals.update(key, (value) => value + total, ifAbsent: () => total);
    }

    const order = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return order
        .where(totals.containsKey)
        .map((month) => VentaMes(mes: month, total: totals[month]!))
        .toList();
  }

  String _monthLabel(int month) {
    const labels = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    if (month < 1 || month > 12) return 'N/A';
    return labels[month - 1];
  }
}
