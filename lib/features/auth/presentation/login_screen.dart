import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.productoInteres});

  final String? productoInteres;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(loginProvider.notifier)
        .login(_usernameCtrl.text.trim(), _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final theme = Theme.of(context);

    // Navegar al dashboard cuando el login es exitoso
    ref.listen(loginProvider, (_, next) {
      if (!next.isSuccess) return;

      final producto = widget.productoInteres?.trim();
      if (producto != null && producto.isNotEmpty) {
        final uri = Uri(path: '/checkout', queryParameters: {'producto': producto});
        context.go(uri.toString());
      } else {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFE7EEF7), Color(0xFFF9FBFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -10,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF103D7A).withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: -40,
              bottom: 120,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC79A3B).withValues(alpha: 0.12),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          if (MediaQuery.of(context).size.width >= 860)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(36),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0D2C55), Color(0xFF164C93), Color(0xFF2A79D8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const _LoginHeroPanel(),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _FinatiolLogo(theme: theme),
                                    const SizedBox(height: 28),
                                    Text(
                                      'Acceso seguro',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: const Color(0xFF0D2C55),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ingresa para consultar pedidos, catalogo y seguimiento comercial.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (widget.productoInteres != null &&
                                        widget.productoInteres!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F1FF),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                              color: const Color(0xFFC7DAF7)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.sell_outlined,
                                                size: 18, color: Color(0xFF174A92)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Para contratar ${widget.productoInteres}, inicia sesión o regístrate.',
                                                style: const TextStyle(
                                                  color: Color(0xFF174A92),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _usernameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Usuario',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.username],
                                      validator: (v) =>
                                          (v == null || v.isEmpty) ? 'Ingresa tu usuario' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Contraseña',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined),
                                          onPressed: () => setState(
                                              () => _obscurePassword = !_obscurePassword),
                                        ),
                                      ),
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      autofillHints: const [AutofillHints.password],
                                      validator: (v) =>
                                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                                    ),
                                    const SizedBox(height: 14),
                                    if (state.error != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: theme.colorScheme.error, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                state.error!,
                                                style: TextStyle(
                                                  color: theme.colorScheme.error,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    FilledButton(
                                      onPressed: state.isLoading ? null : _submit,
                                      child: state.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Text('Entrar al panel'),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        final uri = Uri(
                                          path: '/registro',
                                          queryParameters:
                                              (widget.productoInteres != null &&
                                                      widget.productoInteres!
                                                          .trim()
                                                          .isNotEmpty)
                                                  ? {
                                                      'producto':
                                                          widget.productoInteres!,
                                                    }
                                                  : null,
                                        );
                                        context.go(uri.toString());
                                      },
                                      icon: const Icon(Icons.app_registration_outlined),
                                      label: const Text('Registrarme para comprar'),
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6EEDC),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified_user_outlined,
                                              color: const Color(0xFF8C6420), size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Acceso protegido con autenticación JWT y control granular de permisos.',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: const Color(0xFF6A4A12),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Center(
                                      child: Text(
                                        'FINATIOL © ${DateTime.now().year}',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinatiolLogo extends StatelessWidget {
  const _FinatiolLogo({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.account_balance,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FINATIOL',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Comercio digital de productos multirubro',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _LoginHeroPanel extends StatelessWidget {
  const _LoginHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Portal comercial interno',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Gestiona ventas de tecnología, línea blanca y más en una sola plataforma empresarial.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Controla catálogo, inventario, pedidos y atención comercial desde un flujo operativo unificado.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const _HeroFeature(
          icon: Icons.inventory_2_outlined,
          title: 'Catálogo multirubro',
          subtitle: 'Administra productos de tecnología, línea blanca, hogar y otras categorías.',
        ),
        const SizedBox(height: 14),
        const _HeroFeature(
          icon: Icons.local_shipping_outlined,
          title: 'Pedidos y logística',
          subtitle: 'Da seguimiento a órdenes, entregas y estado de compra en tiempo real.',
        ),
        const SizedBox(height: 14),
        const _HeroFeature(
          icon: Icons.shield_outlined,
          title: 'Acceso seguro',
          subtitle: 'Sesión protegida para equipos comerciales, administrativos e invitados.',
        ),
      ],
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
