import 'package:equatable/equatable.dart';

class ProductoImagen {
  const ProductoImagen({
    required this.id,
    required this.url,
    this.orden = 0,
  });

  final int id;
  final String url;
  final int orden;

  factory ProductoImagen.fromJson(Map<String, dynamic> json) => ProductoImagen(
        id: (json['id'] as num).toInt(),
        url: (json['url'] as String)
            .replaceFirst('http://finatiol-minio:9000', 'http://localhost:9000'),
        orden: (json['orden'] as num?)?.toInt() ?? 0,
      );
}

class Producto extends Equatable {
  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    required this.activo,
    this.imagenes = const [],
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final bool activo;
  final List<ProductoImagen> imagenes;

  /// Convenience: URL de la primera imagen, o null si no hay.
  String? get imagenUrl => imagenes.isNotEmpty ? imagenes.first.url : null;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        stock: (json['stock'] as num).toInt(),
        activo: json['activo'] as bool? ?? true,
        imagenes: (json['imagenes'] as List<dynamic>?)
                ?.map((e) => ProductoImagen.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'stock': stock,
      };

  Producto copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    bool? activo,
    List<ProductoImagen>? imagenes,
  }) =>
      Producto(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        precio: precio ?? this.precio,
        stock: stock ?? this.stock,
        activo: activo ?? this.activo,
        imagenes: imagenes ?? this.imagenes,
      );

  @override
  List<Object?> get props =>
      [id, nombre, descripcion, precio, stock, activo, imagenes];
}

class ProductoRequest {
  const ProductoRequest({
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
  });

  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'precio': precio,
        'stock': stock,
      };
}

