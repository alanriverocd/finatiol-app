import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../caja_ahorro/domain/ahorro_model.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../../../shared/utils/format_utils.dart';
import '../domain/dashboard_models.dart';
import 'dashboard_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ahorroAsync = ref.watch(customerSavingsDashboardProvider);
    final authState = ref.watch(loginProvider);
    final storedAuthAsync = ref.watch(storedAuthProvider);
    final memoryAuth = authState.auth;
    final storedAuth = storedAuthAsync.value;
    final auth = (memoryAuth != null && (memoryAuth.roles.isNotEmpty || memoryAuth.permisos.isNotEmpty || memoryAuth.username.trim().isNotEmpty))
      ? memoryAuth
      : storedAuth;
    final roles = auth?.roles.map((role) => role.toUpperCase()).toSet() ?? <String>{};
    final permisos = auth?.permisos.map((permiso) => permiso.toUpperCase()).toSet() ?? <String>{};
    final usernameUpper = (auth?.username ?? '').toUpperCase();
    final isAdmin =
      roles.any((role) => role == 'ADMIN' || role == 'ROLE_ADMIN' || role.contains('ADMIN')) ||
      permisos.any((permiso) => permiso.contains('ADMIN') || permiso.contains('CATALOGO') || permiso.contains('MODULO') || permiso.contains('ROL')) ||
      usernameUpper == 'ADMIN';
    final isSavingsCustomer = !isAdmin && (roles.contains('CLIENTE') || roles.contains('AHORRO_CLIENTE'));

    return Scaffold(
      appBar: FinatiolAppBar(
        includeBackOrHomeLeading: false,
        includeHomeAction: false,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(loginProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: _AdaptiveDrawer(
        isCustomer: isSavingsCustomer,
        isAdmin: isAdmin,
      ),
      body: statsAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => ahorroAsync.when(
          loading: () => const _DashboardSkeleton(),
          error: (ahorroError, stackTrace) => _ErrorView(
            message: 'No se pudieron cargar los datos',
            onRetry: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(customerSavingsDashboardProvider);
            },
          ),
          data: (dashboard) => _CustomerDashboardContent(dashboard: dashboard),
        ),
        data: (stats) {
          final savingsDashboard = ahorroAsync.valueOrNull;
          return _DashboardContent(
            stats: stats,
            savingsDashboard: savingsDashboard,
            onRefresh: () async {
            await ref.refresh(dashboardStatsProvider.future).catchError((_) => stats);
            final savings = savingsDashboard;
            if (savings != null) {
              await ref.refresh(customerSavingsDashboardProvider.future).catchError((_) => savings);
            }
            },
          );
        },
      ),
    );
  }
}

class _CustomerDashboardContent extends StatelessWidget {
  const _CustomerDashboardContent({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final cliente = dashboard.cliente;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF103D7A), Color(0xFF1B5FB7), Color(0xFF3E8DF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente?.nombre ?? 'Cliente Finatiol',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  cliente?.email ?? 'Portal de caja de ahorro',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _CustomerMetric(
                      label: 'Saldo acumulado',
                      value: FormatUtils.currency(dashboard.saldoTotal),
                    ),
                    _CustomerMetric(
                      label: 'Cuentas activas',
                      value: '${dashboard.cuentas.length}',
                    ),
                    _CustomerMetric(
                      label: 'Semanas pendientes',
                      value: '${dashboard.semanasPendientes.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (dashboard.semanasPendientes.isNotEmpty)
            Card(
              color: const Color(0xFFFFF5E4),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagos semanales pendientes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('A partir del martes se notifican automáticamente las semanas vencidas.'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dashboard.semanasPendientes
                          .map((semana) => Chip(label: Text('Semana ${semana.numeroSemana}')))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Tus cuentas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...dashboard.cuentas.map(
            (cuenta) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.savings_outlined)),
                  title: Text('Cuenta #${cuenta.id}'),
                  subtitle: Text('Saldo disponible ${FormatUtils.currency(cuenta.saldo)}'),
                  trailing: FilledButton.tonal(
                    onPressed: () => context.go('/ahorros/detalle/${cuenta.id}'),
                    child: const Text('Ver detalle'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Movimientos recientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (dashboard.movimientosRecientes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Aún no hay movimientos registrados.'),
              ),
            )
          else
            ...dashboard.movimientosRecientes.map(
              (movimiento) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CustomerMovementTile(movimiento: movimiento),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerMetric extends StatelessWidget {
  const _CustomerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CustomerMovementTile extends StatelessWidget {
  const _CustomerMovementTile({required this.movimiento});

  final MovimientoAhorro movimiento;

  @override
  Widget build(BuildContext context) {
    final isDeposito = movimiento.tipo == 'DEPOSITO' || movimiento.tipo == 'INTERES';
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isDeposito ? Colors.green : Colors.orange).withValues(alpha: 0.14),
          child: Icon(
            isDeposito ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isDeposito ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        title: Text(movimiento.referencia ?? movimiento.tipo),
        subtitle: Text(movimiento.fecha),
        trailing: Text(
          '${isDeposito ? '+' : '-'}${FormatUtils.currency(movimiento.monto)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDeposito ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
      ),
    );
  }
}

// --- Contenido principal ---

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats, required this.onRefresh, this.savingsDashboard});

  final DashboardStats stats;
  final AhorroDashboard? savingsDashboard;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BusinessSummary(stats: stats),
          const SizedBox(height: 20),

          // Fila de KPIs
          _KpiRow(stats: stats),
          const SizedBox(height: 20),

          // Balance
          _BalanceCard(stats: stats),
          const SizedBox(height: 20),

          // Gráfica de barras de ventas
          _SalesChart(stats: stats),

          if (savingsDashboard != null) ...[
            const SizedBox(height: 20),
            _SavingsSummaryCard(dashboard: savingsDashboard!),
            const SizedBox(height: 20),
            _SavingsCharts(dashboard: savingsDashboard!),
          ],
        ],
      ),
    );
  }
}

class _BusinessSummary extends StatelessWidget {
  const _BusinessSummary({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final balance = stats.balance;
    final balancePositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen general',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Indicadores principales, tendencias y estado financiero.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryBadge(label: 'Ventas', value: stats.totalVentas.toString()),
              _SummaryBadge(label: 'Productos', value: stats.totalProductos.toString()),
              _SummaryBadge(label: 'Usuarios', value: stats.totalUsuarios.toString()),
              _SummaryBadge(label: 'Balance', value: FormatUtils.currency(balance), accent: balancePositive ? Colors.greenAccent : Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent ?? Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// --- KPI Cards ---

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _KpiCard(
          label: 'Ventas',
          value: stats.totalVentas.toString(),
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFF1565C0),
        ),
        _KpiCard(
          label: 'Productos',
          value: stats.totalProductos.toString(),
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF00897B),
        ),
        _KpiCard(
          label: 'Ingresos',
          value: FormatUtils.currency(stats.ingresos),
          icon: Icons.trending_up,
          color: const Color(0xFF2E7D32),
        ),
        _KpiCard(
          label: 'Usuarios',
          value: stats.totalUsuarios.toString(),
          icon: Icons.people_outline,
          color: const Color(0xFF6A1B9A),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Balance Card ---

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final isPositive = stats.balance >= 0;
    return Card(
      color: isPositive
          ? const Color(0xFF1B5E20).withValues(alpha: 0.05)
          : const Color(0xFFB71C1C).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance financiero',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BalanceItem(
                    label: 'Ingresos',
                    amount: stats.ingresos,
                    color: Colors.green.shade700),
                _BalanceItem(
                    label: 'Egresos',
                    amount: stats.egresos,
                    color: Colors.red.shade700),
                _BalanceItem(
                    label: 'Balance',
                    amount: stats.balance,
                    color: isPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    isBold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem(
      {required this.label,
      required this.amount,
      required this.color,
      this.isBold = false});

  final String label;
  final double amount;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          FormatUtils.currency(amount),
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// --- Gráfica de ventas ---

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    // Datos demo si no hay datos del servidor
    final data = stats.ventasPorMes.isEmpty
        ? _demoData()
        : stats.ventasPorMes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ventas por mes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: data.map((e) => e.total).reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.total,
                          color: const Color(0xFF1565C0),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(data[idx].mes,
                                style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<VentaMes> _demoData() => [
        const VentaMes(mes: 'Ene', total: 12000),
        const VentaMes(mes: 'Feb', total: 18500),
        const VentaMes(mes: 'Mar', total: 15200),
        const VentaMes(mes: 'Abr', total: 22000),
        const VentaMes(mes: 'May', total: 19800),
        const VentaMes(mes: 'Jun', total: 27300),
      ];
}

// --- Drawer de navegación ---

class _AdaptiveDrawer extends StatelessWidget {
  const _AdaptiveDrawer({required this.isCustomer, required this.isAdmin});

  final bool isCustomer;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text('FINATIOL',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(isCustomer && !isAdmin ? 'Portal comercial' : 'Plataforma empresarial',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const _DrawerItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/dashboard',
          ),
          if (!isCustomer || isAdmin) ...[
            const _DrawerItem(
              icon: Icons.inventory_2_outlined,
              label: 'Productos',
              route: '/productos',
            ),
            const _DrawerItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Ventas',
              route: '/ventas',
            ),
            const _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Finanzas',
              route: '/finanzas',
            ),
          ],
          _DrawerItem(
            icon: Icons.savings_outlined,
            label: 'Caja de Ahorro',
            route: '/ahorros',
          ),
          const _DrawerItem(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Mis pedidos',
            route: '/mis-solicitudes',
          ),
          if (isAdmin)
            const _DrawerItem(
              icon: Icons.manage_accounts_outlined,
              label: 'Pedidos admin',
              route: '/solicitudes-admin',
            ),
          const _DrawerItem(
            icon: Icons.smart_toy_outlined,
            label: 'OpenAI Man',
            route: '/openai-man',
          ),
          if (!isCustomer || isAdmin)
            const _DrawerItem(
              icon: Icons.people_outline,
              label: 'Usuarios',
              route: '/usuarios',
            ),
          const Divider(),
          if (!isCustomer || isAdmin)
            const _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              route: '/configuracion',
            ),
          if (isAdmin)
            const _DrawerItem(
              icon: Icons.query_stats_outlined,
              label: 'Estadísticas',
              route: '/configuracion/estadisticas',
            ),
          if (isAdmin)
            const _DrawerItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Catálogos y módulos',
              route: '/configuracion/catalogos',
            ),
        ],
      ),
    );
  }
}

class _SavingsSummaryCard extends StatelessWidget {
  const _SavingsSummaryCard({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caja de ahorro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              dashboard.cliente?.nombre ?? 'Resumen de ahorro del usuario',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SavingsBadge(label: 'Saldo total', value: FormatUtils.currency(dashboard.saldoTotal), icon: Icons.account_balance_wallet_outlined),
                _SavingsBadge(label: 'Cuentas activas', value: dashboard.cuentas.length.toString(), icon: Icons.credit_card_outlined),
                _SavingsBadge(label: 'Pendientes', value: dashboard.semanasPendientes.length.toString(), icon: Icons.event_note_outlined),
                _SavingsBadge(label: 'Movimientos', value: dashboard.movimientosRecientes.length.toString(), icon: Icons.swap_horiz_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsCharts extends StatelessWidget {
  const _SavingsCharts({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SavingsBalanceChart(dashboard: dashboard),
        const SizedBox(height: 16),
        _SavingsTrendChart(dashboard: dashboard),
        const SizedBox(height: 16),
        _SavingsActivityChart(dashboard: dashboard),
      ],
    );
  }
}

class _SavingsTrendPoint {
  const _SavingsTrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _SavingsBalanceChart extends StatelessWidget {
  const _SavingsBalanceChart({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final cuentas = dashboard.cuentas;
    final maxY = cuentas.isEmpty
        ? 1000.0
        : cuentas.map((e) => e.saldo).reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo por cuenta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: cuentas.isEmpty
                  ? const Center(child: Text('No hay cuentas para graficar.'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY,
                        barGroups: cuentas.asMap().entries.map((entry) {
                          final cuenta = entry.value;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: cuenta.saldo,
                                width: 18,
                                color: const Color(0xFF1B5FB7),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= cuentas.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('C${cuentas[idx].id}', style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsTrendChart extends StatelessWidget {
  const _SavingsTrendChart({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final points = _buildMonthlyTrend(dashboard.movimientosRecientes);
    final maxY = points.isEmpty
        ? 1000.0
        : points.map((point) => point.value).reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tendencia mensual de ahorro', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Acumulado mensual calculado a partir de los movimientos recientes.'),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: points.isEmpty
                  ? const Center(child: Text('No hay datos suficientes para graficar la tendencia.'))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(points[idx].label, style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.value)).toList(),
                            isCurved: true,
                            color: const Color(0xFF0F9D58),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF0F9D58).withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SavingsTrendPoint> _buildMonthlyTrend(List<MovimientoAhorro> movimientos) {
    final totals = <String, double>{};
    for (final movimiento in movimientos) {
      final parsed = DateTime.tryParse(movimiento.fecha);
      if (parsed == null) continue;
      final key = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}';
      final isIngreso = movimiento.tipo == 'DEPOSITO' || movimiento.tipo == 'INTERES';
      totals[key] = (totals[key] ?? 0) + (isIngreso ? movimiento.monto : -movimiento.monto);
    }

    final keys = totals.keys.toList()..sort();
    double running = 0;
    return keys.map((key) {
      running += totals[key] ?? 0;
      return _SavingsTrendPoint(
        label: _monthLabel(key),
        value: running < 0 ? 0 : running,
      );
    }).toList();
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final month = int.tryParse(parts[1]) ?? 0;
    const labels = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    if (month < 1 || month > 12) return key;
    return labels[month - 1];
  }
}

class _SavingsActivityChart extends StatelessWidget {
  const _SavingsActivityChart({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final deposits = dashboard.movimientosRecientes.where((m) => m.tipo == 'DEPOSITO' || m.tipo == 'INTERES').length.toDouble();
    final withdrawals = dashboard.movimientosRecientes.where((m) => m.tipo != 'DEPOSITO' && m.tipo != 'INTERES').length.toDouble();
    final total = deposits + withdrawals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad reciente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Distribución de movimientos de la caja de ahorro.'),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: total == 0
                  ? const Center(child: Text('Sin movimientos recientes para mostrar.'))
                  : PieChart(
                      PieChartData(
                        centerSpaceRadius: 42,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(
                            value: deposits,
                            color: const Color(0xFF2E7D32),
                            title: 'Depósitos',
                            radius: 70,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          PieChartSectionData(
                            value: withdrawals,
                            color: const Color(0xFFE53935),
                            title: 'Retiros',
                            radius: 70,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem(
      {required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    final isActive = current.startsWith(route);
    return ListTile(
      leading: Icon(icon,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700),
      title: Text(label,
          style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      selected: isActive,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}

// --- Skeleton loading ---

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Error view ---

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message,
              style:
                  TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
