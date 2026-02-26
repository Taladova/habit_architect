import 'dart:async';

import '../../../../core/utils/date_only.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habits_repository.dart';

class FakeInMemoryHabitsRepository implements HabitsRepository {
  final List<Habit> _habits = [];
  final _controller = StreamController<List<Habit>>.broadcast();

  FakeInMemoryHabitsRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_habits));
  }

  @override
  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    _emit();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _emit();
  }

  @override
  Future<List<Habit>> getHabits() async {
    return List.unmodifiable(_habits);
  }

  @override
  Stream<List<Habit>> watchHabits() {
    return _controller.stream;
  }

  @override
  Future<Habit?> getHabitById(String habitId) async {
    try {
      return _habits.firstWhere((h) => h.id == habitId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> toggleHabitForToday({
    required String habitId,
    required DateTime today,
  }) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = _habits[index];
    final normalizedToday = dateOnly(today);

    final normalizedDays =
        habit.completedDays.map(dateOnly).toList();

    final alreadyDone =
        normalizedDays.contains(normalizedToday);

    final updatedDays = [
      for (final d in normalizedDays)
        if (d != normalizedToday) d,
      if (!alreadyDone) normalizedToday,
    ];

    _habits[index] = Habit(
      id: habit.id,
      name: habit.name,
      createdAt: habit.createdAt,
      completedDays: updatedDays,
    );

    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
