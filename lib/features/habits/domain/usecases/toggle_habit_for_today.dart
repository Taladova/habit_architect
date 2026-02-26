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
    // ✅ Validation (senior)
    if (habitId.trim().isEmpty) {
      return Err(ValidationFailure('habitId ne doit pas être vide.'));
    }

    final today = dateOnly(now);

    try {
      final habit = await _repo.getHabitById(habitId);
      if (habit == null) {
        return Err(ValidationFailure('Habitude introuvable.'));
      }

      // ✅ Action côté repository (source de vérité / persistence)
      await _repo.toggleHabitForToday(habitId: habitId, today: today);

      // ✅ Retourner une version "mise à jour" (utile pour tests / UI)
      final completed = habit.completedDays.map(dateOnly).toList();
      final alreadyDone = completed.contains(today);

      final updated = Habit(
        id: habit.id,
        name: habit.name,
        createdAt: habit.createdAt,
        completedDays: [
          for (final d in completed)
            if (d != today) d,
          if (!alreadyDone) today,
        ],
      );

      return Ok(updated);
    } catch (e) {
      return Err(RepositoryFailure('Erreur repository: $e'));
    }
  }
}
