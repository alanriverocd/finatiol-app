import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/venta_repository.dart';
import '../domain/venta_model.dart';
import 'ventas_provider.dart';

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------
class PagosState {
  const PagosState({
    this.saldo,
    this.pagos = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final SaldoVenta? saldo;
  final List<PagoVenta> pagos;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  PagosState copyWith({
    SaldoVenta? saldo,
    List<PagoVenta>? pagos,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      PagosState(
        saldo: saldo ?? this.saldo,
        pagos: pagos ?? this.pagos,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class PagosNotifier extends StateNotifier<PagosState> {
  PagosNotifier(this._repo, this._ventaId) : super(const PagosState());

  final VentaRepository _repo;
  final int _ventaId;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.obtenerSaldo(_ventaId),
        _repo.listarPagos(_ventaId),
      ]);
      state = state.copyWith(
        saldo: results[0] as SaldoVenta,
        pagos: results[1] as List<PagoVenta>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> registrar(PagoVentaRequest request) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.registrarPago(_ventaId, request);
      await cargar();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider family (por ventaId)
// ---------------------------------------------------------------------------
final pagosProvider =
    StateNotifierProvider.family<PagosNotifier, PagosState, int>(
  (ref, ventaId) => PagosNotifier(
    ref.watch(ventaRepositoryProvider),
    ventaId,
  ),
);
