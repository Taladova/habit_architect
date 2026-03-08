import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/habit.dart';
import 'habits_providers.dart';

final habitsControllerProvider = Provider<HabitsController>((ref) {
  return HabitsController(ref);
});

class HabitsController {
  final Ref _ref;
  HabitsController(this._ref);

  Future<void> addHabit(String name) async {
    final addHabit = _ref.read(addHabitProvider);
    final result = await addHabit(name: name, now: DateTime.now());

    if (result is Err<Habit>) {
      // Ici tu pourras gérer UI error (SnackBar etc.)
    }
  }

  // Future<void> deleteHabit(String habitId) async {
  //   final repo = _ref.read(habitsRepositoryProvider);
  //   await repo.deleteHabit(habitId);
  // }

  Future<void> deleteHabit(String habitId) async {
    await _ref.read(habitsRepositoryProvider).deleteHabit(habitId);
  }

  Future<void> toggleToday(String habitId) async {
    final toggle = _ref.read(toggleHabitForTodayProvider);
    final result = await toggle(habitId: habitId, now: DateTime.now());

    if (result is Err<Habit>) {
      debugPrint('Toggle error: $result');
    } else {
      debugPrint('Toggle ok');
    }
  }

  Future<void> toggleDate(String habitId, DateTime date) async {
    final toggle = _ref.read(toggleHabitForDateProvider);
    await toggle(habitId: habitId, date: date);
  }

  Future<void> restoreHabit(Habit habit) async {
    await _ref.read(habitsRepositoryProvider).restoreHabit(habit);
  }
}
