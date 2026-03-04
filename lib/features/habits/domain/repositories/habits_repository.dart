import '../entities/habit.dart';

abstract class HabitsRepository {
  Future<List<Habit>> getHabits();
  Stream<List<Habit>> watchHabits();

  Future<Habit?> getHabitById(String habitId);

  Future<void> addHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<void> restoreHabit(Habit habit);

  Future<void> toggleHabitForToday({
    required String habitId,
    required DateTime today,
  }) => toggleHabitForDate(habitId: habitId, date: today);

  Future<void> toggleHabitForDate({
    required String habitId,
    required DateTime date,
  });
}
