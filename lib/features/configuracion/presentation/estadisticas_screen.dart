import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../../dashboard/domain/dashboard_models.dart';
import '../../dashboard/presentation/dashboard_provider.dart';

class EstadisticasScreen extends ConsumerWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: const FinatiolAppBar(title: Text('Estadísticas')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No fue posible cargar estadísticas\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewCard(stats: stats),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _MetricTile(label: 'Ventas', value: stats.totalVentas.toString(), icon: Icons.shopping_cart_outlined),
                  _MetricTile(label: 'Productos', value: stats.totalProductos.toString(), icon: Icons.inventory_2_outlined),
                  _MetricTile(label: 'Usuarios', value: stats.totalUsuarios.toString(), icon: Icons.people_outline),
                  _MetricTile(label: 'Balance', value: FormatUtils.currency(stats.balance), icon: Icons.account_balance_outlined),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingresos vs egresos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (stats.ingresos > stats.egresos ? stats.ingresos : stats.egresos) * 1.2 + 1,
                            barGroups: [
                              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stats.ingresos, color: Colors.green, width: 18)]),
                              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: stats.egresos, color: Colors.red, width: 18)]),
                              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: stats.balance.abs(), color: Colors.blue, width: 18)]),
                            ],
                            titlesData: const FlTitlesData(show: true),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF103D7A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen general', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              'Vista consolidada de ventas, productos, usuarios y finanzas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}