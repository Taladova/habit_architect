import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/habit.dart';
import '../providers/habits_controller.dart';
import '../providers/habits_providers.dart';

class HabitDetailsPage extends ConsumerWidget {
  const HabitDetailsPage({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final controller = ref.read(habitsControllerProvider);

    return habitsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Détails')),
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (habits) {
        // ✅ type-safe
        final Habit? habit = habits
            .whereType<Habit>()
            .cast<Habit?>()
            .firstWhere((h) => h!.id == habitId, orElse: () => null);

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails')),
            body: const Center(child: Text("Habitude introuvable")),
          );
        }

        final now = DateTime.now();
        final doneToday = habit.completedDays.any((d) => _isSameDay(d, now));

        final base = DateTime(now.year, now.month, now.day);
        final last7Days = List.generate(
          7,
          (i) => base.subtract(Duration(days: 6 - i)),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer ?'),
                      content: Text('Supprimer "${habit.name}" ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );

                  if (ok != true) return;

                  await controller.deleteHabit(habit.id);

                  // ✅ revenir à la liste après suppression
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Chip(label: Text('🔥 ${habit.currentStreak}')),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      doneToday ? "Aujourd’hui ✅" : "Pas fait aujourd’hui",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7 derniers jours',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final day in last7Days)
                            _DayDot(
                              date: day,
                              isDone: habit.completedDays.any(
                                (d) => _isSameDay(d, day),
                              ),
                              onTap: () => controller.toggleDate(habit.id, day),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          // ✅ IMPORTANT : await + pop => retour à la liste
                          onPressed: () async {
                            await controller.toggleToday(habit.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: Icon(doneToday ? Icons.undo : Icons.check),
                          label: Text(
                            doneToday
                                ? "Annuler aujourd’hui"
                                : "Cocher aujourd’hui",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.isDone,
    required this.onTap,
  });

  final DateTime date;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = ['L', 'M', 'M', 'J', 'V', 'S', 'D'][date.weekday - 1];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDone ? Theme.of(context).colorScheme.primaryContainer : null,
          border: Border.all(
            // ignore: deprecated_member_use
            color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
