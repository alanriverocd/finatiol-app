import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Detalle de una venta
// ---------------------------------------------------------------------------
class DetalleVenta extends Equatable {
  const DetalleVenta({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  final int id;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precio;
  final double subtotal;

  factory DetalleVenta.fromJson(Map<String, dynamic> json) => DetalleVenta(
        id: (json['id'] as num).toInt(),
        productoId: (json['productoId'] as num).toInt(),
        productoNombre: (json['productoNombre'] as String?) ?? '',
        cantidad: (json['cantidad'] as num).toInt(),
        precio: (json['precio'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  @override
  List<Object?> get props =>
      [id, productoId, productoNombre, cantidad, precio, subtotal];
}

// ---------------------------------------------------------------------------
// Venta (respuesta del servidor)
// ---------------------------------------------------------------------------
class Venta extends Equatable {
  const Venta({
    required this.id,
    required this.total,
    required this.fecha,
    required this.usuario,
    required this.detalles,
  });

  final int id;
  final double total;
  final DateTime fecha;
  final String usuario;
  final List<DetalleVenta> detalles;

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: (json['id'] as num).toInt(),
        total: (json['total'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha'] as String),
        usuario: (json['usuario'] as String?) ?? '',
        detalles: (json['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleVenta.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, total, fecha, usuario, detalles];
}

// ---------------------------------------------------------------------------
// Request para crear una venta
// ---------------------------------------------------------------------------
class DetalleVentaRequest {
  const DetalleVentaRequest({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precio,
  });

  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precio;

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'productoNombre': productoNombre,
        'cantidad': cantidad,
        'precio': precio,
      };
}

class VentaRequest {
  const VentaRequest({
    required this.usuario,
    required this.detalles,
  });

  final String usuario;
  final List<DetalleVentaRequest> detalles;

  Map<String, dynamic> toJson() => {
        'usuario': usuario,
        'detalles': detalles.map((d) => d.toJson()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Producto resumido — para el picker en el formulario de venta
// ---------------------------------------------------------------------------
class ProductoResumen {
  const ProductoResumen({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
  });

  final int id;
  final String nombre;
  final double precio;
  final int stock;

  factory ProductoResumen.fromJson(Map<String, dynamic> json) =>
      ProductoResumen(
        id: (json['id'] as num).toInt(),
        nombre: (json['nombre'] as String?) ?? '',
        precio: (json['precio'] as num).toDouble(),
        stock: (json['stock'] as num).toInt(),
      );
}

// ---------------------------------------------------------------------------
// Pago de una venta
// ---------------------------------------------------------------------------
class PagoVenta extends Equatable {
  const PagoVenta({
    required this.id,
    required this.ventaId,
    required this.monto,
    required this.fecha,
    this.concepto,
    this.metodoPago,
    this.registradoPor,
  });

  final int id;
  final int ventaId;
  final double monto;
  final DateTime fecha;
  final String? concepto;
  final String? metodoPago;
  final String? registradoPor;

  factory PagoVenta.fromJson(Map<String, dynamic> json) => PagoVenta(
        id: (json['id'] as num).toInt(),
        ventaId: (json['ventaId'] as num).toInt(),
        monto: (json['monto'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha'] as String),
        concepto: json['concepto'] as String?,
        metodoPago: json['metodoPago'] as String?,
        registradoPor: json['registradoPor'] as String?,
      );

  @override
  List<Object?> get props => [id, ventaId, monto, fecha];
}

// ---------------------------------------------------------------------------
// Saldo de una venta (resumen de pagos)
// ---------------------------------------------------------------------------
class SaldoVenta extends Equatable {
  const SaldoVenta({
    required this.ventaId,
    required this.usuario,
    required this.totalVenta,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.estadoPago,
  });

  final int ventaId;
  final String usuario;
  final double totalVenta;
  final double totalPagado;
  final double saldoPendiente;
  final String estadoPago; // PENDIENTE | PARCIAL | COMPLETO

  factory SaldoVenta.fromJson(Map<String, dynamic> json) => SaldoVenta(
        ventaId: (json['ventaId'] as num).toInt(),
        usuario: (json['usuario'] as String?) ?? '',
        totalVenta: (json['totalVenta'] as num).toDouble(),
        totalPagado: (json['totalPagado'] as num).toDouble(),
        saldoPendiente: (json['saldoPendiente'] as num).toDouble(),
        estadoPago: (json['estadoPago'] as String?) ?? 'PENDIENTE',
      );

  @override
  List<Object?> get props => [ventaId, saldoPendiente, estadoPago];
}

// ---------------------------------------------------------------------------
// Request para registrar un pago
// ---------------------------------------------------------------------------
class PagoVentaRequest {
  const PagoVentaRequest({
    required this.monto,
    this.concepto,
    this.metodoPago,
    this.registradoPor,
  });

  final double monto;
  final String? concepto;
  final String? metodoPago;
  final String? registradoPor;

  Map<String, dynamic> toJson() => {
        'monto': monto,
        if (concepto != null) 'concepto': concepto,
        if (metodoPago != null) 'metodoPago': metodoPago,
        if (registradoPor != null) 'registradoPor': registradoPor,
      };
}

