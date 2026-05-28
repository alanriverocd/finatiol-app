import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';

class CatalogosAdminRepository {
  CatalogosAdminRepository(this._dio);

  final Dio _dio;
  static const String _usuariosServiceBase = '/finatiol-usuarios-ms';

  dynamic _data(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData['data'] != null) {
      return responseData['data'];
    }
    return responseData;
  }

  Future<List<Map<String, dynamic>>> listarTenants() async {
    final response = await _dio.get('${AppConstants.usuariosEndpoint.replaceFirst('/usuarios', '')}/tenants');
    return (_data(response.data) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> crearTenant({
    required String id,
    required String nombre,
  }) async {
    final response = await _dio.post(
      '${AppConstants.usuariosEndpoint.replaceFirst('/usuarios', '')}/tenants',
      data: {'id': id, 'nombre': nombre},
    );
    return Map<String, dynamic>.from(_data(response.data) as Map);
  }

  Future<void> eliminarTenant(String id) async {
    await _dio.delete('${AppConstants.usuariosEndpoint.replaceFirst('/usuarios', '')}/tenants/$id');
  }

  Future<List<Map<String, dynamic>>> listarRoles() async {
    final response = await _dio.get('$_usuariosServiceBase/roles');
    return (_data(response.data) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> crearRol({
    required String nombre,
    required String descripcion,
    Set<int> permisosIds = const {},
  }) async {
    final response = await _dio.post(
      '$_usuariosServiceBase/roles',
      data: {
        'nombre': nombre,
        'descripcion': descripcion,
        'permisosIds': permisosIds.toList(),
      },
    );
    return Map<String, dynamic>.from(_data(response.data) as Map);
  }

  Future<void> eliminarRol(int id) async {
    await _dio.delete('$_usuariosServiceBase/roles/$id');
  }

  Future<List<Map<String, dynamic>>> listarPermisos() async {
    final response = await _dio.get('$_usuariosServiceBase/permisos');
    return (_data(response.data) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> crearPermiso({
    required String nombre,
    required String descripcion,
    int? moduloId,
  }) async {
    final data = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
    };
    if (moduloId != null) {
      data['moduloId'] = moduloId;
    }
    final response = await _dio.post(
      '$_usuariosServiceBase/permisos',
      data: data,
    );
    return Map<String, dynamic>.from(_data(response.data) as Map);
  }

  Future<void> eliminarPermiso(int id) async {
    await _dio.delete('$_usuariosServiceBase/permisos/$id');
  }

  Future<List<Map<String, dynamic>>> listarModulos() async {
    final response = await _dio.get('$_usuariosServiceBase/modulos');
    return (_data(response.data) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> crearModulo({
    required String nombre,
    required String descripcion,
    required String ruta,
    required String icono,
    required bool activo,
  }) async {
    final response = await _dio.post(
      '$_usuariosServiceBase/modulos',
      data: {
        'nombre': nombre,
        'descripcion': descripcion,
        'ruta': ruta,
        'icono': icono,
        'activo': activo,
      },
    );
    return Map<String, dynamic>.from(_data(response.data) as Map);
  }

  Future<void> eliminarModulo(int id) async {
    await _dio.delete('$_usuariosServiceBase/modulos/$id');
  }
}