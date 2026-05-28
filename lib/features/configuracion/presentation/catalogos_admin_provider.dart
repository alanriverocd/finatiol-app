import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/auth_provider.dart';
import '../data/catalogos_admin_repository.dart';

final catalogosAdminRepositoryProvider = Provider<CatalogosAdminRepository>(
  (ref) => CatalogosAdminRepository(ref.watch(dioProvider)),
);

class CatalogosAdminState {
  const CatalogosAdminState({
    this.tenants = const [],
    this.roles = const [],
    this.permisos = const [],
    this.modulos = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Map<String, dynamic>> tenants;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> permisos;
  final List<Map<String, dynamic>> modulos;
  final bool isLoading;
  final String? error;

  CatalogosAdminState copyWith({
    List<Map<String, dynamic>>? tenants,
    List<Map<String, dynamic>>? roles,
    List<Map<String, dynamic>>? permisos,
    List<Map<String, dynamic>>? modulos,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      CatalogosAdminState(
        tenants: tenants ?? this.tenants,
        roles: roles ?? this.roles,
        permisos: permisos ?? this.permisos,
        modulos: modulos ?? this.modulos,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class CatalogosAdminNotifier extends StateNotifier<CatalogosAdminState> {
  CatalogosAdminNotifier(this._repo) : super(const CatalogosAdminState());

  final CatalogosAdminRepository _repo;

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Tu sesión expiró o no tienes permisos. Vuelve a iniciar sesión.';
    }

    final data = e.response?.data;
    if (data is Map) {
      final message = data['mensaje'] ?? data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return fallback;
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.listarTenants(),
        _repo.listarRoles(),
        _repo.listarPermisos(),
        _repo.listarModulos(),
      ]);
      state = state.copyWith(
        tenants: results[0],
        roles: results[1],
        permisos: results[2],
        modulos: results[3],
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(
          e,
          fallback: 'No se pudieron cargar los catálogos',
        ),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'No se pudieron cargar los catálogos');
    }
  }

  Future<bool> crearTenant(String id, String nombre) async {
    try {
      await _repo.crearTenant(id: id, nombre: nombre);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo crear el tenant');
      return false;
    }
  }

  Future<bool> crearModulo({required String nombre, required String descripcion, required String ruta, required String icono, required bool activo}) async {
    try {
      await _repo.crearModulo(nombre: nombre, descripcion: descripcion, ruta: ruta, icono: icono, activo: activo);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo crear el módulo');
      return false;
    }
  }

  Future<bool> crearPermiso({required String nombre, required String descripcion, int? moduloId}) async {
    try {
      await _repo.crearPermiso(nombre: nombre, descripcion: descripcion, moduloId: moduloId);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo crear el permiso');
      return false;
    }
  }

  Future<bool> crearRol({required String nombre, required String descripcion, Set<int> permisosIds = const {}}) async {
    try {
      await _repo.crearRol(nombre: nombre, descripcion: descripcion, permisosIds: permisosIds);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo crear el rol');
      return false;
    }
  }

  Future<bool> actualizarTenant({
    required String originalId,
    required String id,
    required String nombre,
  }) async {
    try {
      await _repo.eliminarTenant(originalId);
      await _repo.crearTenant(id: id, nombre: nombre);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo actualizar el tenant');
      return false;
    }
  }

  Future<bool> actualizarModulo({
    required int id,
    required String nombre,
    required String descripcion,
    required String ruta,
    required String icono,
    required bool activo,
  }) async {
    try {
      await _repo.eliminarModulo(id);
      await _repo.crearModulo(nombre: nombre, descripcion: descripcion, ruta: ruta, icono: icono, activo: activo);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo actualizar el módulo');
      return false;
    }
  }

  Future<bool> actualizarPermiso({
    required int id,
    required String nombre,
    required String descripcion,
    int? moduloId,
  }) async {
    try {
      await _repo.eliminarPermiso(id);
      await _repo.crearPermiso(nombre: nombre, descripcion: descripcion, moduloId: moduloId);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo actualizar el permiso');
      return false;
    }
  }

  Future<bool> actualizarRol({
    required int id,
    required String nombre,
    required String descripcion,
    Set<int> permisosIds = const {},
  }) async {
    try {
      await _repo.eliminarRol(id);
      await _repo.crearRol(nombre: nombre, descripcion: descripcion, permisosIds: permisosIds);
      await cargar();
      return true;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo actualizar el rol');
      return false;
    }
  }

  Future<void> eliminarTenant(String id) async { await _repo.eliminarTenant(id); await cargar(); }
  Future<void> eliminarModulo(int id) async { await _repo.eliminarModulo(id); await cargar(); }
  Future<void> eliminarPermiso(int id) async { await _repo.eliminarPermiso(id); await cargar(); }
  Future<void> eliminarRol(int id) async { await _repo.eliminarRol(id); await cargar(); }

  void clearError() => state = state.copyWith(clearError: true);
}

final catalogosAdminProvider = StateNotifierProvider<CatalogosAdminNotifier, CatalogosAdminState>(
  (ref) => CatalogosAdminNotifier(ref.watch(catalogosAdminRepositoryProvider)),
);