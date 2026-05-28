import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/finatiol_app_bar.dart';
import '../domain/ahorro_model.dart';
import 'cliente_ahorro_form_screen.dart';
import 'ahorro_provider.dart';

class AhorroScreen extends ConsumerStatefulWidget {
  const AhorroScreen({super.key});

  @override
  ConsumerState<AhorroScreen> createState() => _AhorroScreenState();
}

class _AhorroScreenState extends ConsumerState<AhorroScreen> {
  AhorroNotifier get _ahorroNotifier => ref.read(ahorroProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _ahorroNotifier.cargarInicio());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ahorroProvider);

    ref.listen(ahorroProvider, (_, next) {
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
                _ahorroNotifier.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: FinatiolAppBar(
        title: const Text('Caja de Ahorro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(ahorroProvider.notifier).cargarInicio(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(ahorroProvider.notifier).cargarInicio(),
              child: state.isAdmin
                  ? _AdminView(state: state)
                  : _ClienteView(state: state),
            ),
      floatingActionButton: state.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openClienteForm(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo cliente'),
            )
          : state.cuentas.isNotEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _abrirCuenta(context),
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text('Abrir cuenta'),
                ),
    );
  }

  Future<void> _openClienteForm(BuildContext context, {ClienteAhorro? cliente}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClienteAhorroFormScreen(cliente: cliente),
      ),
    );
    if (mounted) {
      await ref.read(ahorroProvider.notifier).cargarInicio();
    }
  }

  void _abrirCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir cuenta de ahorro'),
        content: const Text(
            '¿Deseas abrir una nueva cuenta de ahorro?\n'
            'Se creará con saldo inicial de \$0.00.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(ahorroProvider.notifier).abrirCuenta();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cuenta abierta exitosamente')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _ClienteView extends StatelessWidget {
  const _ClienteView({required this.state});

  final AhorroState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    if (dashboard == null && state.cuentas.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          _WaitingInvitationCard(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroAhorroCard(dashboard: dashboard, cuentas: state.cuentas),
        const SizedBox(height: 16),
        if (dashboard != null) ...[
          _ClienteStatsPanel(dashboard: dashboard),
          const SizedBox(height: 16),
        ],
        if (dashboard != null && dashboard.semanasPendientes.isNotEmpty) ...[
          _PendientesCard(semanas: dashboard.semanasPendientes),
          const SizedBox(height: 16),
        ],
        if (state.cuentas.isEmpty)
          const _WaitingInvitationCard()
        else ...[
          Text('Tus cuentas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...state.cuentas.map(
            (cuenta) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CuentaCard(
                cuenta: cuenta,
                onTap: () => context.push('/ahorros/detalle/${cuenta.id}'),
              ),
            ),
          ),
        ],
        if (dashboard != null && dashboard.movimientosRecientes.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Actividad reciente', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...dashboard.movimientosRecientes.map(
            (movimiento) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MovimientoResumenCard(movimiento: movimiento),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClienteStatsPanel extends StatelessWidget {
  const _ClienteStatsPanel({required this.dashboard});

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
              'Estadísticas de tu ahorro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo, cuentas activas, pendientes y actividad reciente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SavingsStatChip(label: 'Saldo total', value: FormatUtils.currency(dashboard.saldoTotal), icon: Icons.account_balance_wallet_outlined),
                _SavingsStatChip(label: 'Cuentas activas', value: dashboard.cuentas.length.toString(), icon: Icons.credit_card_outlined),
                _SavingsStatChip(label: 'Pendientes', value: dashboard.semanasPendientes.length.toString(), icon: Icons.event_note_outlined),
                _SavingsStatChip(label: 'Movimientos', value: dashboard.movimientosRecientes.length.toString(), icon: Icons.swap_horiz_rounded),
              ],
            ),
            const SizedBox(height: 16),
            _SavingsTrendChart(dashboard: dashboard),
            const SizedBox(height: 16),
            _SavingsActivityChart(dashboard: dashboard),
          ],
        ),
      ),
    );
  }
}

class _AdminStatsPanel extends StatelessWidget {
  const _AdminStatsPanel({required this.state});

  final AhorroState state;

  @override
  Widget build(BuildContext context) {
    final activeClients = state.clientes.where((cliente) => cliente.activo).length;
    final inactiveClients = state.clientes.length - activeClients;
    final topClients = [...state.clientes]..sort((a, b) => b.saldoTotal.compareTo(a.saldoTotal));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas administrativas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Clientes, cuentas y concentración de saldos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SavingsStatChip(label: 'Clientes activos', value: activeClients.toString(), icon: Icons.verified_user_outlined),
                _SavingsStatChip(label: 'Clientes inactivos', value: inactiveClients.toString(), icon: Icons.person_off_outlined),
                _SavingsStatChip(label: 'Cuentas activas', value: state.cuentasAdmin.length.toString(), icon: Icons.savings_outlined),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ClientBalanceChart(topClients: topClients.take(3).toList())),
                const SizedBox(width: 12),
                Expanded(child: _ClientStatusChart(activeClients: activeClients, inactiveClients: inactiveClients)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsStatChip extends StatelessWidget {
  const _SavingsStatChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
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

class _SavingsTrendPoint {
  const _SavingsTrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _SavingsTrendChart extends StatelessWidget {
  const _SavingsTrendChart({required this.dashboard});

  final AhorroDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final points = _buildMonthlyTrend(dashboard.movimientosRecientes);
    final maxY = points.isEmpty ? 1000.0 : points.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tendencia mensual de ahorro', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: points.isEmpty
              ? const Center(child: Text('No hay datos suficientes para mostrar la tendencia.'))
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
                        belowBarData: BarAreaData(show: true, color: const Color(0xFF0F9D58).withValues(alpha: 0.12)),
                      ),
                    ],
                  ),
                ),
        ),
      ],
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
      return _SavingsTrendPoint(label: _monthLabel(key), value: running < 0 ? 0 : running);
    }).toList();
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final month = int.tryParse(parts[1]) ?? 0;
    const labels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actividad reciente', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
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
    );
  }
}

class _ClientBalanceChart extends StatelessWidget {
  const _ClientBalanceChart({required this.topClients});

  final List<ClienteAhorro> topClients;

  @override
  Widget build(BuildContext context) {
    final maxY = topClients.isEmpty ? 1000.0 : topClients.map((e) => e.saldoTotal).reduce((a, b) => a > b ? a : b) * 1.25;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top saldos por cliente', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: topClients.isEmpty
                  ? const Center(child: Text('No hay clientes para graficar.'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY,
                        barGroups: topClients.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.saldoTotal,
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
                                if (idx < 0 || idx >= topClients.length) return const SizedBox.shrink();
                                final name = topClients[idx].nombre;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(name.isEmpty ? '@${topClients[idx].username}' : name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
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

class _ClientStatusChart extends StatelessWidget {
  const _ClientStatusChart({required this.activeClients, required this.inactiveClients});

  final int activeClients;
  final int inactiveClients;

  @override
  Widget build(BuildContext context) {
    final total = activeClients + inactiveClients;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado de clientes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: total == 0
                  ? const Center(child: Text('Sin datos para mostrar.'))
                  : PieChart(
                      PieChartData(
                        centerSpaceRadius: 42,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(
                            value: activeClients.toDouble(),
                            color: const Color(0xFF2E7D32),
                            title: 'Activos',
                            radius: 72,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          PieChartSectionData(
                            value: inactiveClients.toDouble(),
                            color: const Color(0xFFE53935),
                            title: 'Inactivos',
                            radius: 72,
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

class _AdminView extends StatefulWidget {
  const _AdminView({required this.state});

  final AhorroState state;

  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView> {
  String? _selectedUsername;

  @override
  void didUpdateWidget(covariant _AdminView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final usernames = widget.state.cuentasAdmin.map((c) => c.username).toSet();
    if (_selectedUsername != null && !usernames.contains(_selectedUsername)) {
      _selectedUsername = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final totalSaldo = state.clientes.fold<double>(0, (sum, item) => sum + item.saldoTotal);
    final cuentasFiltradas = _selectedUsername == null
        ? state.cuentasAdmin
      : state.cuentasAdmin.where((c) => c.username == _selectedUsername).toList();

    return DefaultTabController(
      length: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E3566), Color(0xFF1F6ED4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Panel bancario de ahorro',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const Text(
                  'Administra expedientes, altas y seguimiento semanal',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _AdminKpi(label: 'Clientes', value: '${state.clientes.length}'),
                    _AdminKpi(label: 'Cuentas activas', value: '${state.cuentasAdmin.length}'),
                    _AdminKpi(label: 'Saldo administrado', value: FormatUtils.currency(totalSaldo)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AdminStatsPanel(state: state),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Clientes'),
                Tab(text: 'Cuentas'),
              ],
            ),
          ),
          SizedBox(
            height: 720,
            child: TabBarView(
              children: [
                state.clientes.isEmpty
                    ? const _EmptyAdminClients()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16),
                        itemCount: state.clientes.length,
                        itemBuilder: (context, index) {
                          final cliente = state.clientes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ClienteAdminCard(
                              cliente: cliente,
                              onViewAccounts: () {
                                setState(() => _selectedUsername = cliente.username);
                                DefaultTabController.of(context).animateTo(1);
                              },
                            ),
                          );
                        },
                      ),
                state.cuentasAdmin.isEmpty
                    ? const _EmptyAdminAccounts()
                    : Column(
                        children: [
                          if (_selectedUsername != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mostrando cuentas de @$_selectedUsername',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => setState(() => _selectedUsername = null),
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Mostrar todas'),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Selecciona un cliente para ver solo sus cuentas.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          Expanded(
                            child: cuentasFiltradas.isEmpty
                                ? const Center(
                                    child: Text('El cliente seleccionado no tiene cuentas activas.'),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 8),
                                    itemCount: cuentasFiltradas.length,
                                    itemBuilder: (context, index) {
                                      final cuenta = cuentasFiltradas[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: _CuentaCard(
                                          cuenta: cuenta,
                                          onTap: () => context.push('/ahorros/detalle/${cuenta.id}'),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingInvitationCard extends StatelessWidget {
  const _WaitingInvitationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Tu acceso ya está activo, pero aún no hay una cuenta de ahorro asignada.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Solicita al administrador que complete tu alta para consultar saldos, semanas y movimientos desde este panel.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAhorroCard extends StatelessWidget {
  const _HeroAhorroCard({required this.dashboard, required this.cuentas});

  final AhorroDashboard? dashboard;
  final List<CuentaAhorro> cuentas;

  @override
  Widget build(BuildContext context) {
    final cliente = dashboard?.cliente;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C2D57), Color(0xFF245FAF), Color(0xFF3E8DF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cliente?.nombre ?? 'Portal de ahorro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            cliente?.email ?? 'Consulta tu saldo, pagos semanales y actividad reciente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Saldo total',
                  value: FormatUtils.currency(dashboard?.saldoTotal ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Cuentas activas',
                  value: '${cuentas.where((c) => c.activa).length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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

class _PendientesCard extends StatelessWidget {
  const _PendientesCard({required this.semanas});

  final List<SemanaAhorro> semanas;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF6E9),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text('Pagos semanales pendientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Desde el martes se marcan como vencidas las semanas sin cubrir al cierre del lunes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: semanas
                  .map((semana) => Chip(label: Text('Semana ${semana.numeroSemana}')))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovimientoResumenCard extends StatelessWidget {
  const _MovimientoResumenCard({required this.movimiento});

  final MovimientoAhorro movimiento;

  @override
  Widget build(BuildContext context) {
    final isDeposito = movimiento.tipo == 'DEPOSITO' || movimiento.tipo == 'INTERES';
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isDeposito ? Colors.green : Colors.orange).withValues(alpha: 0.12),
          child: Icon(
            isDeposito ? Icons.south_west : Icons.north_east,
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

class _AdminKpi extends StatelessWidget {
  const _AdminKpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ClienteAdminCard extends ConsumerWidget {
  const _ClienteAdminCard({required this.cliente, required this.onViewAccounts});

  final ClienteAhorro cliente;
  final VoidCallback onViewAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(cliente.nombre.isEmpty ? '?' : cliente.nombre.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.nombre,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('@${cliente.username} • ${cliente.email}'),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClienteAhorroFormScreen(cliente: cliente),
                      ),
                    );
                    if (context.mounted) {
                      await ref.read(ahorroProvider.notifier).cargarInicio();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: 'Saldo', value: FormatUtils.currency(cliente.saldoTotal)),
                _MetaChip(label: 'Cuentas', value: '${cliente.cuentasActivas}'),
                if ((cliente.telefono ?? '').isNotEmpty)
                  _MetaChip(label: 'Tel.', value: cliente.telefono!),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onViewAccounts,
                icon: const Icon(Icons.savings_outlined, size: 18),
                label: const Text('Ver cuentas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _EmptyAdminClients extends StatelessWidget {
  const _EmptyAdminClients();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aún no hay clientes registrados en caja de ahorro.'),
    );
  }
}

class _EmptyAdminAccounts extends StatelessWidget {
  const _EmptyAdminAccounts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aún no hay cuentas de ahorro activas.'),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de cuenta
// ---------------------------------------------------------------------------
class _CuentaCard extends StatelessWidget {
  const _CuentaCard({required this.cuenta, required this.onTap});
  final CuentaAhorro cuenta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.savings_outlined,
              color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(
          'Cuenta #${cuenta.id}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Apertura: ${cuenta.fechaApertura}',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              FormatUtils.currency(cuenta.saldo),
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cuenta.activa
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cuenta.activa ? 'Activa' : 'Inactiva',
                style: TextStyle(
                    fontSize: 11,
                    color: cuenta.activa
                        ? Colors.green.shade700
                        : Colors.red.shade700),
              ),
            ),
          ],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
