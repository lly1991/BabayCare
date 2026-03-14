import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babycare_flutter/app/app.dart';

void main() {
  testWidgets('app bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BabyCareApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(BabyCareApp), findsOneWidget);
  });
}
