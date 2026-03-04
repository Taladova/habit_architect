import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:habit_architect/core/utils/result.dart';
import 'package:habit_architect/features/habits/domain/entities/habit.dart';
import 'package:habit_architect/features/habits/domain/repositories/habits_repository.dart';
import 'package:habit_architect/features/habits/domain/usecases/toggle_habit_for_today.dart';

class _MockHabitsRepository extends Mock implements HabitsRepository {}

void main() {
  late HabitsRepository repo;
  late ToggleHabitForToday usecase;

  setUp(() {
    repo = _MockHabitsRepository();
    usecase = ToggleHabitForToday(repo);
  });

  test('ajoute "today" si pas déjà complété', () async {
    final now = DateTime(2026, 2, 24, 10, 30);
    const habitId = 'h1';

    final habit = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: const [],
    );

    when(() => repo.getHabitById(habitId)).thenAnswer((_) async => habit);
    when(() => repo.toggleHabitForToday(habitId: habitId, today: any(named: 'today')))
        .thenAnswer((_) async {});

    final result = await usecase(habitId: habitId, now: now);

    expect(result, isA<Ok<Habit>>());
    final updated = (result as Ok<Habit>).value;
    expect(updated.completedDays.length, 1);

    verify(() => repo.toggleHabitForToday(habitId: habitId, today: any(named: 'today'))).called(1);
  });

  test('retire "today" si déjà complété', () async {
    final now = DateTime(2026, 2, 24, 18, 00);
    const habitId = 'h1';

    final habit = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: [DateTime(2026, 2, 24, 9, 0)], // même jour, autre heure
    );

    when(() => repo.getHabitById(habitId)).thenAnswer((_) async => habit);
    when(() => repo.toggleHabitForToday(habitId: habitId, today: any(named: 'today')))
        .thenAnswer((_) async {});

    final result = await usecase(habitId: habitId, now: now);

    expect(result, isA<Ok<Habit>>());
    final updated = (result as Ok<Habit>).value;
    expect(updated.completedDays.isEmpty, true);

    verify(() => repo.toggleHabitForToday(habitId: habitId, today: any(named: 'today'))).called(1);
  });
}
