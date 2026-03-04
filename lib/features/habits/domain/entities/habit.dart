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
  int get currentStreak {
    if (completedDays.isEmpty) return 0;

    final sorted = completedDays.toList()..sort((a, b) => b.compareTo(a));

    int streak = 1;

    for (int i = 1; i < sorted.length; i++) {
      final difference = sorted[i - 1].difference(sorted[i]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
