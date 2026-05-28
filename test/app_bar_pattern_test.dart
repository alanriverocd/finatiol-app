import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature screens must use FinatiolAppBar instead of AppBar directly', () {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue);

    final violatingFiles = <String>[];

    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (content.contains('appBar: AppBar(')) {
        violatingFiles.add(entity.path.replaceAll('\\', '/'));
      }
    }

    expect(
      violatingFiles,
      isEmpty,
      reason: 'Use FinatiolAppBar for consistent back/home navigation. Violations: $violatingFiles',
    );
  });
}
