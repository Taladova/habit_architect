import '../entities/habit.dart';

abstract class HabitsRepository {
  Future<List<Habit>> getHabits();
  Stream<List<Habit>> watchHabits();

  Future<Habit?> getHabitById(String habitId);

  Future<void> addHabit(Habit habit);
  Future<void> deleteHabit(String habitId);

  Future<void> toggleHabitForToday({
    required String habitId,
    required DateTime today,
  });
}
