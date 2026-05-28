import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../../auth/presentation/auth_provider.dart';
import 'configuracion_provider.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(loginProvider);
    final storedAuthAsync = ref.watch(storedAuthProvider);
    final memoryAuth = authState.auth;
    final storedAuth = storedAuthAsync.value;
    final auth = (memoryAuth != null && (memoryAuth.roles.isNotEmpty || memoryAuth.permisos.isNotEmpty || memoryAuth.username.trim().isNotEmpty))
        ? memoryAuth
        : storedAuth;
    final username = (auth?.username ?? '').trim().isEmpty ? '—' : auth!.username;
    final roles = auth?.roles ?? const <String>[];
    final permisos = auth?.permisos ?? const <String>[];
    final tenantId = auth?.tenantId ?? '—';
    final roleSet = roles.map((role) => role.toUpperCase()).toSet();
    final permisosSet = permisos.map((permiso) => permiso.toUpperCase()).toSet();
    final usernameUpper = (auth?.username ?? '').toUpperCase();
    final isAdmin =
      roleSet.any((role) => role == 'ADMIN' || role == 'ROLE_ADMIN' || role.contains('ADMIN')) ||
      permisosSet.any((permiso) => permiso.contains('ADMIN') || permiso.contains('CATALOGO') || permiso.contains('MODULO') || permiso.contains('ROL')) ||
      usernameUpper == 'ADMIN';

    return Scaffold(
      appBar: const FinatiolAppBar(title: Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Perfil ──────────────────────────────────────────────────
          _SectionHeader(label: 'Perfil'),
          _ProfileTile(
            username: username,
            roles: roles,
            tenantId: tenantId,
          ),

          if (isAdmin) ...[
            const Divider(height: 32),
            _SectionHeader(label: 'Administración'),
            ListTile(
              leading: const Icon(Icons.query_stats_outlined),
              title: const Text('Estadísticas'),
              subtitle: const Text('Resumen general del sistema para administradores'),
              onTap: () => context.push('/configuracion/estadisticas'),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Catálogos'),
              subtitle: const Text('Tenants, módulos, permisos y roles'),
              onTap: () => context.push('/configuracion/catalogos'),
            ),
          ],

          const Divider(height: 32),

          // ── Apariencia ──────────────────────────────────────────────
          _SectionHeader(label: 'Apariencia'),
          _ThemeSelector(current: themeMode),

          const Divider(height: 32),

          // ── Acerca de ───────────────────────────────────────────────
          _SectionHeader(label: 'Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Aplicación'),
            subtitle: const Text('Finatiol'),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0'),
          ),

          const Divider(height: 32),

          // ── Sesión ──────────────────────────────────────────────────
          _SectionHeader(label: 'Sesión'),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade600),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red.shade600),
            ),
            onTap: () => _confirmarLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String username;
  final List<String> roles;
  final String tenantId;

  const _ProfileTile({
    required this.username,
    required this.roles,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inicial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              inicial,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (tenantId.isNotEmpty && tenantId != '—')
                  Text(
                    tenantId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                if (roles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: roles
                        .map((r) => _SmallChip(label: r))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;

  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final ThemeMode current;

  const _ThemeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ThemeOption(
          icon: Icons.light_mode_outlined,
          label: 'Claro',
          selected: current == ThemeMode.light,
          onTap: () => ref.read(themeModeProvider.notifier).state =
              ThemeMode.light,
        ),
        _ThemeOption(
          icon: Icons.dark_mode_outlined,
          label: 'Oscuro',
          selected: current == ThemeMode.dark,
          onTap: () => ref.read(themeModeProvider.notifier).state =
              ThemeMode.dark,
        ),
        _ThemeOption(
          icon: Icons.brightness_auto_outlined,
          label: 'Sistema',
          selected: current == ThemeMode.system,
          onTap: () => ref.read(themeModeProvider.notifier).state =
              ThemeMode.system,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : null,
      ),
      title: Text(
        label,
        style: selected
            ? TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : null,
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked,
              color: Colors.transparent),
      onTap: onTap,
    );
  }
}
