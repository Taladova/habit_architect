import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/habit.dart';
import '../repositories/habits_repository.dart';

typedef IdGenerator = String Function();

class AddHabit {
  final HabitsRepository _repo;
  final IdGenerator _generateId;

  AddHabit(this._repo, {required IdGenerator generateId})
    : _generateId = generateId;

  Future<Result<Habit>> call({
    required String name,
    required DateTime now,
  }) async {
    if (name.trim().isEmpty) {
      return Err(ValidationFailure('Le nom ne peut pas être vide.'));
    }

    try {
      final habit = Habit(
        id: _generateId(),
        name: name.trim(),
        createdAt: now,
        completedDays: const [],
      );

      await _repo.addHabit(habit);

      return Ok(habit);
    } catch (e) {
      return Err(RepositoryFailure('Erreur lors de l\'ajout: $e'));
    }
  }
}
