import 'package:finatiol_app/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra aviso comercial cuando llega producto de interes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(productoInteres: 'Laptop Gamer'),
        ),
      ),
    );

    expect(
      find.textContaining('Para contratar Laptop Gamer, inicia sesión o regístrate.'),
      findsOneWidget,
    );
  });

  testWidgets('oculta aviso comercial cuando no hay producto de interes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.textContaining('Para contratar'), findsNothing);
  });
}
