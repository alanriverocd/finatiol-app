import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../productos/domain/producto_model.dart';
import '../../productos/presentation/productos_provider.dart';

final marketingProductsProvider = FutureProvider<List<Producto>>((ref) async {
  return ref.read(productoRepositoryProvider).listarActivos();
});

class ProductShowcaseScreen extends ConsumerWidget {
  const ProductShowcaseScreen({super.key});

  static const _fallbackProducts = <_PromoProduct>[
    _PromoProduct(
      name: 'Cuenta Digital Plus',
      tag: 'Mas solicitado',
      headline: 'Rendimientos diarios y control total desde app',
      description:
          'Ideal para clientes que buscan liquidez inmediata con beneficios premium.',
      monthlyFrom: 'Desde 0 comision mensual',
      benefits: [
        'Transferencias SPEI 24/7',
        'Rendimiento diario sobre saldo',
        'Tarjeta virtual y alertas instantaneas',
      ],
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFF174A92),
    ),
    _PromoProduct(
      name: 'Crédito Impulso PyME',
      tag: 'Para negocio',
      headline: 'Capital para crecer con tasa competitiva',
      description:
          'Financia inventario, nómina o expansión con aprobación ágil.',
      monthlyFrom: 'Respuesta inicial en 24h habiles',
      benefits: [
        'Montos escalables segun historial',
        'Pagos semanales o quincenales',
        'Acompañamiento comercial especializado',
      ],
      icon: Icons.storefront_outlined,
      accent: Color(0xFF0E7A5F),
    ),
    _PromoProduct(
      name: 'Caja Ahorro Familiar',
      tag: 'Meta familiar',
      headline: 'Ahorro semanal con metas y alertas inteligentes',
      description:
          'Programa aportaciones y mantén seguimiento de progreso familiar.',
      monthlyFrom: 'Plan desde 100 semanales',
      benefits: [
        'Metas por integrante',
        'Recordatorios automaticos',
        'Historial claro de aportaciones',
      ],
      icon: Icons.savings_outlined,
      accent: Color(0xFF9A6A13),
    ),
  ];

  List<_PromoProduct> _toMarketingProducts(List<Producto> productos) {
    final ordered = [...productos]
      ..sort((a, b) {
        final scoreB = _scoreProduct(b);
        final scoreA = _scoreProduct(a);
        return scoreB.compareTo(scoreA);
      });

    return ordered.asMap().entries.map((entry) {
      final index = entry.key;
      final producto = entry.value;
      final accent = _accentForName(producto.nombre);
      final descripcion = (producto.descripcion ?? '').trim();
      final headline = descripcion.isEmpty
          ? 'Producto financiero para impulsar tus objetivos.'
          : descripcion.split('.').first.trim();

      final benefits = <String>[
        'Disponibilidad actual: ${producto.stock} unidades',
        'Seguimiento comercial por correo y telefono',
        'Solicitud en linea con respuesta rapida',
      ];

      return _PromoProduct(
        name: producto.nombre,
        tag: index == 0
          ? 'Top recomendado'
          : producto.stock > 20
            ? 'Alta demanda'
            : 'Disponible',
        headline: headline,
        description: descripcion.isEmpty
            ? 'Consulta detalles con un asesor especializado de FINATIOL.'
            : descripcion,
        monthlyFrom: 'Desde ${producto.precio.toStringAsFixed(2)}',
        benefits: benefits,
        icon: _iconForName(producto.nombre),
        accent: accent,
        imageUrl: producto.imagenUrl,
        isTopRecommended: index < 2,
      );
    }).toList();
  }

  double _scoreProduct(Producto p) {
    // Priorizacion comercial: disponibilidad + ticket de precio.
    return (p.stock * 1.0) + (p.precio * 0.05);
  }

  Color _accentForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('credito') || lower.contains('prestamo')) {
      return const Color(0xFF0E7A5F);
    }
    if (lower.contains('ahorro')) {
      return const Color(0xFF9A6A13);
    }
    return const Color(0xFF174A92);
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('credito') || lower.contains('prestamo')) {
      return Icons.storefront_outlined;
    }
    if (lower.contains('ahorro')) {
      return Icons.savings_outlined;
    }
    return Icons.account_balance_wallet_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(marketingProductsProvider);

    final products = productsAsync.when(
      data: (items) {
        if (items.isEmpty) return _fallbackProducts;
        return _toMarketingProducts(items);
      },
      loading: () => _fallbackProducts,
      error: (error, stackTrace) => _fallbackProducts,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFEAF1FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2C55), Color(0xFF1E5DAE), Color(0xFF3A86EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Productos destacados',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Impulsa tus metas con soluciones financieras diseñadas para vender más y ahorrar mejor.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Explora, compara y elige. Para contratar, inicia sesión o crea tu registro en segundos.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _TrustPill(text: '+15k clientes activos'),
                        _TrustPill(text: '98% renovacion anual'),
                        _TrustPill(text: 'Atencion comercial dedicada'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/acceso'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text('Iniciar sesión'),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.go('/registro'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D2C55),
                          ),
                          icon: const Icon(Icons.app_registration_outlined),
                          label: const Text('Registrarme'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Elige tu producto ideal',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF11325E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Compara beneficios y da el siguiente paso cuando estes listo.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PromoCard(product: product),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.product});

  final _PromoProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: product.isTopRecommended
            ? BorderSide(color: product.accent.withValues(alpha: 0.42), width: 1.4)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.isTopRecommended)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: product.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: product.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Recomendado por conversion',
                      style: TextStyle(
                        color: product.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: product.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(product.icon, color: product.accent),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: product.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(product.icon, color: product.accent),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF112D54),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.tag,
                          style: TextStyle(
                            color: product.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.headline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              product.monthlyFrom,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: product.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...product.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: product.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  final uri = Uri(
                    path: '/acceso',
                    queryParameters: {'producto': product.name},
                  );
                  context.go(uri.toString());
                },
                style: FilledButton.styleFrom(backgroundColor: product.accent),
                icon: const Icon(Icons.shopping_cart_checkout_outlined),
                label: const Text('Quiero este producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PromoProduct {
  const _PromoProduct({
    required this.name,
    required this.tag,
    required this.headline,
    required this.description,
    required this.monthlyFrom,
    required this.benefits,
    required this.icon,
    required this.accent,
    this.imageUrl,
    this.isTopRecommended = false,
  });

  final String name;
  final String tag;
  final String headline;
  final String description;
  final String monthlyFrom;
  final List<String> benefits;
  final IconData icon;
  final Color accent;
  final String? imageUrl;
  final bool isTopRecommended;
}
