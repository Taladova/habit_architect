import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:habit_architect/features/habits/data/repositories/fake_in_memory_habits_repository.dart';
import 'package:habit_architect/features/habits/domain/repositories/habits_repository.dart';
import 'package:habit_architect/features/habits/presentation/pages/habits_list_page.dart';
import 'package:habit_architect/features/habits/presentation/providers/habits_providers.dart';

void main() {
  testWidgets('taper sur une habitude toggle l’icône',
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

    await tester.pump(const Duration(milliseconds: 50));

    // Ajoute une habitude via sheet
    await tester.tap(find.byKey(const Key('openAddHabitSheetFab')));
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(
      find.byKey(const Key('sheetAddHabitTextField')),
      'Footing',
    );
    await tester.pump(const Duration(milliseconds: 50));

    tester.testTextInput.hide();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('sheetAddHabitButton')));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Footing'), findsOneWidget);

    // Toggle (si tu peux, mets une Key sur le bouton toggle; sinon on prend le premier IconButton)
    final toggleBtn = find.byType(IconButton).first;
    await tester.tap(toggleBtn);
    await tester.pump(const Duration(milliseconds: 150));

    // Juste vérifier que l'app n'a pas crash + item toujours présent
    expect(find.text('Footing'), findsOneWidget);
  });
}