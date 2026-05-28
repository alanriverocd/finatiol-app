import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/movimiento_model.dart';
import 'finanzas_provider.dart';
import 'movimiento_form_screen.dart';

class FinanzasScreen extends ConsumerStatefulWidget {
  const FinanzasScreen({super.key});

  @override
  ConsumerState<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends ConsumerState<FinanzasScreen> {
  TipoMovimiento? _filtroTipo;
  FinanzasNotifier get _finanzasNotifier => ref.read(finanzasProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(finanzasProvider.notifier).cargar());
  }

  List<Movimiento> _filtrar(List<Movimiento> lista) {
    if (_filtroTipo == null) return lista;
    return lista.where((m) => m.tipo == _filtroTipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finanzasProvider);
    final filtrados = _filtrar(state.movimientos);

    ref.listen(finanzasProvider, (_, next) {
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
                _finanzasNotifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Finanzas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(finanzasProvider.notifier).cargar(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(finanzasProvider.notifier).cargar(),
              child: CustomScrollView(
                slivers: [
                  // Tarjetas resumen
                  SliverToBoxAdapter(
                    child: _ResumenCards(state: state),
                  ),

                  // Filtro
                  SliverToBoxAdapter(
                    child: _FiltroChips(
                      seleccionado: _filtroTipo,
                      onSeleccion: (tipo) =>
                          setState(() => _filtroTipo = tipo),
                    ),
                  ),

                  // Lista movimientos
                  filtrados.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyView(
                            hasFilter: _filtroTipo != null,
                            onAdd: () => _abrirFormulario(context),
                          ),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          sliver: SliverList.separated(
                            itemCount: filtrados.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) =>
                                _MovimientoCard(movimiento: filtrados[i]),
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
    );
  }

  void _abrirFormulario(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MovimientoFormScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas de resumen
// ---------------------------------------------------------------------------
class _ResumenCards extends StatelessWidget {
  const _ResumenCards({required this.state});

  final FinanzasState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Ingresos',
                  value: FormatUtils.currency(state.totalIngresos),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green.shade600,
                  bgColor: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Egresos',
                  value: FormatUtils.currency(state.totalEgresos),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.red.shade600,
                  bgColor: Colors.red.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Balance',
            value: FormatUtils.currency(state.balance),
            icon: Icons.account_balance_outlined,
            color: state.balance >= 0
                ? const Color(0xFF1565C0)
                : Colors.red.shade600,
            bgColor: state.balance >= 0
                ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                : Colors.red.shade50,
            isWide: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isWide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                children: [
                  CircleAvatar(
                      backgroundColor: bgColor,
                      child: Icon(icon, color: color, size: 22)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                      Text(value,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                      backgroundColor: bgColor,
                      child: Icon(icon, color: color, size: 20)),
                  const SizedBox(height: 10),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chips de filtro
// ---------------------------------------------------------------------------
class _FiltroChips extends StatelessWidget {
  const _FiltroChips({required this.seleccionado, required this.onSeleccion});

  final TipoMovimiento? seleccionado;
  final ValueChanged<TipoMovimiento?> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: seleccionado == null,
            onSelected: (_) => onSeleccion(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Ingresos'),
            selected: seleccionado == TipoMovimiento.ingreso,
            selectedColor: Colors.green.shade100,
            onSelected: (_) => onSeleccion(
              seleccionado == TipoMovimiento.ingreso
                  ? null
                  : TipoMovimiento.ingreso,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Egresos'),
            selected: seleccionado == TipoMovimiento.egreso,
            selectedColor: Colors.red.shade100,
            onSelected: (_) => onSeleccion(
              seleccionado == TipoMovimiento.egreso
                  ? null
                  : TipoMovimiento.egreso,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de movimiento
// ---------------------------------------------------------------------------
class _MovimientoCard extends StatelessWidget {
  const _MovimientoCard({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context) {
    final isIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor:
              isIngreso ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIngreso
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIngreso ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
        ),
        title: Text(
          movimiento.concepto,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FormatUtils.dateTime(movimiento.fecha),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (movimiento.referencia != null)
              Text(
                'Ref: ${movimiento.referencia}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
        trailing: Text(
          '${isIngreso ? '+' : '-'} ${FormatUtils.currency(movimiento.monto)}',
          style: TextStyle(
            color: isIngreso ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
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
            hasFilter ? Icons.filter_alt_off : Icons.account_balance_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Sin movimientos con ese filtro'
                : 'No hay movimientos registrados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar movimiento'),
            ),
          ],
        ],
      ),
    );
  }
}
