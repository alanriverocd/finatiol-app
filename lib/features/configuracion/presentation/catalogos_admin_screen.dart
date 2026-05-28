import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/finatiol_app_bar.dart';
import 'catalogos_admin_provider.dart';

class CatalogosAdminScreen extends ConsumerStatefulWidget {
  const CatalogosAdminScreen({super.key});

  @override
  ConsumerState<CatalogosAdminScreen> createState() => _CatalogosAdminScreenState();
}

class _CatalogosAdminScreenState extends ConsumerState<CatalogosAdminScreen> {
  CatalogosAdminNotifier get _catalogosNotifier => ref.read(catalogosAdminProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _catalogosNotifier.cargar());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogosAdminProvider);

    ref.listen(catalogosAdminProvider, (_, next) {
      if (next.error != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  if (!mounted) return;
                  _catalogosNotifier.clearError();
                },
              ),
            ),
          );
      }
    });

    return Scaffold(
      appBar: const FinatiolAppBar(title: Text('Catálogos admin')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(tabs: [
                    Tab(text: 'Tenants'),
                    Tab(text: 'Módulos'),
                    Tab(text: 'Permisos'),
                    Tab(text: 'Roles'),
                  ]),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _CatalogTab(
                          title: 'Tenants',
                          emptyText: 'Sin tenants registrados',
                          items: state.tenants,
                          itemBuilder: (item) => '${item['id']} · ${item['nombre']}',
                          onCreate: _crearTenant,
                          onEdit: _editarTenant,
                          onDelete: (item) => ref.read(catalogosAdminProvider.notifier).eliminarTenant(item['id'].toString()),
                        ),
                        _CatalogTab(
                          title: 'Módulos',
                          emptyText: 'Sin módulos registrados',
                          items: state.modulos,
                          itemBuilder: (item) => '${item['nombre']} · ${item['ruta']}',
                          onCreate: _crearModulo,
                          onEdit: _editarModulo,
                          onDelete: (item) => ref.read(catalogosAdminProvider.notifier).eliminarModulo((item['id'] as num).toInt()),
                        ),
                        _CatalogTab(
                          title: 'Permisos',
                          emptyText: 'Sin permisos registrados',
                          items: state.permisos,
                          itemBuilder: (item) => '${item['nombre']} · ${(item['modulo']?['nombre'] ?? 'sin módulo')}',
                          onCreate: _crearPermiso,
                          onEdit: _editarPermiso,
                          onDelete: (item) => ref.read(catalogosAdminProvider.notifier).eliminarPermiso((item['id'] as num).toInt()),
                        ),
                        _CatalogTab(
                          title: 'Roles',
                          emptyText: 'Sin roles registrados',
                          items: state.roles,
                          itemBuilder: (item) => '${item['nombre']} · ${(item['permisos'] as List?)?.length ?? 0} permisos',
                          onCreate: _crearRol,
                          onEdit: _editarRol,
                          onDelete: (item) => ref.read(catalogosAdminProvider.notifier).eliminarRol((item['id'] as num).toInt()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _crearTenant() async {
    final data = await _showTenantDialog(title: 'Nuevo tenant');
    if (data == null) return;
    await ref.read(catalogosAdminProvider.notifier).crearTenant(data['id']!, data['nombre']!);
  }

  Future<void> _editarTenant(Map<String, dynamic> item) async {
    final data = await _showTenantDialog(
      title: 'Editar tenant',
      initialId: item['id']?.toString() ?? '',
      initialNombre: item['nombre']?.toString() ?? '',
    );
    if (data == null) return;
    final confirmed = await _confirmReplace(
      title: 'Actualizar tenant',
      message: 'Se reemplazará el tenant actual por la nueva versión.',
    );
    if (!confirmed) return;
    await ref.read(catalogosAdminProvider.notifier).actualizarTenant(
      originalId: item['id'].toString(),
      id: data['id']!,
      nombre: data['nombre']!,
    );
  }

  Future<void> _crearModulo() async {
    final data = await _showModuloDialog();
    if (data == null) return;
    await ref.read(catalogosAdminProvider.notifier).crearModulo(
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      ruta: data['ruta']!,
      icono: data['icono']!,
      activo: data['activo'] == 'true',
    );
  }

  Future<void> _editarModulo(Map<String, dynamic> item) async {
    final data = await _showModuloDialog(
      title: 'Editar módulo',
      initialNombre: item['nombre']?.toString() ?? '',
      initialDescripcion: item['descripcion']?.toString() ?? '',
      initialRuta: item['ruta']?.toString() ?? '',
      initialIcono: item['icono']?.toString() ?? 'settings_outlined',
      initialActivo: item['activo'] as bool? ?? true,
    );
    if (data == null) return;
    final confirmed = await _confirmReplace(
      title: 'Actualizar módulo',
      message: 'Se reemplazará el módulo actual por la nueva versión.',
    );
    if (!confirmed) return;
    await ref.read(catalogosAdminProvider.notifier).actualizarModulo(
      id: (item['id'] as num).toInt(),
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      ruta: data['ruta']!,
      icono: data['icono']!,
      activo: data['activo'] == 'true',
    );
  }

  Future<void> _crearPermiso() async {
    final data = await _showPermisoDialog();
    if (data == null) return;
    final moduloId = data['moduloId']?.isEmpty == true ? null : int.tryParse(data['moduloId'] ?? '');
    await ref.read(catalogosAdminProvider.notifier).crearPermiso(
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      moduloId: moduloId,
    );
  }

  Future<void> _editarPermiso(Map<String, dynamic> item) async {
    final data = await _showPermisoDialog(
      title: 'Editar permiso',
      initialNombre: item['nombre']?.toString() ?? '',
      initialDescripcion: item['descripcion']?.toString() ?? '',
      initialModuloId: item['modulo']?['id']?.toString(),
    );
    if (data == null) return;
    final confirmed = await _confirmReplace(
      title: 'Actualizar permiso',
      message: 'Se reemplazará el permiso actual por la nueva versión.',
    );
    if (!confirmed) return;
    final moduloId = data['moduloId']?.isEmpty == true ? null : int.tryParse(data['moduloId'] ?? '');
    await ref.read(catalogosAdminProvider.notifier).actualizarPermiso(
      id: (item['id'] as num).toInt(),
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      moduloId: moduloId,
    );
  }

  Future<void> _crearRol() async {
    final data = await _showRolDialog();
    if (data == null) return;
    final permisosIds = (data['permisosIds'] ?? <int>[]).map<int>((e) => e as int).toSet();
    await ref.read(catalogosAdminProvider.notifier).crearRol(
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      permisosIds: permisosIds,
    );
  }

  Future<void> _editarRol(Map<String, dynamic> item) async {
    final permisosActuales = ((item['permisos'] as List<dynamic>?) ?? const [])
        .map((permiso) => (permiso as Map)['id'] as int)
        .toSet();
    final data = await _showRolDialog(
      title: 'Editar rol',
      initialNombre: item['nombre']?.toString() ?? '',
      initialDescripcion: item['descripcion']?.toString() ?? '',
      initialPermisosIds: permisosActuales,
    );
    if (data == null) return;
    final confirmed = await _confirmReplace(
      title: 'Actualizar rol',
      message: 'Se reemplazará el rol actual por la nueva versión.',
    );
    if (!confirmed) return;
    final permisosIds = (data['permisosIds'] ?? <int>[]).map<int>((e) => e as int).toSet();
    await ref.read(catalogosAdminProvider.notifier).actualizarRol(
      id: (item['id'] as num).toInt(),
      nombre: data['nombre']!,
      descripcion: data['descripcion']!,
      permisosIds: permisosIds,
    );
  }

  Future<Map<String, String>?> _showTenantDialog({
    required String title,
    String initialId = '',
    String initialNombre = '',
  }) async {
    final idCtrl = TextEditingController(text: initialId);
    final nombreCtrl = TextEditingController(text: initialNombre);
    final tenants = ref.read(catalogosAdminProvider).tenants;
    String? selectedTenantId = tenants.any((tenant) => tenant['id']?.toString() == initialId)
        ? initialId
        : null;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: selectedTenantId,
                  decoration: const InputDecoration(labelText: 'Disponibles (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Captura manual')),
                    ...tenants.map(
                      (tenant) => DropdownMenuItem<String?>(
                        value: tenant['id']?.toString(),
                        child: Text('${tenant['id']} · ${tenant['nombre']}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedTenantId = value);
                    if (value == null) return;
                    final selected = tenants.cast<Map<String, dynamic>>().firstWhere(
                          (tenant) => tenant['id']?.toString() == value,
                          orElse: () => const {},
                        );
                    if (selected.isNotEmpty) {
                      idCtrl.text = selected['id']?.toString() ?? '';
                      nombreCtrl.text = selected['nombre']?.toString() ?? '';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'ID')),
                const SizedBox(height: 12),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final id = idCtrl.text.trim();
                final nombre = nombreCtrl.text.trim();
                if (id.isEmpty || nombre.isEmpty) return;
                Navigator.pop(ctx, {'id': id, 'nombre': nombre});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    idCtrl.dispose();
    nombreCtrl.dispose();
    return result;
  }

  Future<Map<String, String>?> _showModuloDialog({
    String title = 'Nuevo módulo',
    String initialNombre = '',
    String initialDescripcion = '',
    String initialRuta = '',
    String initialIcono = 'settings_outlined',
    bool initialActivo = true,
  }) async {
    final nombreCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final rutaCtrl = TextEditingController();
    final iconoCtrl = TextEditingController(text: 'settings_outlined');
    bool activo = true;
    final modulos = ref.read(catalogosAdminProvider).modulos;
    String? selectedModuloId;

    nombreCtrl.text = initialNombre;
    descripcionCtrl.text = initialDescripcion;
    rutaCtrl.text = initialRuta;
    iconoCtrl.text = initialIcono;
    activo = initialActivo;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: selectedModuloId,
                  decoration: const InputDecoration(labelText: 'Disponibles (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Captura manual')),
                    ...modulos.map(
                      (modulo) => DropdownMenuItem<String?>(
                        value: (modulo['id'] as num?)?.toInt().toString(),
                        child: Text('${modulo['nombre']} · ${modulo['ruta']}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedModuloId = value);
                    if (value == null) return;
                    final selected = modulos.cast<Map<String, dynamic>>().firstWhere(
                          (modulo) => (modulo['id'] as num?)?.toInt().toString() == value,
                          orElse: () => const {},
                        );
                    if (selected.isNotEmpty) {
                      nombreCtrl.text = selected['nombre']?.toString() ?? '';
                      descripcionCtrl.text = selected['descripcion']?.toString() ?? '';
                      rutaCtrl.text = selected['ruta']?.toString() ?? '';
                      iconoCtrl.text = selected['icono']?.toString() ?? 'settings_outlined';
                      activo = selected['activo'] as bool? ?? true;
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                const SizedBox(height: 12),
                TextField(controller: rutaCtrl, decoration: const InputDecoration(labelText: 'Ruta')),
                const SizedBox(height: 12),
                TextField(controller: iconoCtrl, decoration: const InputDecoration(labelText: 'Icono')),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: activo,
                  onChanged: (value) => setDialogState(() => activo = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final descripcion = descripcionCtrl.text.trim();
                final ruta = rutaCtrl.text.trim();
                final icono = iconoCtrl.text.trim();
                if (nombre.isEmpty || descripcion.isEmpty || ruta.isEmpty || icono.isEmpty) return;
                Navigator.pop(ctx, {
                  'nombre': nombre,
                  'descripcion': descripcion,
                  'ruta': ruta,
                  'icono': icono,
                  'activo': activo.toString(),
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    rutaCtrl.dispose();
    iconoCtrl.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _showPermisoDialog({
    String title = 'Nuevo permiso',
    String initialNombre = '',
    String initialDescripcion = '',
    String? initialModuloId,
  }) async {
    final nombreCtrl = TextEditingController(text: initialNombre);
    final descripcionCtrl = TextEditingController(text: initialDescripcion);
    String? selectedModuloId = initialModuloId;
    String? selectedPermisoId;
    final modulos = ref.read(catalogosAdminProvider).modulos;
    final permisos = ref.read(catalogosAdminProvider).permisos;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: selectedPermisoId,
                  decoration: const InputDecoration(labelText: 'Disponibles (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Captura manual')),
                    ...permisos.map(
                      (permiso) => DropdownMenuItem<String?>(
                        value: (permiso['id'] as num?)?.toInt().toString(),
                        child: Text('${permiso['nombre']} · ${(permiso['modulo']?['nombre'] ?? 'sin módulo')}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedPermisoId = value);
                    if (value == null) return;
                    final selected = permisos.cast<Map<String, dynamic>>().firstWhere(
                          (permiso) => (permiso['id'] as num?)?.toInt().toString() == value,
                          orElse: () => const {},
                        );
                    if (selected.isNotEmpty) {
                      nombreCtrl.text = selected['nombre']?.toString() ?? '';
                      descripcionCtrl.text = selected['descripcion']?.toString() ?? '';
                      selectedModuloId = selected['modulo']?['id']?.toString();
                      setDialogState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedModuloId,
                  decoration: const InputDecoration(labelText: 'Módulo (opcional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Sin módulo')),
                    ...modulos.map(
                      (modulo) => DropdownMenuItem<String?>(
                        value: (modulo['id'] as num).toString(),
                        child: Text('${modulo['nombre']} · ${modulo['ruta']}'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => selectedModuloId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final descripcion = descripcionCtrl.text.trim();
                if (nombre.isEmpty || descripcion.isEmpty) return;
                Navigator.pop(ctx, {
                  'nombre': nombre,
                  'descripcion': descripcion,
                  'moduloId': selectedModuloId ?? '',
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    return result;
  }

  Future<Map<String, dynamic>?> _showRolDialog({
    String title = 'Nuevo rol',
    String initialNombre = '',
    String initialDescripcion = '',
    Set<int> initialPermisosIds = const {},
  }) async {
    final nombreCtrl = TextEditingController(text: initialNombre);
    final descripcionCtrl = TextEditingController(text: initialDescripcion);
    final selected = <int>{...initialPermisosIds};
    String? selectedRolId;
    final permisos = ref.read(catalogosAdminProvider).permisos;
    final roles = ref.read(catalogosAdminProvider).roles;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: selectedRolId,
                    decoration: const InputDecoration(labelText: 'Disponibles (opcional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Captura manual')),
                      ...roles.map(
                        (rol) => DropdownMenuItem<String?>(
                          value: (rol['id'] as num?)?.toInt().toString(),
                          child: Text('${rol['nombre']} · ${(rol['permisos'] as List?)?.length ?? 0} permisos'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedRolId = value);
                      if (value == null) return;
                      final selectedRol = roles.cast<Map<String, dynamic>>().firstWhere(
                            (rol) => (rol['id'] as num?)?.toInt().toString() == value,
                            orElse: () => const {},
                          );
                      if (selectedRol.isNotEmpty) {
                        nombreCtrl.text = selectedRol['nombre']?.toString() ?? '';
                        descripcionCtrl.text = selectedRol['descripcion']?.toString() ?? '';
                        selected
                          ..clear()
                          ..addAll(
                            ((selectedRol['permisos'] as List<dynamic>?) ?? const [])
                                .map((permiso) => ((permiso as Map)['id'] as num).toInt()),
                          );
                        setDialogState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 12),
                  TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Permisos', style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  if (permisos.isEmpty)
                    const Text('No hay permisos disponibles')
                  else
                    ...permisos.map((permiso) {
                      final id = (permiso['id'] as num).toInt();
                      final checked = selected.contains(id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: checked,
                        title: Text('${permiso['nombre']}'),
                        subtitle: Text('${permiso['descripcion'] ?? ''}'),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          });
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final descripcion = descripcionCtrl.text.trim();
                if (nombre.isEmpty || descripcion.isEmpty) return;
                Navigator.pop(ctx, {
                  'nombre': nombre,
                  'descripcion': descripcion,
                  'permisosIds': selected.toList(),
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    return result;
  }

  Future<bool> _confirmReplace({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    return result == true;
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.title, required this.emptyText, required this.items, required this.itemBuilder, required this.onCreate, required this.onEdit, required this.onDelete});

  final String title;
  final String emptyText;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) itemBuilder;
  final Future<void> Function() onCreate;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: Text('Nuevo $title')),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyText)))
        else
          ...items.map((item) => Card(
                child: ListTile(
                  title: Text(itemBuilder(item)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => onEdit(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => onDelete(item),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}