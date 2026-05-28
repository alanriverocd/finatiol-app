import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/producto_model.dart';

class ProductoRepository {
  ProductoRepository(this._dio);

  final Dio _dio;

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data;
      }
      if (data is Map<String, dynamic>) {
        if (data['items'] is List) {
          return data['items'] as List<dynamic>;
        }
        if (data['content'] is List) {
          return data['content'] as List<dynamic>;
        }
      }
      if (payload['content'] is List) {
        return payload['content'] as List<dynamic>;
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return payload;
    }
    return const {};
  }

  int _extractInt(dynamic payload) {
    if (payload is num) {
      return payload.toInt();
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is num) {
        return data.toInt();
      }
      if (data is Map<String, dynamic>) {
        final mapValue = data['totalActivos'] ?? data['total'] ?? data['count'];
        if (mapValue is num) {
          return mapValue.toInt();
        }
      }
      final value = payload['totalActivos'] ?? payload['total'] ?? payload['count'];
      if (value is num) {
        return value.toInt();
      }
    }
    return 0;
  }

  Future<List<Producto>> listar() async {
    final response = await _dio.get(AppConstants.productosEndpoint);
    final data = _extractList(response.data);
    return data
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Producto>> listarActivos() async {
    final response =
        await _dio.get('${AppConstants.productosEndpoint}/activos');
    final data = _extractList(response.data);
    return data
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> contarActivos() async {
    final response = await _dio.get('${AppConstants.productosEndpoint}/resumen');
    return _extractInt(response.data);
  }

  Future<Producto> obtener(int id) async {
    final response =
        await _dio.get('${AppConstants.productosEndpoint}/$id');
    return Producto.fromJson(_extractMap(response.data));
  }

  /// Crea un producto enviando multipart/form-data con hasta 10 imágenes opcionales.
  Future<Producto> crear(ProductoRequest req,
      {List<XFile> imagenes = const []}) async {
    final formData = FormData.fromMap({
      'nombre': req.nombre,
      if (req.descripcion != null) 'descripcion': req.descripcion,
      'precio': req.precio.toString(),
      'stock': req.stock.toString(),
    });
    for (final img in imagenes.take(10)) {
      final bytes = await img.readAsBytes();
      formData.files.add(MapEntry(
        'imagenes',
        MultipartFile.fromBytes(bytes, filename: img.name),
      ));
    }
    final response = await _dio.post(
      AppConstants.productosEndpoint,
      data: formData,
    );
    return Producto.fromJson(_extractMap(response.data));
  }

  Future<Producto> actualizar(int id, ProductoRequest req) async {
    final response = await _dio.put(
      '${AppConstants.productosEndpoint}/$id',
      data: req.toJson(),
    );
    return Producto.fromJson(_extractMap(response.data));
  }

  /// Agrega imágenes a un producto existente (el total no puede superar 10).
  Future<Producto> agregarImagenes(int productoId, List<XFile> imagenes) async {
    final formData = FormData();
    for (final img in imagenes) {
      final bytes = await img.readAsBytes();
      formData.files.add(MapEntry(
        'imagenes',
        MultipartFile.fromBytes(bytes, filename: img.name),
      ));
    }
    final response = await _dio.post(
      '${AppConstants.productosEndpoint}/$productoId/imagenes',
      data: formData,
    );
    return Producto.fromJson(_extractMap(response.data));
  }

  /// Elimina una imagen específica de un producto.
  Future<void> eliminarImagen(int productoId, int imagenId) async {
    await _dio.delete(
        '${AppConstants.productosEndpoint}/$productoId/imagenes/$imagenId');
  }

  Future<void> eliminar(int id) =>
      _dio.delete('${AppConstants.productosEndpoint}/$id');
}

