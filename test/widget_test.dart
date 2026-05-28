import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finatiol_app/main.dart';

void main() {
  testWidgets('Finatiol app builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FinatiolApp()),
    );

    expect(find.byType(FinatiolApp), findsOneWidget);
  });
}
