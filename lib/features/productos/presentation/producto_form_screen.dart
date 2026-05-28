import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/producto_model.dart';
import 'productos_provider.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  /// Si es null, es modo creaciÃ³n. Si tiene valor, es modo ediciÃ³n.
  final Producto? producto;

  @override
  ConsumerState<ProductoFormScreen> createState() =>
      _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  bool _saving = false;
  bool _procesandoImagen = false;

  // Modo creaciÃ³n: imÃ¡genes seleccionadas aÃºn no subidas.
  final List<XFile> _imagenesNuevas = [];

  // Modo ediciÃ³n: imÃ¡genes actuales del producto.
  late List<ProductoImagen> _imagenesExistentes;

  final _picker = ImagePicker();

  bool get _esEdicion => widget.producto != null;

  int get _totalImagenes =>
      _esEdicion ? _imagenesExistentes.length : _imagenesNuevas.length;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl =
        TextEditingController(text: p != null ? p.precio.toString() : '');
    _stockCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _imagenesExistentes = List.from(p?.imagenes ?? []);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final req = ProductoRequest(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      precio: double.parse(_precioCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
    );

    bool ok;
    if (_esEdicion) {
      ok = await ref
          .read(productosProvider.notifier)
          .actualizar(widget.producto!.id, req);
    } else {
      ok = await ref
          .read(productosProvider.notifier)
          .crear(req, imagenes: _imagenesNuevas);
    }

    setState(() => _saving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion
              ? 'Producto actualizado correctamente'
              : 'Producto creado correctamente'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImages() async {
    final disponibles = 10 - _totalImagenes;
    if (disponibles <= 0) return;

    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    final toAdd = picked.take(disponibles).toList();

    if (_esEdicion) {
      setState(() => _procesandoImagen = true);
      try {
        final actualizado = await ref
            .read(productoRepositoryProvider)
            .agregarImagenes(widget.producto!.id, toAdd);
        if (!mounted) return;
        ref
            .read(productosProvider.notifier)
            .actualizarImagenesEnEstado(widget.producto!.id, actualizado.imagenes);
        setState(() {
          _imagenesExistentes = List.from(actualizado.imagenes);
          _procesandoImagen = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _procesandoImagen = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir imÃ¡genes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _imagenesNuevas.addAll(toAdd));
    }
  }

  Future<void> _eliminarImagenExistente(ProductoImagen imagen) async {
    setState(() => _procesandoImagen = true);
    try {
      await ref
          .read(productoRepositoryProvider)
          .eliminarImagen(widget.producto!.id, imagen.id);
      if (!mounted) return;
      final nuevas =
          _imagenesExistentes.where((img) => img.id != imagen.id).toList();
      ref
          .read(productosProvider.notifier)
          .actualizarImagenesEnEstado(widget.producto!.id, nuevas);
      setState(() {
        _imagenesExistentes = nuevas;
        _procesandoImagen = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesandoImagen = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FinatiolAppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (v.trim().length < 2) {
                    return 'MÃ­nimo 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // DescripciÃ³n
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'DescripciÃ³n (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Precio y Stock en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final d = double.tryParse(v.trim());
                        if (d == null || d < 0) return 'Precio invÃ¡lido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        prefixIcon: Icon(Icons.inventory_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0) return 'Valor invÃ¡lido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SecciÃ³n de imÃ¡genes
              _buildSeccionImagenes(),

              const SizedBox(height: 32),

              // BotÃ³n guardar
              ElevatedButton.icon(
                onPressed: _saving ? null : _guardar,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_esEdicion ? Icons.save_outlined : Icons.add),
                label: Text(
                  _esEdicion ? 'Guardar cambios' : 'Crear producto',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionImagenes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ImÃ¡genes ($_totalImagenes / 10)',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500),
            ),
            if (_totalImagenes < 10 && !_procesandoImagen)
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18),
                label: const Text('AÃ±adir'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_procesandoImagen)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_totalImagenes == 0)
          _EmptyImagenesArea(onAdd: _pickImages)
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _totalImagenes + (_totalImagenes < 10 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == _totalImagenes) {
                  return _AgregarImagenBtn(onTap: _pickImages);
                }
                if (_esEdicion) {
                  final img = _imagenesExistentes[i];
                  return _ImagenExistentePreview(
                    imagen: img,
                    onEliminar: () => _eliminarImagenExistente(img),
                  );
                } else {
                  return _ImagenNuevaPreview(
                    file: _imagenesNuevas[i],
                    onRemover: () =>
                        setState(() => _imagenesNuevas.removeAt(i)),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

// â”€â”€ Subwidgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyImagenesArea extends StatelessWidget {
  const _EmptyImagenesArea({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey.shade400, size: 28),
            const SizedBox(height: 4),
            Text(
              'Toca para aÃ±adir imÃ¡genes',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgregarImagenBtn extends StatelessWidget {
  const _AgregarImagenBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Icon(Icons.add_photo_alternate_outlined,
            color: Colors.grey.shade400, size: 28),
      ),
    );
  }
}

class _ImagenExistentePreview extends StatelessWidget {
  const _ImagenExistentePreview(
      {required this.imagen, required this.onEliminar});
  final ProductoImagen imagen;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imagen.url,
            width: 90,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 90,
              height: 110,
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image,
                  color: Colors.grey.shade400),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onEliminar,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagenNuevaPreview extends StatelessWidget {
  const _ImagenNuevaPreview(
      {required this.file, required this.onRemover});
  final XFile file;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<Uint8List>(
          future: file.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  snapshot.data!,
                  width: 90,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemover,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
