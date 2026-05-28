import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/ahorro_repository.dart';
import '../domain/ahorro_model.dart';

// ---------------------------------------------------------------------------
// Repositorio
// ---------------------------------------------------------------------------
final ahorroRepositoryProvider = Provider<AhorroRepository>((ref) {
  return AhorroRepository(ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------
class AhorroState {
  const AhorroState({
    this.cuentas = const [],
    this.cuentasAdmin = const [],
    this.movimientos = const [],
    this.semanas = const [],
    this.clientes = const [],
    this.dashboard,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  final List<CuentaAhorro> cuentas;
  final List<CuentaAhorro> cuentasAdmin;
  final List<MovimientoAhorro> movimientos;
  final List<SemanaAhorro> semanas;
  final List<ClienteAhorro> clientes;
  final AhorroDashboard? dashboard;
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  AhorroState copyWith({
    List<CuentaAhorro>? cuentas,
    List<CuentaAhorro>? cuentasAdmin,
    List<MovimientoAhorro>? movimientos,
    List<SemanaAhorro>? semanas,
    List<ClienteAhorro>? clientes,
    AhorroDashboard? dashboard,
    bool? isAdmin,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AhorroState(
        cuentas: cuentas ?? this.cuentas,
        cuentasAdmin: cuentasAdmin ?? this.cuentasAdmin,
        movimientos: movimientos ?? this.movimientos,
        semanas: semanas ?? this.semanas,
        clientes: clientes ?? this.clientes,
        dashboard: dashboard ?? this.dashboard,
        isAdmin: isAdmin ?? this.isAdmin,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class AhorroNotifier extends StateNotifier<AhorroState> {
  AhorroNotifier(this._repo) : super(const AhorroState());

  final AhorroRepository _repo;

  Future<void> _refreshAfterMutation({
    int? cuentaId,
    int? anio,
    bool refreshSemanas = false,
  }) async {
    try {
      final dashboard = await _repo.getMiDashboard();
      state = state.copyWith(dashboard: dashboard, cuentas: dashboard.cuentas);
    } catch (_) {
      try {
        final cuentas = await _repo.getMisCuentas();
        state = state.copyWith(cuentas: cuentas);
      } catch (_) {}
    }

    if (cuentaId != null) {
      try {
        final movimientos = await _repo.getMovimientos(cuentaId);
        state = state.copyWith(movimientos: movimientos);
      } catch (_) {}
    }

    if (refreshSemanas && cuentaId != null && anio != null) {
      try {
        final semanas = await _repo.getSemanas(cuentaId, anio);
        state = state.copyWith(semanas: semanas);
      } catch (_) {}
    }
  }

  Future<void> cargarInicio() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      AhorroDashboard? dashboard;
      List<CuentaAhorro> cuentas = const [];
      try {
        dashboard = await _repo.getMiDashboard();
        cuentas = dashboard.cuentas;
      } catch (_) {
        cuentas = await _repo.getMisCuentas();
      }

      bool isAdmin = false;
      List<ClienteAhorro> clientes = const [];
      List<CuentaAhorro> cuentasAdmin = const [];
      try {
        clientes = await _repo.getClientesAdmin();
        cuentasAdmin = await _repo.getCuentasAdmin();
        isAdmin = true;
      } on DioException catch (e) {
        if ((e.response?.statusCode ?? 0) != 403) {
          rethrow;
        }
      }

      state = state.copyWith(
        dashboard: dashboard,
        cuentas: cuentas,
        clientes: clientes,
        cuentasAdmin: cuentasAdmin,
        isAdmin: isAdmin,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'Error al cargar la información de ahorro'),
      );
    }
  }

  Future<void> cargarCuentas() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cuentas = await _repo.getMisCuentas();
      state = state.copyWith(cuentas: cuentas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(
          e,
          fallback: 'No se pudieron cargar las cuentas de ahorro. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<bool> crearCliente(ClienteAhorroRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.crearClienteAdmin(request);
      await cargarInicio();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(
          e,
          fallback: 'No se pudo crear el cliente. Verifica si el usuario ya existe.',
        ),
      );
      return false;
    }
  }

  Future<bool> actualizarCliente(int id, ClienteAhorroRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.actualizarClienteAdmin(id, request);
      await cargarInicio();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'No se pudo actualizar el cliente'),
      );
      return false;
    }
  }

  Future<bool> abrirCuentaAdmin({required int clienteId, double? montoInicial}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.abrirCuentaAdmin(
        clienteId: clienteId,
        montoInicial: montoInicial,
        referencia: 'Cuenta creada desde panel administrativo',
      );
      await cargarInicio();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'No se pudo abrir la cuenta para el cliente'),
      );
      return false;
    }
  }

  Future<void> cargarMovimientos(int cuentaId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final movimientos = await _repo.getMovimientos(cuentaId);
      state = state.copyWith(movimientos: movimientos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(
          e,
          fallback: 'No se pudieron cargar los movimientos de la cuenta. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> cargarSemanas(int cuentaId, int anio) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final semanas = await _repo.getSemanas(cuentaId, anio);
      state = state.copyWith(semanas: semanas, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(
          e,
          fallback: 'No se pudieron cargar las semanas de pago. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<bool> abrirCuenta() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.abrirCuenta();
      await cargarInicio();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'Error al abrir cuenta'),
      );
      return false;
    }
  }

  Future<bool> depositar({
    required int cuentaId,
    required double monto,
    String? referencia,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.depositar(
          cuentaId: cuentaId, monto: monto, referencia: referencia);
      await _refreshAfterMutation(cuentaId: cuentaId);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'Error al depositar'),
      );
      return false;
    }
  }

  Future<bool> retirar({
    required int cuentaId,
    required double monto,
    String? referencia,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.retirar(
          cuentaId: cuentaId, monto: monto, referencia: referencia);
      await _refreshAfterMutation(cuentaId: cuentaId);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'Error al retirar'),
      );
      return false;
    }
  }

  Future<bool> registrarPago({
    required int cuentaId,
    required int anio,
    required int semana,
    required double monto,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.registrarPago(
          cuentaId: cuentaId, anio: anio, semana: semana, monto: monto);
      await _refreshAfterMutation(
        cuentaId: cuentaId,
        anio: anio,
        refreshSemanas: true,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e, fallback: 'Error al registrar pago'),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _parseError(Object error, {required String fallback}) {
    if (error is DioException) {
      if (error.error is FormatException) {
        return fallback;
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.';
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['mensaje'] ?? data['error'];
        if (message is String && message.isNotEmpty) return message;
      }

      if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
        return 'Tu sesión no tiene permisos o expiró. Vuelve a iniciar sesión.';
      }

      return fallback;
    }

    if (error is FormatException) {
      return fallback;
    }

    return fallback;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final ahorroProvider =
    StateNotifierProvider<AhorroNotifier, AhorroState>((ref) {
  return AhorroNotifier(ref.watch(ahorroRepositoryProvider));
});
