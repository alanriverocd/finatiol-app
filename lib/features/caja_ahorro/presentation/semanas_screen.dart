import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/ahorro_model.dart';
import 'ahorro_provider.dart';

class SemanasScreen extends ConsumerStatefulWidget {
  final int cuentaId;
  const SemanasScreen({super.key, required this.cuentaId});

  @override
  ConsumerState<SemanasScreen> createState() => _SemanasScreenState();
}

class _SemanasScreenState extends ConsumerState<SemanasScreen> {
  int _anio = DateTime.now().year;
  AhorroNotifier get _ahorroNotifier => ref.read(ahorroProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => _ahorroNotifier.cargarSemanas(widget.cuentaId, _anio));
  }

  void _cambiarAnio(int delta) {
    setState(() => _anio += delta);
    _ahorroNotifier.cargarSemanas(widget.cuentaId, _anio);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ahorroProvider);
    final semanas = state.semanas;
    final pagadas = semanas.where((s) => s.pagado).length;
    final totalAcumulado = semanas.fold<double>(
        0, (sum, s) => sum + (s.pagado ? (s.monto ?? 0) : 0));

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
        title: Text('Semanas — Cuenta #${widget.cuentaId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(ahorroProvider.notifier)
                .cargarSemanas(widget.cuentaId, _anio),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Selector de año ──────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _cambiarAnio(-1),
                ),
                Text(
                  '$_anio',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _cambiarAnio(1),
                ),
              ],
            ),
          ),
          // ── Resumen ──────────────────────────────────────────────────────
          if (semanas.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResumenItem(
                      label: 'Semanas pagadas',
                      value: '$pagadas / 52'),
                  _ResumenItem(
                      label: 'Total acumulado',
                      value: FormatUtils.currency(totalAcumulado)),
                ],
              ),
            ),
          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: semanas.length,
                    itemBuilder: (context, i) => _SemanaCard(
                      semana: semanas[i],
                      onRegistrarPago: () =>
                          _mostrarDialogoPago(context, semanas[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPago(BuildContext context, SemanaAhorro semana) {
    if (semana.pagado) return;

    final montoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pago — Semana ${semana.numeroSemana}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${semana.fechaInicio}  →  ${semana.fechaFin}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: montoCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(ahorroProvider.notifier)
                  .registrarPago(
                    cuentaId: widget.cuentaId,
                    anio: _anio,
                    semana: semana.numeroSemana,
                    monto: double.parse(montoCtrl.text.trim()),
                  );
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Semana ${semana.numeroSemana} registrada ✓'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resumen item
// ---------------------------------------------------------------------------
class _ResumenItem extends StatelessWidget {
  const _ResumenItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de semana
// ---------------------------------------------------------------------------
class _SemanaCard extends StatelessWidget {
  const _SemanaCard(
      {required this.semana, required this.onRegistrarPago});

  final SemanaAhorro semana;
  final VoidCallback onRegistrarPago;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pagado = semana.pagado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: pagado
          ? Colors.green.shade50
          : theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor:
              pagado ? Colors.green.shade100 : Colors.grey.shade200,
          child: Text(
            '${semana.numeroSemana}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: pagado
                  ? Colors.green.shade800
                  : Colors.grey.shade700,
            ),
          ),
        ),
        title: Text(
          '${semana.fechaInicio}  →  ${semana.fechaFin}',
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: pagado
            ? Text(
                'Pagado: ${FormatUtils.currency(semana.monto ?? 0)}',
                style: TextStyle(
                    fontSize: 12, color: Colors.green.shade700),
              )
            : const Text('Pendiente',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: pagado
            ? Icon(Icons.check_circle,
                color: Colors.green.shade600, size: 22)
            : IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: theme.colorScheme.primary, size: 22),
                tooltip: 'Registrar pago',
                onPressed: onRegistrarPago,
              ),
      ),
    );
  }
}
