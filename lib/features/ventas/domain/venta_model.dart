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
