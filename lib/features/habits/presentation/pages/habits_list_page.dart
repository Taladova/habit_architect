import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_architect/core/theme/app_colors.dart';
import 'package:habit_architect/features/stats/presentation/pages/stats_page.dart';

import '../../../../core/utils/date_only.dart';
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
    final nameController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        Future<void> submit() async {
          final name = nameController.text.trim();
          if (name.isEmpty) return;

          // ✅ action
          await ref.read(habitsControllerProvider).addHabit(name);

          // ✅ important: fermer le sheet d'abord (avec le context du sheet)
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }

          // ✅ dispose après fermeture
          nameController.dispose();
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                'Nouvelle habitude',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Ex: Lecture',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: submit,
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // ✅ si l’utilisateur ferme le sheet sans ajouter (swipe/down/back)
      if (!nameController.hasListeners) {
        // évite double dispose
        // (simplement ignorer, ou faire un try/catch)
      }
      try {
        nameController.dispose();
      } catch (_) {}
    });
  }

  void _submitAddHabit(TextEditingController controller) {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    ref.read(habitsControllerProvider).addHabit(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final habitsAsync = ref.watch(habitsStreamProvider);
    final habitsController = ref.read(habitsControllerProvider);
    final topInset = MediaQuery.of(context).padding.top;

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
        // petit fond doux sous l'appbar
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
                            color: cs.onSurface.withOpacity(0.7),
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
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final today = dateOnly(DateTime.now());

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
                  itemCount: habits.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 16, color: cs.outline.withOpacity(0.10)),
                  itemBuilder: (context, i) {
                    final h = habits[i];

                    final now = DateTime.now();
                    final last7 = _lastNDays(now, 7);

                    // combien de jours cochés sur les 7 derniers
                    final done7 = last7.where((day) {
                      return h.completedDays.any((d) => _isSameDay(d, day));
                    }).length;

                    final progress = done7 / 7.0;
                    final percent = ((progress * 100).round());

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
                        await habitsController.deleteHabit(h.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Habitude supprimée')),
                        );
                      },
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outline.withOpacity(0.10)),
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
                                    // Badge gauche
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: AppColors.primary.withOpacity(
                                          0.14,
                                        ),
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
                                            // 'Complétions: ${h.completedDays.length}',
                                            ('7 jours: $done7/7'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurface
                                                      .withOpacity(0.65),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Toggle (icône à droite)
                                    IconButton.filledTonal(
                                      onPressed: () async {
                                        // debugPrint(
                                        //   '✅ UI: toggle pressed for ${h.id}',
                                        // );
                                        debugPrint(
                                          'TOGGLE LIST => id=${h.id} name=${h.name}',
                                        );
                                        await ref
                                            .read(habitsControllerProvider)
                                            .toggleToday(h.id);
                                      },
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
                                  days: last7,
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openAddHabitSheet,
        child: const Icon(Icons.add),
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
        color: cs.surfaceContainerHighest.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
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

List<DateTime> _lastNDays(DateTime now, int n) {
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.days, required this.isDone});

  final List<DateTime> days;
  final bool Function(DateTime day) isDone;

  @override
  Widget build(BuildContext context) {
    final labels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(days.length, (i) {
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
                  color: cs.onSurface.withOpacity(0.65),
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
                    color: done ? cs.primary : cs.outline.withOpacity(0.35),
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
