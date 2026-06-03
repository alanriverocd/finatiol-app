import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalVentas,
    required this.totalProductos,
    required this.totalUsuarios,
    required this.ingresos,
    required this.egresos,
    this.ventasTotalesMonto = 0,
    this.balanceCalculado = 0,
    this.ventasPorMes = const [],
  });

  final int totalVentas;
  final int totalProductos;
  final int totalUsuarios;
  final double ingresos;
  final double egresos;
  final double ventasTotalesMonto;
  final double balanceCalculado;
  final List<VentaMes> ventasPorMes;

  double get balance {
    if (ingresos != 0 || egresos != 0) return ingresos - egresos;
    return balanceCalculado;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalVentas: _parseInt(json['totalVentas'] ?? json['ventasTotales']),
        totalProductos: _parseInt(json['totalProductos'] ?? json['productosActivos']),
        totalUsuarios: _parseInt(json['totalUsuarios'] ?? json['usuarios']),
        ingresos: _parseDouble(json['ingresos']),
        egresos: _parseDouble(json['egresos']),
        ventasTotalesMonto: _parseDouble(json['ventasTotales']),
        balanceCalculado: _parseDouble(json['balance']),
        ventasPorMes: (json['ventasPorMes'] as List<dynamic>? ?? const [])
            .map((item) => VentaMes.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props =>
      [
        totalVentas,
        totalProductos,
        totalUsuarios,
        ingresos,
        egresos,
        ventasTotalesMonto,
        balanceCalculado,
        ventasPorMes,
      ];
}

class VentaMes extends Equatable {
  const VentaMes({required this.mes, required this.total});

  final String mes;
  final double total;

  factory VentaMes.fromJson(Map<String, dynamic> json) => VentaMes(
        mes: json['mes'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object> get props => [mes, total];
}
