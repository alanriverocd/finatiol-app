import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrandIntroScreen extends StatefulWidget {
  const BrandIntroScreen({super.key});

  @override
  State<BrandIntroScreen> createState() => _BrandIntroScreenState();
}

class _BrandIntroScreenState extends State<BrandIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fade = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _redirectTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      context.go('/escaparate');
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071A34), Color(0xFF103D7A), Color(0xFF1F66C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -30,
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, child) => Opacity(
                  opacity: _fade.value,
                  child: child,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: 160,
                  color: Colors.white24,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -10,
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, child) => Opacity(
                  opacity: _fade.value * 0.8,
                  child: child,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  size: 150,
                  color: Colors.white24,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) => Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.pets, size: 56, color: Color(0xFF103D7A)),
                            Positioned(
                              bottom: 12,
                              child: Icon(
                                Icons.account_balance,
                                size: 24,
                                color: Color(0xFFC79A3B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'FINATIOL',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La mascota financiera que cuida tu futuro',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'by FINATIOL',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
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
    );
  }
}
