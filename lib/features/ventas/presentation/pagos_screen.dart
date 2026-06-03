import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/venta_model.dart';
import 'pagos_provider.dart';

class PagosVentaScreen extends ConsumerStatefulWidget {
  const PagosVentaScreen({super.key, required this.ventaId});

  final int ventaId;

  @override
  ConsumerState<PagosVentaScreen> createState() => _PagosVentaScreenState();
}

class _PagosVentaScreenState extends ConsumerState<PagosVentaScreen> {
  static final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(pagosProvider(widget.ventaId).notifier).cargar());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagosProvider(widget.ventaId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Cobros — venta #${widget.ventaId}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegistrarPagoSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar pago'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(pagosProvider(widget.ventaId).notifier).cargar(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(pagosProvider(widget.ventaId).notifier).cargar(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.saldo != null) _SaldoCard(saldo: state.saldo!),
                      const SizedBox(height: 16),
                      if (state.pagos.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No hay pagos registrados'),
                          ),
                        )
                      else
                        ...state.pagos
                            .map((p) => _PagoTile(pago: p, dateFmt: _dateFmt, moneyFmt: _fmt)),
                    ],
                  ),
                ),
    );
  }

  void _showRegistrarPagoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PagoForm(ventaId: widget.ventaId),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de saldo
// ---------------------------------------------------------------------------
class _SaldoCard extends StatelessWidget {
  const _SaldoCard({required this.saldo});
  final SaldoVenta saldo;

  static final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  Color _colorEstado(String estado) => switch (estado) {
        'COMPLETO' => Colors.green,
        'PARCIAL' => Colors.orange,
        _ => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cliente: ${saldo.usuario}',
                    style: theme.textTheme.titleMedium),
                Chip(
                  label: Text(saldo.estadoPago,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _colorEstado(saldo.estadoPago),
                ),
              ],
            ),
            const Divider(),
            _Row(label: 'Total venta', value: _fmt.format(saldo.totalVenta)),
            _Row(label: 'Total pagado', value: _fmt.format(saldo.totalPagado)),
            _Row(
              label: 'Saldo pendiente',
              value: _fmt.format(saldo.saldoPendiente),
              highlight: saldo.saldoPendiente > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.red : null,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Tile de pago
// ---------------------------------------------------------------------------
class _PagoTile extends StatelessWidget {
  const _PagoTile(
      {required this.pago, required this.dateFmt, required this.moneyFmt});
  final PagoVenta pago;
  final DateFormat dateFmt;
  final NumberFormat moneyFmt;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
          title: Text(moneyFmt.format(pago.monto)),
          subtitle: Text(
              '${dateFmt.format(pago.fecha)}${pago.concepto != null ? "\n${pago.concepto}" : ""}'),
          trailing: pago.metodoPago != null
              ? Chip(label: Text(pago.metodoPago!))
              : null,
          isThreeLine: pago.concepto != null,
        ),
      );
}

// ---------------------------------------------------------------------------
// Formulario de registro de pago
// ---------------------------------------------------------------------------
class _PagoForm extends ConsumerStatefulWidget {
  const _PagoForm({required this.ventaId});
  final int ventaId;

  @override
  ConsumerState<_PagoForm> createState() => _PagoFormState();
}

class _PagoFormState extends ConsumerState<_PagoForm> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  String? _metodoPago;

  static const _metodos = ['EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'OTRO'];

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        ref.watch(pagosProvider(widget.ventaId)).isSaving;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Registrar pago',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conceptoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: _metodos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _metodoPago = v),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final request = PagoVentaRequest(
      monto: double.parse(_montoCtrl.text),
      concepto: _conceptoCtrl.text.isNotEmpty ? _conceptoCtrl.text : null,
      metodoPago: _metodoPago,
    );
    final ok = await ref
        .read(pagosProvider(widget.ventaId).notifier)
        .registrar(request);
    if (ok && mounted) Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Widget de error
// ---------------------------------------------------------------------------
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
}
