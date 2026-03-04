import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// جدول habits
class HabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// جدول completions (1 ligne = 1 jour coché)
class HabitCompletionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitId => text()();
  DateTimeColumn get day => dateTime()(); // stocké "date only"

  @override
  List<String> get customConstraints => [
        'UNIQUE(habit_id, day)',
        'FOREIGN KEY(habit_id) REFERENCES habits_table(id) ON DELETE CASCADE',
      ];
}

@DriftDatabase(tables: [HabitsTable, HabitCompletionsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final db = driftDatabase(name: 'habit_architect');
    return db;
  });
}