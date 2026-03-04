import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/date_only.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habits_repository.dart';

class DriftHabitsRepository implements HabitsRepository {
  DriftHabitsRepository(this.db);

  final AppDatabase db;

  // ---- helpers
  DateTime _d(DateTime dt) => dateOnly(dt);

  Future<List<DateTime>> _loadCompletedDays(String habitId) async {
    final rows =
        await (db.select(db.habitCompletionsTable)
              ..where((t) => t.habitId.equals(habitId))
              ..orderBy([
                (t) => OrderingTerm(expression: t.day, mode: OrderingMode.asc),
              ]))
            .get();
    return rows.map((r) => r.day).toList();
  }

  Future<Habit> _toHabitFromRow(HabitsTableData h) async {
    final days = await _loadCompletedDays(h.id);
    return Habit(
      id: h.id,
      name: h.name,
      createdAt: h.createdAt,
      completedDays: days,
    );
  }

  // ---- HabitsRepository
  @override
  Stream<List<Habit>> watchHabits() {
    final query = db.select(db.habitsTable).join([
      leftOuterJoin(
        db.habitCompletionsTable,
        db.habitCompletionsTable.habitId.equalsExp(db.habitsTable.id),
      ),
    ])..orderBy([OrderingTerm.desc(db.habitsTable.createdAt)]);

    return query.watch().map((rows) {
      // Group completions by habitId
      final mapDays = <String, List<DateTime>>{};
      final mapHabitRow = <String, dynamic>{};

      for (final row in rows) {
        final habitRow = row.readTable(db.habitsTable);
        mapHabitRow[habitRow.id] = habitRow;

        final completionRow = row.readTableOrNull(db.habitCompletionsTable);
        if (completionRow != null) {
          mapDays.putIfAbsent(habitRow.id, () => []).add(completionRow.day);
        }
      }

      // Build domain list
      final habits = <Habit>[];
      for (final entry in mapHabitRow.entries) {
        final h = entry.value;
        habits.add(
          Habit(
            id: h.id,
            name: h.name,
            createdAt: h.createdAt,
            completedDays: mapDays[h.id] ?? const [],
          ),
        );
      }

      return habits;
    });
  }

  @override
  Future<List<Habit>> getHabits() async {
    final rows = await db.select(db.habitsTable).get();
    final habits = <Habit>[];
    for (final r in rows) {
      habits.add(await _toHabitFromRow(r));
    }
    habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return habits;
  }

  @override
  Future<Habit?> getHabitById(String habitId) async {
    final row = await (db.select(
      db.habitsTable,
    )..where((t) => t.id.equals(habitId))).getSingleOrNull();
    if (row == null) return null;
    return _toHabitFromRow(row);
  }

  @override
  Future<void> addHabit(Habit habit) async {
    await db
        .into(db.habitsTable)
        .insert(
          HabitsTableCompanion.insert(
            id: habit.id,
            name: habit.name,
            createdAt: habit.createdAt,
          ),
        );
    // insert completions si jamais (optionnel)
    for (final d in habit.completedDays) {
      await db
          .into(db.habitCompletionsTable)
          .insert(
            HabitCompletionsTableCompanion.insert(
              habitId: habit.id,
              day: _d(d),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    // ON DELETE CASCADE supprime aussi les completions
    await (db.delete(db.habitsTable)..where((t) => t.id.equals(habitId))).go();
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    // restore = réinsérer (si absent)
    await db
        .into(db.habitsTable)
        .insert(
          HabitsTableCompanion.insert(
            id: habit.id,
            name: habit.name,
            createdAt: habit.createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    for (final d in habit.completedDays) {
      await db
          .into(db.habitCompletionsTable)
          .insert(
            HabitCompletionsTableCompanion.insert(
              habitId: habit.id,
              day: _d(d),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  @override
  Future<void> toggleHabitForToday({
    required String habitId,
    required DateTime today,
  }) async {
    debugPrint('DRIFT TOGGLE => habitId=$habitId today=$today');

    final day = DateTime(today.year, today.month, today.day);

    final existing =
        await (db.select(db.habitCompletionsTable)
              ..where((t) => t.habitId.equals(habitId) & t.day.equals(day)))
            .getSingleOrNull();

    if (existing != null) {
      // ✅ déjà coché => on SUPPRIME (décocher)
      await (db.delete(
        db.habitCompletionsTable,
      )..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).go();
    } else {
      // ✅ pas coché => on INSÈRE (cocher)
      await db
          .into(db.habitCompletionsTable)
          .insert(
            HabitCompletionsTableCompanion.insert(habitId: habitId, day: day),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  @override
  Future<void> toggleHabitForDate({
    required String habitId,
    required DateTime date,
  }) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return;

    final normalized = DateTime(date.year, date.month, date.day);

    final days = habit.completedDays.toSet();

    final alreadyDone = days.any(
      (d) =>
          d.year == normalized.year &&
          d.month == normalized.month &&
          d.day == normalized.day,
    );

    if (alreadyDone) {
      days.removeWhere(
        (d) =>
            d.year == normalized.year &&
            d.month == normalized.month &&
            d.day == normalized.day,
      );
    } else {
      days.add(normalized);
    }

    await toggleHabitForToday(habitId: habitId, today: date);
  }
}
