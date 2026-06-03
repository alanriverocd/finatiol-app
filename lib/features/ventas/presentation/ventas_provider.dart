import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/venta_repository.dart';
import '../domain/venta_model.dart';

// ---------------------------------------------------------------------------
// Repositorio
// ---------------------------------------------------------------------------
final ventaRepositoryProvider = Provider<VentaRepository>((ref) {
  return VentaRepository(ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------
class VentasState {
  const VentasState({
    this.ventas = const [],
    this.totalVentas = 0,
    this.isLoading = false,
    this.error,
  });

  final List<Venta> ventas;
  final double totalVentas;
  final bool isLoading;
  final String? error;

  VentasState copyWith({
    List<Venta>? ventas,
    double? totalVentas,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      VentasState(
        ventas: ventas ?? this.ventas,
        totalVentas: totalVentas ?? this.totalVentas,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class VentasNotifier extends StateNotifier<VentasState> {
  VentasNotifier(this._repo) : super(const VentasState());

  final VentaRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ventas = await _repo.listar();
      final totalVentas = await _repo.totalVentas();
      state = state.copyWith(
        ventas: ventas,
        totalVentas: totalVentas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar ventas: $e',
      );
    }
  }

  Future<void> buscarRemoto(String query) async {
    final value = query.trim();
    if (value.isEmpty) {
      await cargar();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final parsedId = int.tryParse(value);
      if (parsedId != null) {
        final venta = await _repo.obtener(parsedId);
        state = state.copyWith(
          ventas: [venta],
          totalVentas: venta.total,
          isLoading: false,
        );
        return;
      }

      final ventas = await _repo.listarPorUsuario(value);
      final totalFiltrado =
          ventas.fold<double>(0, (acc, venta) => acc + venta.total);
      state = state.copyWith(
        ventas: ventas,
        totalVentas: totalFiltrado,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar ventas: $e',
      );
    }
  }

  Future<bool> crear(VentaRequest request) async {
    try {
      final venta = await _repo.crear(request);
      state = state.copyWith(ventas: [venta, ...state.ventas]);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Error al crear venta: $e');
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    try {
      await _repo.eliminar(id);
      state = state.copyWith(
        ventas: state.ventas.where((v) => v.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Error al eliminar venta: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Provider principal
// ---------------------------------------------------------------------------
final ventasProvider =
    StateNotifierProvider<VentasNotifier, VentasState>((ref) {
  return VentasNotifier(ref.watch(ventaRepositoryProvider));
});
