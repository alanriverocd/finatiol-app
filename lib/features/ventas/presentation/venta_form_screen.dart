import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/venta_model.dart';
import 'ventas_provider.dart';

// ---------------------------------------------------------------------------
// Provider local (autoDispose) para productos activos — solo vive en este form
// ---------------------------------------------------------------------------
final _productosActivosProvider =
    FutureProvider.autoDispose<List<ProductoResumen>>((ref) {
  return ref.watch(ventaRepositoryProvider).productosActivos();
});

// ---------------------------------------------------------------------------
// Pantalla de formulario
// ---------------------------------------------------------------------------
class VentaFormScreen extends ConsumerStatefulWidget {
  const VentaFormScreen({super.key});

  @override
  ConsumerState<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends ConsumerState<VentaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final List<_CartItem> _carrito = [];
  bool _saving = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      _carrito.fold(0.0, (sum, item) => sum + item.subtotal);

  void _abrirPickerProducto() async {
    final seleccionado = await showModalBottomSheet<_CartItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ProductPickerSheet(),
    );
    if (seleccionado != null) {
      setState(() {
        final idx = _carrito.indexWhere(
            (c) => c.productoId == seleccionado.productoId);
        if (idx >= 0) {
          // Sumar cantidad si ya existe
          final existente = _carrito[idx];
          _carrito[idx] = _CartItem(
            productoId: existente.productoId,
            productoNombre: existente.productoNombre,
            cantidad: existente.cantidad + seleccionado.cantidad,
            precio: existente.precio,
          );
        } else {
          _carrito.add(seleccionado);
        }
      });
    }
  }

  void _removerItem(int index) => setState(() => _carrito.removeAt(index));

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega al menos un producto al carrito')),
      );
      return;
    }
    setState(() => _saving = true);

    final request = VentaRequest(
      usuario: _usuarioCtrl.text.trim(),
      detalles: _carrito
          .map((c) => DetalleVentaRequest(
                productoId: c.productoId,
                productoNombre: c.productoNombre,
                cantidad: c.cantidad,
                precio: c.precio,
              ))
          .toList(),
    );

    final ok = await ref.read(ventasProvider.notifier).crear(request);
    setState(() => _saving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Venta creada correctamente'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const FinatiolAppBar(title: Text('Nueva venta')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Campo usuario
                  TextFormField(
                    controller: _usuarioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Usuario / Vendedor *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El usuario es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Encabezado carrito
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos (${_carrito.length})',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _abrirPickerProducto,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Lista carrito
                  if (_carrito.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'Sin productos en el carrito',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...List.generate(
                          _carrito.length,
                          (i) => _CartRow(
                            item: _carrito[i],
                            onRemove: () => _removerItem(i),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Total estimado:  ',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              FormatUtils.currency(_total),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Botón inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _guardar,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar venta',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila del carrito
// ---------------------------------------------------------------------------
class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.onRemove});

  final _CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.productoNombre,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            '${item.cantidad} × ${FormatUtils.currency(item.precio)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Text(
            FormatUtils.currency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hoja de selección de producto
// ---------------------------------------------------------------------------
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _cantCtrl = TextEditingController(text: '1');
  ProductoResumen? _seleccionado;
  String _query = '';

  @override
  void dispose() {
    _cantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(_productosActivosProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle
          const _SheetHandle(),

          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Seleccionar producto',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Lista
          Expanded(
            child: productosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error al cargar productos: $e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (productos) {
                final filtrados = _query.isEmpty
                    ? productos
                    : productos
                        .where((p) => p.nombre
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final p = filtrados[i];
                    final isSelected = _seleccionado?.id == p.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF1565C0)
                          .withValues(alpha: 0.08),
                      title: Text(p.nombre),
                      subtitle: Text(
                        '${FormatUtils.currency(p.precio)}  ·  Stock: ${p.stock}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF1565C0))
                          : null,
                      onTap: () => setState(() => _seleccionado = p),
                    );
                  },
                );
              },
            ),
          ),

          // Cantidad y confirmación
          if (_seleccionado != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cantCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        prefixIcon: Icon(Icons.numbers),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final cant = int.tryParse(_cantCtrl.text.trim());
                      if (cant == null || cant <= 0) return;
                      if (cant > _seleccionado!.stock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Stock disponible: ${_seleccionado!.stock}'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(
                        context,
                        _CartItem(
                          productoId: _seleccionado!.id,
                          productoNombre: _seleccionado!.nombre,
                          cantidad: cant,
                          precio: _seleccionado!.precio,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Modelo interno del carrito (no requiere Equatable)
// ---------------------------------------------------------------------------
class _CartItem {
  const _CartItem({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precio,
  });

  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precio;

  double get subtotal => cantidad * precio;
}
