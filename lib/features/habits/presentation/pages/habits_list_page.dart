import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_architect/core/theme/app_colors.dart';
import 'package:habit_architect/features/habits/domain/entities/habit.dart';
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
  bool showOnlyToday = false;

  void _openAddHabitSheet() {
    final surface = Theme.of(context).colorScheme.surface;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _AddHabitSheet(
        onSubmit: (name) async {
          await ref.read(habitsControllerProvider).addHabit(name);
          if (Navigator.of(sheetContext).canPop()) {
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
        flexibleSpace: ClipPath(
          clipper: HeaderCurveClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final doneTodayCount = habits.where((h) {
                  return h.completedDays.any((d) => _isSameDay(d, today));
                }).length;

                final totalHabits = habits.length;
                final dayPercent = totalHabits == 0
                    ? 0
                    : ((doneTodayCount / totalHabits) * 100).round();

                final visibleHabits = showOnlyToday
                    ? habits
                          .where(
                            (h) => h.completedDays.any(
                              (d) => _isSameDay(d, today),
                            ),
                          )
                          .toList()
                    : habits;

                if (habits.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _SummaryHeader(totalHabits: 0, doneToday: 0, percent: 0),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: cs.outline.withAlpha(26)),
                        ),
                        child: Column(
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
                                  ?.copyWith(
                                    color: cs.onSurface.withAlpha(170),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _SummaryHeader(
                        totalHabits: totalHabits,
                        doneToday: doneTodayCount,
                        percent: dayPercent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            showOnlyToday
                                ? "Aujourd’hui"
                                : "Toutes les habitudes",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.surface,
                                ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Filtrer',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppColors.surface),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: showOnlyToday,
                                onChanged: (v) {
                                  setState(() => showOnlyToday = v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: visibleHabits.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final h = visibleHabits[i];
                          final weekDays = weekMondayToSunday(now);

                          final done7 = weekDays.where((day) {
                            return h.completedDays.any(
                              (d) => _isSameDay(d, day),
                            );
                          }).length;

                          final progress = done7 / 7.0;
                          final percent = (progress * 100).round();
                          final doneToday = h.completedDays.any(
                            (d) => _isSameDay(d, today),
                          );

                          return Dismissible(
                            key: Key('dismiss_${h.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) async {
                              final deleted = h;
                              final messenger = ScaffoldMessenger.of(context);

                              await habitsController.deleteHabit(h.id);

                              if (!mounted) return;

                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Habitude supprimée'),
                                  action: SnackBarAction(
                                    label: 'Annuler',
                                    onPressed: () {
                                      habitsController.restoreHabit(deleted);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: _HabitCard(
                              habit: h,
                              done7: done7,
                              percent: percent,
                              progress: progress,
                              doneToday: doneToday,
                              weekDays: weekDays,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HabitDetailsPage(habitId: h.id),
                                  ),
                                );
                              },
                              onToggle: () =>
                                  habitsController.toggleToday(h.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalHabits,
    required this.doneToday,
    required this.percent,
  });

  final int totalHabits;
  final int doneToday;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 10),
              color: Colors.black.withAlpha(28),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du jour',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withAlpha(220),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeaderInfo(label: 'Habitudes', value: '$totalHabits'),
                ),
                Expanded(
                  child: _HeaderInfo(label: 'Faites', value: '$doneToday'),
                ),
                Expanded(
                  child: _HeaderInfo(label: 'Progression', value: '$percent%'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: totalHabits == 0 ? 0 : doneToday / totalHabits,
                minHeight: 10,
                backgroundColor: Colors.white.withAlpha(50),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withAlpha(210),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.done7,
    required this.percent,
    required this.progress,
    required this.doneToday,
    required this.weekDays,
    required this.onTap,
    required this.onToggle,
  });

  final Habit habit;
  final int done7;
  final int percent;
  final double progress;
  final bool doneToday;
  final List<DateTime> weekDays;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outline.withAlpha(26)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Semaine : $done7/7',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurface.withAlpha(166)),
                          ),
                        ],
                      ),
                    ),

                    // ✅ bouton toggle animé
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: doneToday
                            ? [
                                BoxShadow(
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                  color: AppColors.primary.withAlpha(60),
                                ),
                              ]
                            : null,
                      ),
                      child: IconButton.filledTonal(
                        key: Key('toggle_${habit.id}'),
                        onPressed: onToggle,
                        style: IconButton.styleFrom(
                          backgroundColor: doneToday
                              ? AppColors.primary.withAlpha(40)
                              : null,
                        ),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            doneToday
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            key: ValueKey(doneToday),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _WeekDots(
                  days: weekDays,
                  isDone: (day) =>
                      habit.completedDays.any((d) => _isSameDay(d, day)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniInfoChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${habit.currentStreak}',
                    ),
                    _MiniInfoChip(
                      icon: doneToday
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      label: doneToday ? "Aujourd'hui" : 'Pas fait',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.days, required this.isDone});

  final List<DateTime> days;
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
                  color: cs.onSurface.withAlpha(166),
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
                    color: done ? cs.primary : cs.outline.withAlpha(90),
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

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<DateTime> weekMondayToSunday(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}
