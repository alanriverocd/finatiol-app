import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/venta_model.dart';
import 'ventas_provider.dart';
import 'venta_form_screen.dart';

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  VentasNotifier get _ventasNotifier => ref.read(ventasProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ventasProvider.notifier).cargar());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Venta> _filtrar(List<Venta> lista) {
    if (_query.isEmpty) return lista;
    final q = _query.toLowerCase();
    return lista
        .where((v) =>
            v.usuario.toLowerCase().contains(q) ||
            v.id.toString().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ventasProvider);
    final filtradas = _filtrar(state.ventas);

    ref.listen(ventasProvider, (_, next) {
      if (next.error != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                messenger.hideCurrentSnackBar();
                if (!mounted) return;
                _ventasNotifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(ventasProvider.notifier).cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: const Color(0xFFEAF7EE),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.point_of_sale_outlined, color: Colors.green.shade700),
                ),
                title: const Text('Ventas registradas'),
                subtitle: Text(
                  '${state.ventas.length} ventas · Total ${FormatUtils.currency(state.totalVentas)}',
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por usuario o ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Buscar en servidor',
                      icon: const Icon(Icons.travel_explore_outlined),
                      onPressed: () => _ventasNotifier.buscarRemoto(_query),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                          _ventasNotifier.cargar();
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) => _ventasNotifier.buscarRemoto(v),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtradas.isEmpty
                    ? _EmptyView(
                        hasFilter: _query.isNotEmpty,
                        onAdd: () => _abrirFormulario(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(ventasProvider.notifier).cargar(),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtradas.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _VentaCard(
                            venta: filtradas[i],
                            onEliminar: () =>
                                _confirmarEliminar(context, filtradas[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva venta'),
      ),
    );
  }

  void _abrirFormulario(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VentaFormScreen()),
    );
  }

  void _confirmarEliminar(BuildContext context, Venta venta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text(
            '¿Deseas eliminar la venta #${venta.id}? '
            'Esta acción restaurará el stock de los productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(ventasProvider.notifier)
                  .eliminar(venta.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de venta
// ---------------------------------------------------------------------------
class _VentaCard extends StatelessWidget {
  const _VentaCard({required this.venta, required this.onEliminar});

  final Venta venta;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.receipt_outlined,
              color: theme.colorScheme.primary, size: 20),
        ),
        title: Row(
          children: [
            Text(
              'Venta #${venta.id}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                FormatUtils.currency(venta.total),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${venta.usuario}  ·  ${FormatUtils.dateTime(venta.fecha)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.payments_outlined,
                  color: Colors.teal, size: 20),
              tooltip: 'Cobros',
              onPressed: () =>
                  context.push('/ventas/${venta.id}/pagos'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              tooltip: 'Eliminar',
              onPressed: onEliminar,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: venta.detalles.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin detalles',
                      style: TextStyle(color: Colors.grey)),
                ),
              ]
            : [
                const Divider(height: 1),
                ...venta.detalles.map((d) => _DetalleRow(detalle: d)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Total: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        FormatUtils.currency(venta.total),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

class _DetalleRow extends StatelessWidget {
  const _DetalleRow({required this.detalle});

  final DetalleVenta detalle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              detalle.productoNombre,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${detalle.cantidad} × ${FormatUtils.currency(detalle.precio)}',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          Text(
            FormatUtils.currency(detalle.subtotal),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter, required this.onAdd});

  final bool hasFilter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.receipt_long_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Sin resultados para esa búsqueda'
                : 'No hay ventas registradas',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nueva venta'),
            ),
          ],
        ],
      ),
    );
  }
}
