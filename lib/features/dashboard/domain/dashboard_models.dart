import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalVentas,
    required this.totalProductos,
    required this.totalUsuarios,
    required this.ingresos,
    required this.egresos,
    this.ventasPorMes = const [],
  });

  final int totalVentas;
  final int totalProductos;
  final int totalUsuarios;
  final double ingresos;
  final double egresos;
  final List<VentaMes> ventasPorMes;

  double get balance => ingresos - egresos;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalVentas: json['totalVentas'] as int? ?? 0,
        totalProductos: json['totalProductos'] as int? ?? 0,
        totalUsuarios: json['totalUsuarios'] as int? ?? 0,
        ingresos: (json['ingresos'] as num?)?.toDouble() ?? 0,
        egresos: (json['egresos'] as num?)?.toDouble() ?? 0,
        ventasPorMes: (json['ventasPorMes'] as List<dynamic>? ?? const [])
            .map((item) => VentaMes.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props =>
      [totalVentas, totalProductos, totalUsuarios, ingresos, egresos, ventasPorMes];
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
