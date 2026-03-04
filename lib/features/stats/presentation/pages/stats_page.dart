import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/presentation/providers/habits_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (habits) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          int doneToday = 0;
          int doneLast7 = 0;

          final last7 = List.generate(
            7,
            (i) => today.subtract(Duration(days: 6 - i)),
          );

          for (final h in habits) {
            if (h.completedDays.any((d) => _isSameDay(d, today))) {
              doneToday++;
            }
            for (final day in last7) {
              if (h.completedDays.any((d) => _isSameDay(d, day))) {
                doneLast7++;
              }
            }
          }

          final totalHabits = habits.length;
          final bestStreak = habits.isEmpty
              ? 0
              : habits
                    .map((h) => h.currentStreak)
                    .reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                title: 'Habitudes',
                value: '$totalHabits',
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Faites aujourd’hui',
                value: '$doneToday / $totalHabits',
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Complétions (7 jours)',
                value: '$doneLast7',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'Meilleur streak',
                value: '$bestStreak 🔥',
                icon: Icons.local_fire_department_rounded,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cs.primaryContainer,
              ),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
