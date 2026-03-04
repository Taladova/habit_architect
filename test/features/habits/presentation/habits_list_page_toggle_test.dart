import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_architect/main.dart';

void main() {
  testWidgets('taper sur une habitude toggle l’icône', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppRoot());
    await tester.pump(const Duration(milliseconds: 200));

    // Ajoute une habitude
    await tester.enterText(
      find.byKey(const Key('addHabitTextField')),
      'Lecture',
    );
    await tester.tap(find.byKey(const Key('addHabitButton')));
    await tester.pump(const Duration(milliseconds: 200));

    // Au début: pas check
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Tap sur l’item "Lecture"
    await tester.tap(find.text('Lecture'));
    await tester.pump(const Duration(milliseconds: 200));

    // Après: check visible
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // Tap encore: doit revenir à non-check
    await tester.tap(find.text('Lecture'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
