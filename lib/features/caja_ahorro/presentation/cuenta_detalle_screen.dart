import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/ahorro_model.dart';
import 'ahorro_provider.dart';

class CuentaDetalleScreen extends ConsumerStatefulWidget {
  final int cuentaId;
  const CuentaDetalleScreen({super.key, required this.cuentaId});

  @override
  ConsumerState<CuentaDetalleScreen> createState() =>
      _CuentaDetalleScreenState();
}

class _CuentaDetalleScreenState extends ConsumerState<CuentaDetalleScreen> {
  AhorroNotifier get _ahorroNotifier => ref.read(ahorroProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _ahorroNotifier.cargarMovimientos(widget.cuentaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ahorroProvider);
    final cuenta = state.cuentas
        .where((c) => c.id == widget.cuentaId)
        .firstOrNull;

    ref.listen(ahorroProvider, (_, next) {
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
                _ahorroNotifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: Text('Cuenta #${widget.cuentaId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref
                .read(ahorroProvider.notifier)
                .cargarMovimientos(widget.cuentaId),
          ),
        ],
      ),
      body: Column(
        children: [
          if (cuenta != null) _CuentaInfoCard(cuenta: cuenta),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context
                        .push('/ahorros/deposito/${widget.cuentaId}'),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: const Text('Depositar'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/ahorros/retiro/${widget.cuentaId}'),
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Retirar'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .push('/ahorros/semanas/${widget.cuentaId}'),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Semanas'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.movimientos.isEmpty
                    ? const Center(
                        child: Text('Sin movimientos registrados',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(ahorroProvider.notifier)
                            .cargarMovimientos(widget.cuentaId),
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: state.movimientos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) =>
                              _MovimientoTile(movimiento: state.movimientos[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card
// ---------------------------------------------------------------------------
class _CuentaInfoCard extends StatelessWidget {
  const _CuentaInfoCard({required this.cuenta});
  final CuentaAhorro cuenta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo disponible',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            FormatUtils.currency(cuenta.saldo),
            style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usuario: ${cuenta.username}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Apertura: ${cuenta.fechaApertura}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Movimiento tile
// ---------------------------------------------------------------------------
class _MovimientoTile extends StatelessWidget {
  const _MovimientoTile({required this.movimiento});
  final MovimientoAhorro movimiento;

  @override
  Widget build(BuildContext context) {
    final isDeposito = movimiento.tipo == 'DEPOSITO' || movimiento.tipo == 'INTERES';
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isDeposito ? Colors.green : Colors.orange).withValues(alpha: 0.15),
          child: Icon(
            isDeposito ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposito ? Colors.green.shade700 : Colors.orange.shade700,
            size: 20,
          ),
        ),
        title: Text(movimiento.tipo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          movimiento.referencia ?? movimiento.fecha,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${isDeposito ? '+' : '-'}${FormatUtils.currency(movimiento.monto)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isDeposito ? Colors.green.shade700 : Colors.orange.shade700),
        ),
      ),
    );
  }
}
