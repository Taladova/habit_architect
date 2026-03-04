import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habit_architect/features/habits/data/repositories/fake_in_memory_habits_repository.dart';
import 'package:habit_architect/features/habits/domain/repositories/habits_repository.dart';
import 'package:habit_architect/features/habits/presentation/pages/habits_list_page.dart';
import 'package:habit_architect/features/habits/presentation/providers/habits_providers.dart';

void main() {
  testWidgets('ajouter une habitude affiche la nouvelle habitude',
      (WidgetTester tester) async {
    final repo = FakeInMemoryHabitsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsRepositoryProvider.overrideWithValue(repo as HabitsRepository),
        ],
        child: const MaterialApp(home: HabitsListPage()),
      ),
    );

    // Laisse Riverpod recevoir la 1ère valeur du stream
    await tester.pump(const Duration(milliseconds: 50));

    // Ouvre la sheet
    await tester.tap(find.byKey(const Key('openAddHabitSheetFab')));
    await tester.pump(const Duration(milliseconds: 350)); // animation sheet

    // Tape le texte
    await tester.enterText(
      find.byKey(const Key('sheetAddHabitTextField')),
      'Lecture',
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Ferme le clavier (important)
    tester.testTextInput.hide();
    await tester.pump(const Duration(milliseconds: 50));

    // Clique ajouter
    await tester.tap(find.byKey(const Key('sheetAddHabitButton')));
    await tester.pump(const Duration(milliseconds: 350)); // fermeture sheet

    // Vérifie
    expect(find.text('Lecture'), findsOneWidget);
  });
}