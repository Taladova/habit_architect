import '../../../../core/errors/failures.dart';
import '../../../../core/utils/date_only.dart';
import '../../../../core/utils/result.dart';
import '../entities/habit.dart';
import '../repositories/habits_repository.dart';

class ToggleHabitForToday {
  final HabitsRepository _repo;

  const ToggleHabitForToday(this._repo);

  Future<Result<Habit>> call({
    required String habitId,
    required DateTime now,
  }) async {
    if (habitId.trim().isEmpty) {
      return Err(ValidationFailure('habitId ne doit pas être vide.'));
    }

    final today = dateOnly(now);

    try {
      // 1) check habit exists
      final before = await _repo.getHabitById(habitId);
      if (before == null) {
        return Err(ValidationFailure('Habitude introuvable.'));
      }

      // 2) toggle in repo (source de vérité)
      await _repo.toggleHabitForToday(habitId: habitId, today: today);

      // 3) re-read after toggle (retour fiable)
      final after = await _repo.getHabitById(habitId);
      if (after == null) {
        return Err(RepositoryFailure('Habitude introuvable après toggle.'));
      }

      return Ok(after);
    } catch (e) {
      return Err(RepositoryFailure('Erreur repository: $e'));
    }
  }
}