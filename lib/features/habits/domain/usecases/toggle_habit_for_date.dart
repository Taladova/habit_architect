import '../repositories/habits_repository.dart';

class ToggleHabitForDate {
  ToggleHabitForDate(this._repo);

  final HabitsRepository _repo;

  Future<void> call({
    required String habitId,
    required DateTime date,
  }) async {
    await _repo.toggleHabitForDate(
      habitId: habitId,
      date: date,
    );
  }
}