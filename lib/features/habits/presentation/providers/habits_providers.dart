import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_in_memory_habits_repository.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../domain/usecases/add_habit.dart';
import '../../domain/usecases/toggle_habit_for_today.dart';

// Repository (Fake pour l’instant)
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final repo = FakeInMemoryHabitsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

// Use cases
final addHabitProvider = Provider<AddHabit>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return AddHabit(
    repo,
    generateId: () => DateTime.now().microsecondsSinceEpoch.toString(),
  );
});

final toggleHabitForTodayProvider = Provider<ToggleHabitForToday>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return ToggleHabitForToday(repo);
});

// Stream des habitudes
final habitsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return repo.watchHabits();
});
