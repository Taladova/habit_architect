import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_architect/core/theme/app_colors.dart';
import 'package:habit_architect/features/stats/presentation/pages/stats_page.dart';

import '../providers/habits_controller.dart';
import '../providers/habits_providers.dart';
import 'habit_details_page.dart';

class HabitsListPage extends ConsumerStatefulWidget {
  const HabitsListPage({super.key});

  @override
  ConsumerState<HabitsListPage> createState() => _HabitsListPageState();
}

class _HabitsListPageState extends ConsumerState<HabitsListPage> {
  void _openAddHabitSheet() {
    // ✅ Capturer AVANT (plus d'accès context après)
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _AddHabitSheet(
        onSubmit: (name) async {
          await ref.read(habitsControllerProvider).addHabit(name);

          // ✅ fermer avec sheetContext, pas context
          // ignore: use_build_context_synchronously
          if (Navigator.of(sheetContext).canPop()) {
            // ignore: use_build_context_synchronously
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final habitsAsync = ref.watch(habitsStreamProvider);
    final habitsController = ref.read(habitsControllerProvider);

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
            const Text(
              'Habit Architect',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsPage()));
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
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            ),
            child: habitsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(key: Key('habitsLoading')),
              ),
              error: (e, st) => Center(
                child: Text(
                  'Erreur: $e',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (habits) {
                if (habits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 46,
                            color: cs.onSurface.withAlpha(180),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aucune habitude',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ajoute la première avec le bouton +',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurface.withAlpha(170)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
                  itemCount: habits.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 16, color: cs.outline.withAlpha(26)),
                  itemBuilder: (context, i) {
                    final h = habits[i];

                    final now = DateTime.now();
                    final weekDays = weekMondayToSunday(now);

                    final done7 = weekDays.where((day) {
                      return h.completedDays.any((d) => _isSameDay(d, day));
                    }).length;

                    final progress = done7 / 7.0;
                    final percent = (progress * 100).round();

                    final today = DateTime(now.year, now.month, now.day);
                    final doneToday = h.completedDays.any(
                      (d) => _isSameDay(d, today),
                    );

                    return Dismissible(
                      key: Key('dismiss_${h.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      onDismissed: (_) async {
                        // ✅ capturer avant async
                        final messenger = ScaffoldMessenger.of(context);

                        await habitsController.deleteHabit(h.id);

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Habitude supprimée')),
                        );
                      },
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outline.withAlpha(26)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HabitDetailsPage(habitId: h.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: AppColors.primary.withAlpha(36),
                                      ),
                                      child: const Icon(
                                        Icons.checklist_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '7 jours: $done7/7',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurface.withAlpha(
                                                    166,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      key: Key('toggle_${h.id}'),
                                      onPressed: () =>
                                          habitsController.toggleToday(h.id),
                                      icon: Icon(
                                        doneToday
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 8,
                                          backgroundColor:
                                              cs.surfaceContainerHighest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$percent%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _WeekDots(
                                  days: weekDays,
                                  isDone: (day) => h.completedDays.any(
                                    (d) => _isSameDay(d, day),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniInfoChip(
                                      icon: Icons.local_fire_department_rounded,
                                      label: '${h.currentStreak}',
                                    ),
                                    _MiniInfoChip(
                                      icon: doneToday
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      label: doneToday
                                          ? "Aujourd'hui"
                                          : 'Pas fait',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('openAddHabitSheetFab'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openAddHabitSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet({required this.onSubmit});
  final Future<void> Function(String name) onSubmit;

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    await widget.onSubmit(name);
    // Pas besoin de dispose ici (fait dans dispose)
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            'Nouvelle habitude',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('sheetAddHabitTextField'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Ex: Lecture',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('sheetAddHabitButton'),
              onPressed: _submit,
              child: const Text('Ajouter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(170),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withAlpha(31)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// List<DateTime> _lastNDays(DateTime now, int n) {
//   final today = DateTime(now.year, now.month, now.day);
//   return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
// }
List<DateTime> weekMondayToSunday(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(
    Duration(days: today.weekday - 1),
  ); // weekday: Mon=1
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.days, required this.isDone});

  final List<DateTime> days; // doit être lundi->dimanche
  final bool Function(DateTime day) isDone;

  static const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(7, (i) {
        final day = days[i];
        final done = isDone(day);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? cs.primary : cs.surfaceContainerHighest,
                  border: Border.all(
                    color: done ? cs.primary : cs.outline.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
