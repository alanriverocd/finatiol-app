import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/producto_repository.dart';
import '../domain/producto_model.dart';

// --- Providers de infraestructura ---

final productoRepositoryProvider = Provider<ProductoRepository>(
  (ref) => ProductoRepository(ref.watch(dioProvider)),
);

// --- Lista de productos ---

class ProductosState {
  const ProductosState({
    this.productos = const [],
    this.totalActivos = 0,
    this.isLoading = false,
    this.error,
  });

  final List<Producto> productos;
  final int totalActivos;
  final bool isLoading;
  final String? error;

  ProductosState copyWith({
    List<Producto>? productos,
    int? totalActivos,
    bool? isLoading,
    String? error,
  }) =>
      ProductosState(
        productos: productos ?? this.productos,
        totalActivos: totalActivos ?? this.totalActivos,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ProductosNotifier extends StateNotifier<ProductosState> {
  ProductosNotifier(this._repo) : super(const ProductosState());

  final ProductoRepository _repo;

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Tu sesión expiró o no tienes permisos. Vuelve a iniciar sesión.';
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['mensaje'] ?? data['code'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productos = await _repo.listar();
      int totalActivos;
      try {
        totalActivos = await _repo.contarActivos();
      } catch (_) {
        totalActivos = productos.where((producto) => producto.activo).length;
      }
      state = state.copyWith(
        isLoading: false,
        productos: productos,
        totalActivos: totalActivos,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e, fallback: 'Error al cargar productos'),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error inesperado');
    }
  }

  Future<bool> crear(ProductoRequest req,
      {List<XFile> imagenes = const []}) async {
    try {
      final nuevo = await _repo.crear(req, imagenes: imagenes);
      state = state.copyWith(productos: [...state.productos, nuevo]);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          error: _extractErrorMessage(e, fallback: 'Error al crear producto'));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error inesperado al crear');
      return false;
    }
  }

  Future<bool> actualizar(int id, ProductoRequest req) async {
    try {
      final actualizado = await _repo.actualizar(id, req);
      state = state.copyWith(
        productos: state.productos
            .map((p) => p.id == id ? actualizado : p)
            .toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          error: _extractErrorMessage(e, fallback: 'Error al actualizar'));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Error inesperado al actualizar');
      return false;
    }
  }

  Future<bool> eliminar(int id) async {
    try {
      await _repo.eliminar(id);
      state = state.copyWith(
        productos: state.productos.where((p) => p.id != id).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: 'Error al eliminar producto');
      return false;
    }
  }

  void actualizarImagenesEnEstado(int productoId, List<ProductoImagen> imagenes) {
    state = state.copyWith(
      productos: state.productos
          .map((p) => p.id == productoId ? p.copyWith(imagenes: imagenes) : p)
          .toList(),
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

final productosProvider =
    StateNotifierProvider<ProductosNotifier, ProductosState>(
  (ref) => ProductosNotifier(ref.watch(productoRepositoryProvider)),
);
