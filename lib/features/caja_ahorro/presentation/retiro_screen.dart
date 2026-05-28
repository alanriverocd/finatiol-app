import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import 'ahorro_provider.dart';

class RetiroScreen extends ConsumerStatefulWidget {
  final int cuentaId;
  const RetiroScreen({super.key, required this.cuentaId});

  @override
  ConsumerState<RetiroScreen> createState() => _RetiroScreenState();
}

class _RetiroScreenState extends ConsumerState<RetiroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FinatiolAppBar(title: Text('Retirar — Cuenta #${widget.cuentaId}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El monto es requerido';
                  }
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  hintText: 'Ej. pago, efectivo...',
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(context),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_upward),
                label: Text(_submitting ? 'Procesando...' : 'Confirmar retiro'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final ok = await ref.read(ahorroProvider.notifier).retirar(
            cuentaId: widget.cuentaId,
            monto: double.parse(_montoCtrl.text.trim()),
            referencia: _referenciaCtrl.text.trim().isEmpty
                ? null
                : _referenciaCtrl.text.trim(),
          );
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Retiro realizado exitosamente'),
              backgroundColor: Colors.orange),
        );
        Navigator.of(context).pop();
      } else if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar el retiro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
