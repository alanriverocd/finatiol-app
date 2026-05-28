import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/productos/presentation/productos_screen.dart';
import '../../features/ventas/presentation/ventas_screen.dart';
import '../../features/finanzas/presentation/finanzas_screen.dart';
import '../../features/usuarios/presentation/usuarios_screen.dart';
import '../../features/configuracion/presentation/configuracion_screen.dart';
import '../../features/configuracion/presentation/estadisticas_screen.dart';
import '../../features/configuracion/presentation/catalogos_admin_screen.dart';
import '../../features/caja_ahorro/presentation/ahorro_screen.dart';
import '../../features/caja_ahorro/presentation/cuenta_detalle_screen.dart';
import '../../features/caja_ahorro/presentation/deposito_screen.dart';
import '../../features/caja_ahorro/presentation/retiro_screen.dart';
import '../../features/caja_ahorro/presentation/semanas_screen.dart';
import '../../features/marketing/presentation/brand_intro_screen.dart';
import '../../features/marketing/presentation/product_checkout_screen.dart';
import '../../features/marketing/presentation/product_showcase_screen.dart';
import '../../features/solicitudes/presentation/admin_solicitudes_screen.dart';
import '../../features/solicitudes/presentation/mis_solicitudes_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/intro',
    redirect: (context, state) async {
      final isAuthenticated =
          await ref.read(authRepositoryProvider).isAuthenticated();
      final location = state.matchedLocation;
      const publicRoutes = {
        '/intro',
        '/escaparate',
        '/acceso',
        '/login',
        '/registro',
      };

      if (!isAuthenticated && !publicRoutes.contains(location)) {
        final producto = state.uri.queryParameters['producto'];
        if (producto != null && producto.trim().isNotEmpty) {
          return Uri(
            path: '/acceso',
            queryParameters: {'producto': producto},
          ).toString();
        }
        return '/acceso';
      }

      if (isAuthenticated && publicRoutes.contains(location)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/intro',
        builder: (context, state) => const BrandIntroScreen(),
      ),
      GoRoute(
        path: '/escaparate',
        builder: (context, state) => const ProductShowcaseScreen(),
      ),
      GoRoute(
        path: '/acceso',
        builder: (context, state) => LoginScreen(
          productoInteres: state.uri.queryParameters['producto'],
        ),
      ),
      GoRoute(
        path: '/login',
        redirect: (context, state) {
          final query = state.uri.query;
          return query.isEmpty ? '/acceso' : '/acceso?$query';
        },
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) => RegisterScreen(
          productoInteres: state.uri.queryParameters['producto'],
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => ProductCheckoutScreen(
          producto: state.uri.queryParameters['producto'],
        ),
      ),
      GoRoute(
        path: '/mis-solicitudes',
        builder: (context, state) => const MisSolicitudesScreen(),
      ),
      GoRoute(
        path: '/solicitudes-admin',
        builder: (context, state) => const AdminSolicitudesScreen(),
      ),
      GoRoute(
        path: '/productos',
        builder: (context, state) => const ProductosScreen(),
      ),
      // Rutas pendientes de implementar
      GoRoute(
        path: '/ventas',
        builder: (context, state) => const VentasScreen(),
      ),
      GoRoute(
        path: '/finanzas',
        builder: (context, state) => const FinanzasScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuariosScreen(),
      ),
      GoRoute(
        path: '/configuracion',
        builder: (context, state) => const ConfiguracionScreen(),
        routes: [
          GoRoute(
            path: 'estadisticas',
            builder: (context, state) => const EstadisticasScreen(),
          ),
          GoRoute(
            path: 'catalogos',
            builder: (context, state) => const CatalogosAdminScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ahorros',
        builder: (context, state) => const AhorroScreen(),
        routes: [
          GoRoute(
            path: 'detalle/:cuentaId',
            builder: (context, state) => CuentaDetalleScreen(
              cuentaId: int.parse(state.pathParameters['cuentaId']!),
            ),
          ),
          GoRoute(
            path: 'deposito/:cuentaId',
            builder: (context, state) => DepositoScreen(
              cuentaId: int.parse(state.pathParameters['cuentaId']!),
            ),
          ),
          GoRoute(
            path: 'retiro/:cuentaId',
            builder: (context, state) => RetiroScreen(
              cuentaId: int.parse(state.pathParameters['cuentaId']!),
            ),
          ),
          GoRoute(
            path: 'semanas/:cuentaId',
            builder: (context, state) => SemanasScreen(
              cuentaId: int.parse(state.pathParameters['cuentaId']!),
            ),
          ),
        ],
      ),
    ],
  );
});
