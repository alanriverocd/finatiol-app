import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Tipo de movimiento
// ---------------------------------------------------------------------------
enum TipoMovimiento { ingreso, egreso }

extension TipoMovimientoExt on TipoMovimiento {
  String get label => name[0].toUpperCase() + name.substring(1);

  /// Valor que espera el backend (INGRESO / EGRESO)
  String get backendValue => name.toUpperCase();
}

// ---------------------------------------------------------------------------
// Movimiento financiero (respuesta del servidor)
// ---------------------------------------------------------------------------
class Movimiento extends Equatable {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.fecha,
    this.referencia,
  });

  final int id;
  final TipoMovimiento tipo;
  final String concepto;
  final double monto;
  final DateTime fecha;
  final String? referencia;

  factory Movimiento.fromJson(Map<String, dynamic> json) => Movimiento(
        id: (json['id'] as num).toInt(),
        tipo: TipoMovimiento.values.firstWhere(
          (e) => e.backendValue == (json['tipo'] as String),
          orElse: () => TipoMovimiento.ingreso,
        ),
        concepto: (json['concepto'] as String?) ?? '',
        monto: (json['monto'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha'] as String),
        referencia: json['referencia'] as String?,
      );

  @override
  List<Object?> get props => [id, tipo, concepto, monto, fecha, referencia];
}

// ---------------------------------------------------------------------------
// Request para registrar un movimiento
// ---------------------------------------------------------------------------
class MovimientoRequest {
  const MovimientoRequest({
    required this.tipo,
    required this.concepto,
    required this.monto,
    this.referencia,
  });

  final TipoMovimiento tipo;
  final String concepto;
  final double monto;
  final String? referencia;

  Map<String, dynamic> toJson() => {
        'tipo': tipo.backendValue,
        'concepto': concepto,
        'monto': monto,
        if (referencia != null && referencia!.isNotEmpty)
          'referencia': referencia,
      };
}

class ResumenMensual {
  const ResumenMensual({
    required this.id,
    required this.mes,
    required this.anio,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.balance,
    required this.fechaCierre,
  });

  final int id;
  final int mes;
  final int anio;
  final double totalIngresos;
  final double totalEgresos;
  final double balance;
  final DateTime fechaCierre;

  factory ResumenMensual.fromJson(Map<String, dynamic> json) => ResumenMensual(
        id: (json['id'] as num).toInt(),
        mes: (json['mes'] as num).toInt(),
        anio: (json['anio'] as num).toInt(),
        totalIngresos: (json['totalIngresos'] as num).toDouble(),
        totalEgresos: (json['totalEgresos'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        fechaCierre: DateTime.parse(json['fechaCierre'] as String),
      );
}
