import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../data/repositories/drift_habits_repository.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../domain/usecases/add_habit.dart';
import '../../domain/usecases/toggle_habit_for_date.dart';
import '../../domain/usecases/toggle_habit_for_today.dart';

/// Database (Drift)
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Repository (Drift)
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftHabitsRepository(db);
});

/// Use case: Add habit
final addHabitProvider = Provider<AddHabit>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return AddHabit(
    repo,
    generateId: () => DateTime.now().microsecondsSinceEpoch.toString(),
  );
});

/// Use case: Toggle today
final toggleHabitForTodayProvider = Provider<ToggleHabitForToday>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return ToggleHabitForToday(repo);
});

/// Use case: Toggle for specific date
final toggleHabitForDateProvider = Provider<ToggleHabitForDate>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return ToggleHabitForDate(repo);
});

/// Stream of habits (UI source)
final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  final repo = ref.watch(habitsRepositoryProvider);
  return repo.watchHabits();
});
