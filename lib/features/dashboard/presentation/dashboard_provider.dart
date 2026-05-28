import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../caja_ahorro/domain/ahorro_model.dart';
import '../../caja_ahorro/presentation/ahorro_provider.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardStatsProvider = FutureProvider<DashboardStats>(
  (ref) => ref.watch(dashboardRepositoryProvider).getStats(),
);

final customerSavingsDashboardProvider = FutureProvider<AhorroDashboard>(
  (ref) => ref.watch(ahorroRepositoryProvider).getMiDashboard(),
);
