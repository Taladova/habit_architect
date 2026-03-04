import 'dart:async';

import 'package:flutter/material.dart';

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
  Stream<List<Habit>> watchHabits() async* {
    // Valeur initiale (sinon Riverpod reste en loading)
    yield List.unmodifiable(_habits);

    // Puis les updates
    yield* _controller.stream.map((list) => List.unmodifiable(list));
  }

  @override
  Future<List<Habit>> getHabits() async => List.unmodifiable(_habits);

  @override
  Future<Habit?> getHabitById(String habitId) async {
    try {
      return _habits.firstWhere((h) => h.id == habitId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addHabit(Habit habit) async {
    _habits.insert(0, habit);
    _emit();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _emit();
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    final exists = _habits.any((h) => h.id == habit.id);
    if (!exists) {
      _habits.insert(0, habit);
      _emit();
    }
  }

  @override
  Future<void> toggleHabitForDate({
    required String habitId,
    required DateTime date,
  }) async {
    debugPrint('REPO TOGGLE => habitId=$habitId date=$date');
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = _habits[index];
    final day = dateOnly(date);

    final set = habit.completedDays.map(dateOnly).toSet();

    if (set.contains(day)) {
      set.remove(day);
    } else {
      set.add(day);
    }

    _habits[index] = Habit(
      id: habit.id,
      name: habit.name,
      createdAt: habit.createdAt,
      completedDays: set.toList(),
    );

    _emit();
  }

  @override
  Future<void> toggleHabitForToday({
    required String habitId,
    required DateTime today,
  }) async {
    // On réutilise la logique date (source unique)
    await toggleHabitForDate(habitId: habitId, date: today);
  }

  void dispose() {
    _controller.close();
  }
}
