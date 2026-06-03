import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/venta_repository.dart';
import '../domain/venta_model.dart';
import 'ventas_provider.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final cobrosProvider =
    FutureProvider.autoDispose<List<SaldoVenta>>((ref) async {
  final repo = ref.watch(ventaRepositoryProvider);
  return repo.ventasConPendiente();
});

// ---------------------------------------------------------------------------
// Pantalla de cobros
// ---------------------------------------------------------------------------
class CobrosScreen extends ConsumerWidget {
  const CobrosScreen({super.key});

  static final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cobrosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cobrosProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(cobrosProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      SizedBox(height: 8),
                      Text('No hay ventas con saldo pendiente'),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  final s = list[i];
                  return _SaldoTile(saldo: s, fmt: _fmt);
                },
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile
// ---------------------------------------------------------------------------
class _SaldoTile extends StatelessWidget {
  const _SaldoTile({required this.saldo, required this.fmt});
  final SaldoVenta saldo;
  final NumberFormat fmt;

  Color _colorEstado(String estado) => switch (estado) {
        'COMPLETO' => Colors.green,
        'PARCIAL' => Colors.orange,
        _ => Colors.red,
      };

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _colorEstado(saldo.estadoPago),
            child: const Icon(Icons.attach_money, color: Colors.white),
          ),
          title: Text('Venta #${saldo.ventaId} — ${saldo.usuario}'),
          subtitle: Text(
            'Total: ${fmt.format(saldo.totalVenta)} · Pagado: ${fmt.format(saldo.totalPagado)}\nPendiente: ${fmt.format(saldo.saldoPendiente)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          isThreeLine: true,
          onTap: () => context.push('/ventas/${saldo.ventaId}/pagos'),
        ),
      );
}
