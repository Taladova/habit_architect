import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_architect/core/theme/app_colors.dart';

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
    final cs = Theme.of(context).colorScheme;

    return habitsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Détails')),
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (habits) {
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
        final weekDays = weekMondayToSunday(now);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Row(
              children: [
                Image.asset('assets/branding/logo.png', height: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
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
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.secondary, cs.surface],
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListView(
                // ✅ PADDING GLOBAL (c’est ça qui manquait)
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  16,
                  24,
                ),
                children: [
                  // ✅ Chips propres (wrap = pas de débordement)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(label: Text('🔥 ${habit.currentStreak}')),
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
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: cs.outline.withOpacity(0.10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semaine (L → D)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final day in weekDays)
                                _DayDot(
                                  date: day,
                                  isDone: habit.completedDays.any(
                                    (d) => _isSameDay(d, day),
                                  ),
                                  onTap: () =>
                                      controller.toggleDate(habit.id, day),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
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
            ),
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
    final cs = Theme.of(context).colorScheme;
    final label = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'][date.weekday - 1];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDone ? cs.primaryContainer : cs.surface,
          border: Border.all(
            color: cs.outline.withOpacity(0.35),
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
              color: isDone ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ✅ Semaine fixe: Lundi -> Dimanche (ordre stable)
List<DateTime> weekMondayToSunday(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}