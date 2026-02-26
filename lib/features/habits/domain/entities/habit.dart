class Habit {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<DateTime> completedDays;

  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.completedDays,
  });
}