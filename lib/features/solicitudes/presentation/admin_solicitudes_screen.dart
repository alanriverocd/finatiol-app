import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/solicitud_producto_model.dart';
import 'solicitudes_provider.dart';

class AdminSolicitudesScreen extends ConsumerStatefulWidget {
  const AdminSolicitudesScreen({super.key});

  @override
  ConsumerState<AdminSolicitudesScreen> createState() =>
      _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends ConsumerState<AdminSolicitudesScreen> {
  String _selected = 'TODAS';

  List<SolicitudProducto> _filter(List<SolicitudProducto> data) {
    if (_selected == 'TODAS') return data;
    return data.where((s) => s.estado.toUpperCase() == _selected).toList();
  }

  Future<void> _updateStatus(
    SolicitudProducto solicitud,
    String estado,
  ) async {
    final comentarioCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Marcar como $estado'),
            content: TextField(
              controller: comentarioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      comentarioCtrl.dispose();
      return;
    }

    try {
      await ref.read(solicitudProductoRepositoryProvider).actualizarEstado(
            id: solicitud.id,
            estado: estado,
            comentario: comentarioCtrl.text.trim().isEmpty
                ? null
                : comentarioCtrl.text.trim(),
          );

      if (!mounted) return;
      ref.invalidate(adminSolicitudesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${solicitud.id} actualizado a $estado')),
      );
    } on DioException catch (e) {
      String msg = 'No se pudo actualizar el pedido';
      final raw = e.response?.data;
      if (raw is Map<String, dynamic>) {
        final candidate = raw['message'] ?? raw['mensaje'] ?? raw['error'];
        if (candidate != null && candidate.toString().trim().isNotEmpty) {
          msg = candidate.toString();
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      comentarioCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesAsync = ref.watch(adminSolicitudesProvider);

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Administrar pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(adminSolicitudesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminSolicitudesProvider.future),
        child: solicitudesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No se pudieron cargar los pedidos',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          data: (data) {
            if (data.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                children: [
                  Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay pedidos pendientes de gestion.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final filtered = _filter(data);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const ['TODAS', 'PENDIENTE', 'APROBADA', 'RECHAZADA']
                      .map(
                        (status) => ChoiceChip(
                          label: Text(status),
                          selected: _selected == status,
                          onSelected: (_) => setState(() => _selected = status),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sin resultados para ese filtro.'),
                    ),
                  )
                else
                  ...filtered.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.producto,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text('#${s.id}'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Usuario: ${s.username}'),
                              const SizedBox(height: 4),
                              Text('Fecha: ${FormatUtils.dateTime(s.fechaSolicitud)}'),
                              const SizedBox(height: 4),
                              Text('Estado: ${s.estado.toUpperCase()}'),
                              const SizedBox(height: 10),
                              if (s.comentario.trim().isNotEmpty)
                                Text('Comentario: ${s.comentario}'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton.tonal(
                                    onPressed: s.estado.toUpperCase() == 'APROBADA'
                                        ? null
                                        : () => _updateStatus(s, 'APROBADA'),
                                    child: const Text('Aprobar'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: s.estado.toUpperCase() == 'RECHAZADA'
                                        ? null
                                        : () => _updateStatus(s, 'RECHAZADA'),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: s.estado.toUpperCase() == 'PENDIENTE'
                                        ? null
                                        : () => _updateStatus(s, 'PENDIENTE'),
                                    child: const Text('Pendiente'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
