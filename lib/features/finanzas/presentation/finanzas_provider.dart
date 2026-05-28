import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/finanzas_repository.dart';
import '../domain/movimiento_model.dart';

// ---------------------------------------------------------------------------
// Repositorio
// ---------------------------------------------------------------------------
final finanzasRepositoryProvider = Provider<FinanzasRepository>((ref) {
  return FinanzasRepository(ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------
class FinanzasState {
  const FinanzasState({
    this.movimientos = const [],
    this.isLoading = false,
    this.error,
    this.totalIngresos = 0,
    this.totalEgresos = 0,
    this.balance = 0,
  });

  final List<Movimiento> movimientos;
  final bool isLoading;
  final String? error;
  final double totalIngresos;
  final double totalEgresos;
  final double balance;

  FinanzasState copyWith({
    List<Movimiento>? movimientos,
    bool? isLoading,
    String? error,
    double? totalIngresos,
    double? totalEgresos,
    double? balance,
    bool clearError = false,
  }) =>
      FinanzasState(
        movimientos: movimientos ?? this.movimientos,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        totalIngresos: totalIngresos ?? this.totalIngresos,
        totalEgresos: totalEgresos ?? this.totalEgresos,
        balance: balance ?? this.balance,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class FinanzasNotifier extends StateNotifier<FinanzasState> {
  FinanzasNotifier(this._repo) : super(const FinanzasState());

  final FinanzasRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.listar(),
        _repo.totalIngresos(),
        _repo.totalEgresos(),
        _repo.resumenBalance(),
      ]);
      state = state.copyWith(
        movimientos: results[0] as List<Movimiento>,
        totalIngresos: results[1] as double,
        totalEgresos: results[2] as double,
        balance: results[3] as double,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar finanzas: $e',
      );
    }
  }

  Future<bool> registrar(MovimientoRequest request) async {
    try {
      final movimiento = await _repo.registrar(request);
      final isIngreso = request.tipo == TipoMovimiento.ingreso;
      state = state.copyWith(
        movimientos: [movimiento, ...state.movimientos],
        totalIngresos:
            isIngreso ? state.totalIngresos + request.monto : state.totalIngresos,
        totalEgresos:
            isIngreso ? state.totalEgresos : state.totalEgresos + request.monto,
        balance: isIngreso
            ? state.balance + request.monto
            : state.balance - request.monto,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(error: 'Error al registrar movimiento: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Provider principal
// ---------------------------------------------------------------------------
final finanzasProvider =
    StateNotifierProvider<FinanzasNotifier, FinanzasState>((ref) {
  return FinanzasNotifier(ref.watch(finanzasRepositoryProvider));
});
