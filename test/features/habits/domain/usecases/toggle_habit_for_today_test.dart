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

  setUpAll(() {
    // fallback pour any(named: 'today') sur DateTime
    registerFallbackValue(DateTime(2000, 1, 1));
  });

  setUp(() {
    repo = _MockHabitsRepository();
    usecase = ToggleHabitForToday(repo);
  });

  test('ajoute "today" si pas déjà complété', () async {
    final now = DateTime(2026, 3, 4, 10, 30);
    const habitId = 'h1';
    final today = DateTime(2026, 3, 4);

    final before = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: const [],
    );

    final after = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: [today],
    );

    var callCount = 0;
    when(() => repo.getHabitById(habitId)).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? before : after;
    });

    when(
      () => repo.toggleHabitForToday(
        habitId: habitId,
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) async {});

    final result = await usecase(habitId: habitId, now: now);

    expect(result, isA<Ok<Habit>>());
    final updated = (result as Ok<Habit>).value;

    expect(updated.completedDays.any((d) => _isSameDay(d, today)), true);

    verify(() => repo.getHabitById(habitId)).called(2);
    verify(
      () => repo.toggleHabitForToday(
        habitId: habitId,
        today: any(named: 'today'),
      ),
    ).called(1);
  });

  test('retire "today" si déjà complété', () async {
    final now = DateTime(2026, 2, 24, 18, 00);
    const habitId = 'h1';
    final today = DateTime(2026, 2, 24);

    final before = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: [DateTime(2026, 2, 24, 9, 0)], // même jour, autre heure
    );

    final after = Habit(
      id: habitId,
      name: 'Lecture',
      createdAt: DateTime(2026, 2, 1),
      completedDays: const [], // décoché
    );

    var callCount = 0;
    when(() => repo.getHabitById(habitId)).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? before : after;
    });

    when(
      () => repo.toggleHabitForToday(
        habitId: habitId,
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) async {});

    final result = await usecase(habitId: habitId, now: now);

    expect(result, isA<Ok<Habit>>());
    final updated = (result as Ok<Habit>).value;

    expect(updated.completedDays.any((d) => _isSameDay(d, today)), false);

    verify(() => repo.getHabitById(habitId)).called(2);
    verify(
      () => repo.toggleHabitForToday(
        habitId: habitId,
        today: any(named: 'today'),
      ),
    ).called(1);
  });
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;