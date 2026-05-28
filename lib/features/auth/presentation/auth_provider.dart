import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

// --- Providers de infraestructura ---

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => TokenStorage(const FlutterSecureStorage()),
);

final dioProvider = Provider<Dio>(
  (ref) => createDio(ref.watch(tokenStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);

// --- Estado del login ---

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.error,
    this.auth,
  });

  final bool isLoading;
  final String? error;
  final AuthResponse? auth;

  bool get isSuccess => auth != null;

  LoginState copyWith({
    bool? isLoading,
    String? error,
    AuthResponse? auth,
  }) =>
      LoginState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        auth: auth ?? this.auth,
      );
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final auth = await _repo.login(
        LoginRequest(username: username, password: password),
      );
      state = state.copyWith(isLoading: false, auth: auth);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final String msg;
      if (status == 401 || status == 404) {
        // El backend devuelve { "mensaje": "...", ... } en errores
        msg = (e.response?.data as Map<String, dynamic>?)?['mensaje'] as String?
            ?? 'Credenciales incorrectas';
      } else {
        msg = 'Error de conexión con el servidor';
      }
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const LoginState();
  }
}

final loginProvider =
    StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(ref.watch(authRepositoryProvider)),
);

// Provider para verificar si hay sesión activa
final isAuthenticatedProvider = FutureProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isAuthenticated(),
);

final storedAuthProvider = FutureProvider<AuthResponse?>(
  (ref) => ref.watch(authRepositoryProvider).getStoredAuth(),
);
