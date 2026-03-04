import 'package:mocktail/mocktail.dart';
import 'package:habit_architect/features/habits/domain/entities/habit.dart';
// ignore: depend_on_referenced_packages, file_names
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
// import 'package:uuid/uuid.dart';

import 'package:habit_architect/core/utils/result.dart';
// import 'package:habit_architect/features/habits/domain/entities/habit.dart';
import 'package:habit_architect/features/habits/domain/repositories/habits_repository.dart';
import 'package:habit_architect/features/habits/domain/usecases/add_habit.dart';

class _MockHabitsRepository extends Mock implements HabitsRepository {}

class HabitFake extends Fake implements Habit {}

void main() {
  setUpAll(() {
    registerFallbackValue(HabitFake());
  });
  late HabitsRepository repo;
  late AddHabit usecase;

  setUp(() {
    repo = _MockHabitsRepository();
    usecase = AddHabit(repo, generateId: () => 'fixed-id');
  });

  test('retourne ValidationFailure si nom vide', () async {
    final result = await usecase(name: '', now: DateTime.now());

    expect(result, isA<Err>());
  });

  test('ajoute une habitude correctement', () async {
    when(() => repo.addHabit(any(that: isA<Habit>()))).thenAnswer((_) async {});

    final result = await usecase(name: 'Lecture', now: DateTime(2026, 2, 24));

    expect(result, isA<Ok<Habit>>());

    final habit = (result as Ok<Habit>).value;

    expect(habit.id, 'fixed-id');
    expect(habit.name, 'Lecture');

    verify(() => repo.addHabit(any())).called(1);
  });
}
