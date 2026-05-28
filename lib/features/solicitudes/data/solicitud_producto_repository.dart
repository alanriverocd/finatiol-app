import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/solicitud_producto_model.dart';

class SolicitudProductoRepository {
  SolicitudProductoRepository(this._dio);

  final Dio _dio;

  List<SolicitudProducto> _parseList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SolicitudProducto.fromJson)
            .toList();
      }
    }

    return const [];
  }

  Future<List<SolicitudProducto>> listarMias() async {
    final response = await _dio.get('${AppConstants.solicitudesEndpoint}/mias');
    return _parseList(response.data);
  }

  Future<List<SolicitudProducto>> listarTodas() async {
    final response = await _dio.get(AppConstants.solicitudesEndpoint);
    return _parseList(response.data);
  }

  Future<SolicitudProducto> actualizarEstado({
    required int id,
    required String estado,
    String? comentario,
  }) async {
    final response = await _dio.put(
      '${AppConstants.solicitudesEndpoint}/$id/estado',
      data: {
        'estado': estado,
        'comentario': comentario,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return SolicitudProducto.fromJson(raw['data'] as Map<String, dynamic>);
    }

    throw const FormatException('Respuesta inválida al actualizar estado');
  }
}
