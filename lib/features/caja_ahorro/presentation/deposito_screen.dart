import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import 'ahorro_provider.dart';

class DepositoScreen extends ConsumerStatefulWidget {
  final int cuentaId;
  const DepositoScreen({super.key, required this.cuentaId});

  @override
  ConsumerState<DepositoScreen> createState() => _DepositoScreenState();
}

class _DepositoScreenState extends ConsumerState<DepositoScreen> {
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
      appBar: FinatiolAppBar(title: Text('Depositar — Cuenta #${widget.cuentaId}')),
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
                  hintText: 'Ej. transferencia, efectivo...',
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
                    : const Icon(Icons.arrow_downward),
                label: Text(_submitting ? 'Procesando...' : 'Confirmar depósito'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
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
      final ok = await ref.read(ahorroProvider.notifier).depositar(
            cuentaId: widget.cuentaId,
            monto: double.parse(_montoCtrl.text.trim()),
            referencia: _referenciaCtrl.text.trim().isEmpty
                ? null
                : _referenciaCtrl.text.trim(),
          );
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Depósito realizado exitosamente'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo registrar el depósito'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
