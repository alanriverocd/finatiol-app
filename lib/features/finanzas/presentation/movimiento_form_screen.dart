import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/movimiento_model.dart';
import 'finanzas_provider.dart';

class MovimientoFormScreen extends ConsumerStatefulWidget {
  const MovimientoFormScreen({super.key});

  @override
  ConsumerState<MovimientoFormScreen> createState() =>
      _MovimientoFormScreenState();
}

class _MovimientoFormScreenState
    extends ConsumerState<MovimientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  TipoMovimiento _tipo = TipoMovimiento.ingreso;
  bool _saving = false;

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final request = MovimientoRequest(
      tipo: _tipo,
      concepto: _conceptoCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text.trim()),
      referencia: _referenciaCtrl.text.trim().isEmpty
          ? null
          : _referenciaCtrl.text.trim(),
    );

    final ok = await ref.read(finanzasProvider.notifier).registrar(request);
    setState(() => _saving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Movimiento registrado correctamente'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIngreso = _tipo == TipoMovimiento.ingreso;
    final accentColor =
        isIngreso ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      appBar: const FinatiolAppBar(
        title: Text('Nuevo movimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de tipo
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de movimiento',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: TipoMovimiento.values.map((tipo) {
                          final selected = _tipo == tipo;
                          final esIngreso = tipo == TipoMovimiento.ingreso;
                          final color = esIngreso
                              ? Colors.green.shade600
                              : Colors.red.shade600;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right:
                                      esIngreso ? 6 : 0,
                                  left: esIngreso ? 0 : 6),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      esIngreso
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(tipo.label),
                                  ],
                                ),
                                selected: selected,
                                selectedColor: color,
                                labelStyle: TextStyle(
                                  color:
                                      selected ? Colors.white : color,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    setState(() => _tipo = tipo),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Concepto
              TextFormField(
                controller: _conceptoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El concepto es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _montoCtrl,
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  prefixIcon: Icon(Icons.attach_money,
                      color: accentColor),
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) {
                    return 'Ingresa un monto mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Referencia (opcional)
              TextFormField(
                controller: _referenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  prefixIcon: Icon(Icons.tag_outlined),
                  hintText: 'Ej. VENTA-123, PAGO-456',
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              ElevatedButton.icon(
                onPressed: _saving ? null : _guardar,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  'Registrar ${_tipo.label.toLowerCase()}',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
