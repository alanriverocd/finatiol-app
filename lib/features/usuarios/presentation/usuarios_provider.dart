import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/usuario_repository.dart';
import '../domain/usuario_model.dart';

// ── Repository provider ────────────────────────────────────────────────────

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository(ref.watch(dioProvider));
});

// ── State ──────────────────────────────────────────────────────────────────

class UsuariosState {
  final List<Usuario> usuarios;
  final int totalUsuarios;
  final bool isLoading;
  final String? error;

  const UsuariosState({
    this.usuarios = const [],
    this.totalUsuarios = 0,
    this.isLoading = false,
    this.error,
  });

  UsuariosState copyWith({
    List<Usuario>? usuarios,
    int? totalUsuarios,
    bool? isLoading,
    String? error,
  }) =>
      UsuariosState(
        usuarios: usuarios ?? this.usuarios,
        totalUsuarios: totalUsuarios ?? this.totalUsuarios,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class UsuariosNotifier extends StateNotifier<UsuariosState> {
  final UsuarioRepository _repo;

  UsuariosNotifier(this._repo) : super(const UsuariosState());

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true);
    try {
      final usuarios = await _repo.listar();
      final totalUsuarios = await _repo.contar();
      state = state.copyWith(
        usuarios: usuarios,
        totalUsuarios: totalUsuarios,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> crear(UsuarioRequest request) async {
    try {
      final nuevo = await _repo.crear(request);
      state = state.copyWith(usuarios: [nuevo, ...state.usuarios]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> actualizar(int id, UsuarioRequest request) async {
    try {
      final actualizado = await _repo.actualizar(id, request);
      state = state.copyWith(
        usuarios: state.usuarios
            .map((u) => u.id == id ? actualizado : u)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    try {
      await _repo.eliminar(id);
      state = state.copyWith(
        usuarios: state.usuarios.where((u) => u.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> asignarRol(int id, String rolNombre) async {
    try {
      await _repo.asignarRol(id, rolNombre);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) {
          if (u.id != id) return u;
          if (u.roles.contains(rolNombre)) return u;
          return u.copyWith(roles: [...u.roles, rolNombre]);
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removerRol(int id, String rolNombre) async {
    try {
      await _repo.removerRol(id, rolNombre);
      state = state.copyWith(
        usuarios: state.usuarios.map((u) {
          if (u.id != id) return u;
          return u.copyWith(
              roles: u.roles.where((r) => r != rolNombre).toList());
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Provider ───────────────────────────────────────────────────────────────

final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, UsuariosState>((ref) {
  return UsuariosNotifier(ref.watch(usuarioRepositoryProvider));
});
