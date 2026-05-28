import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/solicitud_producto_repository.dart';
import '../domain/solicitud_producto_model.dart';

final solicitudProductoRepositoryProvider =
    Provider<SolicitudProductoRepository>((ref) {
  return SolicitudProductoRepository(ref.watch(dioProvider));
});

final misSolicitudesProvider = FutureProvider<List<SolicitudProducto>>((ref) {
  return ref.watch(solicitudProductoRepositoryProvider).listarMias();
});

final adminSolicitudesProvider = FutureProvider<List<SolicitudProducto>>((ref) {
  return ref.watch(solicitudProductoRepositoryProvider).listarTodas();
});
