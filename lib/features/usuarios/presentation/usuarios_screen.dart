import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/usuario_model.dart';
import 'usuarios_provider.dart';
import 'usuario_form_screen.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  UsuariosNotifier get _usuariosNotifier => ref.read(usuariosProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(usuariosProvider.notifier).cargar());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Usuario> _filtrar(List<Usuario> usuarios) {
    if (_query.isEmpty) return usuarios;
    final q = _query.toLowerCase();
    return usuarios.where((u) {
      return u.nombre.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmarEliminar(BuildContext context, Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Eliminar a "${usuario.nombre}" (@${usuario.username})? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await ref.read(usuariosProvider.notifier).eliminar(usuario.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosProvider);
    final filtrados = _filtrar(state.usuarios);

    ref.listen<UsuariosState>(usuariosProvider, (previous, next) {
      if (next.error != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade600,
          ),
        );
        if (!mounted) return;
        _usuariosNotifier.clearError();
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Usuarios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, usuario o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(usuariosProvider.notifier).cargar(),
              child: filtrados.isEmpty
                  ? const _EmptyView()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          color: const Color(0xFFEAF3FF),
                          elevation: 0,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              child: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: const Text('Usuarios registrados'),
                            subtitle: Text('${state.totalUsuarios} usuarios en el sistema'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(filtrados.length, (index) {
                          final usuario = filtrados[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _UsuarioCard(
                              usuario: usuario,
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UsuarioFormScreen(usuario: usuario),
                                ),
                              ),
                              onDelete: () =>
                                  _confirmarEliminar(context, usuario),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const UsuarioFormScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo'),
      ),
    );
  }
}

// ── Cards ──────────────────────────────────────────────────────────────────

class _UsuarioCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UsuarioCard({
    required this.usuario,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UsuarioAvatar(nombre: usuario.nombre),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              usuario.nombre,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _EstadoBadge(activo: usuario.activo),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${usuario.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary),
                      ),
                      Text(
                        usuario.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (usuario.roles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: usuario.roles
                    .map((rol) => _RolChip(rol: rol))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: Colors.red.shade600),
                  label: Text('Eliminar',
                      style: TextStyle(color: Colors.red.shade600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UsuarioAvatar extends StatelessWidget {
  final String nombre;

  const _UsuarioAvatar({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 24,
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        inicial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final bool activo;

  const _EstadoBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: activo ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

class _RolChip extends StatelessWidget {
  final String rol;

  const _RolChip({required this.rol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rol,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega el primer usuario con el botón +',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
