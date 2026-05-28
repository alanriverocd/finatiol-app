import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/producto_model.dart';
import 'productos_provider.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  ProductosNotifier get _productosNotifier => ref.read(productosProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Carga inicial
    Future.microtask(() => ref.read(productosProvider.notifier).cargar());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> lista) {
    if (_query.isEmpty) return lista;
    final q = _query.toLowerCase();
    return lista
        .where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            (p.descripcion?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productosProvider);
    final filtrados = _filtrar(state.productos);

    // Mostrar snackbar si hay error
    ref.listen(productosProvider, (_, next) {
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
                _productosNotifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(productosProvider.notifier).cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: const Color(0xFFEAF3FF),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.inventory_2_outlined, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Productos activos'),
                subtitle: Text('${state.totalActivos} productos habilitados en el catálogo'),
              ),
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Contenido
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? _EmptyView(
                        hasFilter: _query.isNotEmpty,
                        onAdd: () => _abrirFormulario(context),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(productosProvider.notifier).cargar(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtrados.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) => _ProductoCard(
                            producto: filtrados[i],
                            onEditar: () =>
                                _abrirFormulario(context, producto: filtrados[i]),
                            onEliminar: () =>
                                _confirmarEliminar(context, filtrados[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {Producto? producto}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(producto: producto),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
            '¿Deseas eliminar "${producto.nombre}"? Esta acción no se puede deshacer.'),
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
                  .read(productosProvider.notifier)
                  .eliminar(producto.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta de producto ---

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({
    required this.producto,
    required this.onEditar,
    required this.onEliminar,
  });

  final Producto producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _ProductoAvatar(imagenUrl: producto.imagenUrl),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.descripcion != null)
              Text(
                producto.descripcion!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  FormatUtils.currency(producto.precio),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                _StockBadge(stock: producto.stock),
                const SizedBox(width: 8),
                if (!producto.activo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Inactivo',
                      style: TextStyle(
                          fontSize: 10, color: Colors.orange.shade800),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'editar') onEditar();
            if (v == 'eliminar') onEliminar();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoAvatar extends StatelessWidget {
  const _ProductoAvatar({this.imagenUrl});

  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    if (imagenUrl != null && imagenUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagenUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.inventory_2_outlined,
            color: Color(0xFF1565C0), size: 24),
      );
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final isLow = stock <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Stock: $stock',
        style: TextStyle(
          fontSize: 11,
          color: isLow ? Colors.red.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// --- Empty state ---

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
            hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Sin resultados para esa búsqueda'
                : 'No hay productos registrados',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
          ],
        ],
      ),
    );
  }
}
