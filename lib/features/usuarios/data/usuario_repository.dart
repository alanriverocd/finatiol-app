import 'package:dio/dio.dart';
import '../domain/usuario_model.dart';
import '../../../core/constants/app_constants.dart';

class UsuarioRepository {
  final Dio _dio;

  UsuarioRepository(this._dio);

  Future<List<Usuario>> listar() async {
    final response = await _dio.get(AppConstants.usuariosEndpoint);
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Usuario> obtener(int id) async {
    final response =
        await _dio.get('${AppConstants.usuariosEndpoint}/$id');
    return Usuario.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Usuario> crear(UsuarioRequest request) async {
    final response = await _dio.post(
      AppConstants.usuariosEndpoint,
      data: request.toJson(),
    );
    return Usuario.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Usuario> actualizar(int id, UsuarioRequest request) async {
    final response = await _dio.put(
      '${AppConstants.usuariosEndpoint}/$id',
      data: request.toJson(),
    );
    return Usuario.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> eliminar(int id) async {
    await _dio.delete('${AppConstants.usuariosEndpoint}/$id');
  }

  Future<void> asignarRol(int id, String rolNombre) async {
    await _dio.put('${AppConstants.usuariosEndpoint}/$id/roles/$rolNombre');
  }

  Future<void> removerRol(int id, String rolNombre) async {
    await _dio.delete('${AppConstants.usuariosEndpoint}/$id/roles/$rolNombre');
  }

  Future<int> contar() async {
    final response = await _dio.get('${AppConstants.usuariosEndpoint}/resumen');
    return (response.data as num).toInt();
  }
}
