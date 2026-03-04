import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:habit_architect/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flow complet: add -> toggle', (tester) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump(const Duration(milliseconds: 300));

    // Ajouter une habitude
    await tester.enterText(
      find.byKey(const Key('addHabitTextField')),
      'Lecture',
    );
    await tester.tap(find.byKey(const Key('addHabitButton')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lecture'), findsOneWidget);

    // Toggle
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.tap(find.text('Lecture'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
