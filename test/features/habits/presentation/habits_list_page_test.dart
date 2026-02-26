import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_architect/main.dart';

void main() {
  testWidgets('ajouter une habitude affiche la nouvelle habitude',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppRoot());

    // l’arbre des widgets
    // debugDumpApp();

    // Laisse le temps au StreamProvider d'émettre (loading -> data)
    await tester.pump(const Duration(milliseconds: 200));

    // Entre du texte
    await tester.enterText(
      find.byKey(const Key('addHabitTextField')),
      'Lecture',
    );

    // Clique sur ajouter
    await tester.tap(find.byKey(const Key('addHabitButton')));

    // Laisse le temps au stream d'émettre + rebuild
    await tester.pump(const Duration(milliseconds: 200));

    // Vérifie que "Lecture" apparaît
    expect(find.text('Lecture'), findsOneWidget);
  });
}