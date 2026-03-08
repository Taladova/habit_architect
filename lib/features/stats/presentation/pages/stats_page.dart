import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_architect/core/theme/app_colors.dart';

import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/providers/habits_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final cs = Theme.of(context).colorScheme;

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
              'Statistiques',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (habits) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final totalHabits = habits.length;

                final doneToday = habits.where((h) {
                  return h.completedDays.any((d) => _isSameDay(d, today));
                }).length;

                final percentToday = totalHabits == 0
                    ? 0
                    : ((doneToday / totalHabits) * 100).round();

                final totalStreak = habits.fold<int>(
                  0,
                  (sum, h) => sum + h.currentStreak,
                );

                final bestStreak = habits.isEmpty
                    ? 0
                    : habits
                        .map((h) => h.currentStreak)
                        .reduce((a, b) => a > b ? a : b);

                final averageStreak = habits.isEmpty
                    ? 0
                    : (totalStreak / habits.length).round();

                final weekDays = weekMondayToSunday(today);

                final weekCounts = weekDays.map((day) {
                  return habits.where((h) {
                    return h.completedDays.any((d) => _isSameDay(d, day));
                  }).length;
                }).toList();

                final weekTotalPossible = totalHabits * 7;
                final weekDone = weekCounts.fold<int>(0, (sum, v) => sum + v);
                final weekSuccessRate = weekTotalPossible == 0
                    ? 0
                    : ((weekDone / weekTotalPossible) * 100).round();

                final last30Days = List.generate(
                  35,
                  (i) => today.subtract(Duration(days: 34 - i)),
                );

                final heatmapValues = last30Days.map((day) {
                  return habits.where((h) {
                    return h.completedDays.any((d) => _isSameDay(d, day));
                  }).length;
                }).toList();

                final monthTotalPossible = totalHabits * 30;
                final monthDone = heatmapValues.fold<int>(0, (sum, v) => sum + v);
                final monthSuccessRate = monthTotalPossible == 0
                    ? 0
                    : ((monthDone / monthTotalPossible) * 100).round();

                final bestDayIndex = weekCounts.isEmpty
                    ? 0
                    : weekCounts.indexOf(
                        weekCounts.reduce((a, b) => a >= b ? a : b),
                      );

                final weakestDayIndex = weekCounts.isEmpty
                    ? 0
                    : weekCounts.indexOf(
                        weekCounts.reduce((a, b) => a <= b ? a : b),
                      );

                final bestDayLabel = _weekdayLabel(bestDayIndex);
                final weakestDayLabel = _weekdayLabel(weakestDayIndex);

                final mostConsistentHabit = habits.isEmpty
                    ? null
                    : habits.reduce((a, b) {
                        return a.completedDays.length >= b.completedDays.length
                            ? a
                            : b;
                      });

                final leastConsistentHabit = habits.isEmpty
                    ? null
                    : habits.reduce((a, b) {
                        return a.completedDays.length <= b.completedDays.length
                            ? a
                            : b;
                      });

                final disciplineScore = _computeDisciplineScore(
                  todayRate: percentToday,
                  weekRate: weekSuccessRate,
                  monthRate: monthSuccessRate,
                  bestStreak: bestStreak,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _StatsHeroHeader(
                      totalHabits: totalHabits,
                      doneToday: doneToday,
                      percentToday: percentToday,
                      disciplineScore: disciplineScore,
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      child: Column(
                        children: [
                          _StatRow(
                            title: 'Habitudes',
                            value: '$totalHabits',
                            icon: Icons.list_alt_rounded,
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            title: 'Faites aujourd’hui',
                            value: '$doneToday / $totalHabits',
                            icon: Icons.check_circle_rounded,
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            title: 'Meilleur streak',
                            value: '$bestStreak 🔥',
                            icon: Icons.local_fire_department_rounded,
                          ),
                          const SizedBox(height: 12),
                          _StatRow(
                            title: 'Streak moyen',
                            value: '$averageStreak jours',
                            icon: Icons.timelapse_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Activité de la semaine'),
                    const SizedBox(height: 10),
                    _WeeklyChart(
                      values: weekCounts,
                      maxValue: totalHabits == 0 ? 1 : totalHabits,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          _MetricTile(
                            label: 'Réussite semaine',
                            value: '$weekSuccessRate%',
                          ),
                          const SizedBox(height: 12),
                          _MetricTile(
                            label: 'Réussite 30 jours',
                            value: '$monthSuccessRate%',
                          ),
                          const SizedBox(height: 12),
                          _MetricTile(
                            label: 'Meilleur jour',
                            value: bestDayLabel,
                          ),
                          const SizedBox(height: 12),
                          _MetricTile(
                            label: 'Jour le plus faible',
                            value: weakestDayLabel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Heatmap des 35 derniers jours'),
                    const SizedBox(height: 10),
                    _HeatmapGrid(
                      values: heatmapValues,
                      maxValue: totalHabits == 0 ? 1 : totalHabits,
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Insights'),
                    const SizedBox(height: 10),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mostConsistentHabit == null
                                ? 'Aucune donnée pour le moment.'
                                : 'Habitude la plus régulière : ${mostConsistentHabit.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            leastConsistentHabit == null
                                ? 'Aucune donnée pour le moment.'
                                : 'Habitude la moins régulière : ${leastConsistentHabit.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            totalHabits == 0
                                ? 'Crée quelques habitudes pour débloquer les analyses.'
                                : 'Score discipline : $disciplineScore / 100',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsHeroHeader extends StatelessWidget {
  const _StatsHeroHeader({
    required this.totalHabits,
    required this.doneToday,
    required this.percentToday,
    required this.disciplineScore,
  });

  final int totalHabits;
  final int doneToday;
  final int percentToday;
  final int disciplineScore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = totalHabits == 0 ? 0.0 : doneToday / totalHabits;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withAlpha(20),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 78,
                width: 78,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                ),
              ),
              Text(
                '$percentToday%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vue globale',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '$doneToday / $totalHabits habitudes faites aujourd’hui',
                  style: TextStyle(
                    color: cs.onSurface.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Score $disciplineScore / 100',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outline.withAlpha(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
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
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({
    required this.values,
    required this.maxValue,
  });

  final List<int> values;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return _SectionCard(
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final value = values[i];
            final factor = maxValue == 0 ? 0.0 : value / maxValue;
            final barHeight = 24 + (110 * factor);

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: value == 0
                          ? cs.surfaceContainerHighest
                          : cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withAlpha(170),
                        ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.values,
    required this.maxValue,
  });

  final List<int> values;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final weeks = <List<int>>[];
    for (var i = 0; i < values.length; i += 7) {
      weeks.add(values.skip(i).take(7).toList());
    }

    return _SectionCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: List.generate(dayLabels.length, (i) {
                  return SizedBox(
                    height: 22,
                    child: Center(
                      child: Text(
                        dayLabels[i],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withAlpha(170),
                            ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weeks.map((week) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          children: List.generate(7, (i) {
                            final value = i < week.length ? week[i] : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _heatColor(cs, value, maxValue),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Moins',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
              ),
              const SizedBox(width: 8),
              ...List.generate(4, (i) {
                final previewValue = [0, 1, 2, maxValue][i];
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _heatColor(cs, previewValue, maxValue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                'Plus',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatColor(ColorScheme cs, int value, int maxValue) {
    if (value == 0) return cs.surfaceContainerHighest;
    final ratio = value / maxValue;
    if (ratio < 0.25) return cs.primary.withAlpha(70);
    if (ratio < 0.50) return cs.primary.withAlpha(120);
    if (ratio < 0.75) return cs.primary.withAlpha(180);
    return cs.primary;
  }
}

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 14,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

int _computeDisciplineScore({
  required int todayRate,
  required int weekRate,
  required int monthRate,
  required int bestStreak,
}) {
  final streakPart = bestStreak >= 30 ? 25 : ((bestStreak / 30) * 25).round();
  final score = (todayRate * 0.20) +
      (weekRate * 0.35) +
      (monthRate * 0.20) +
      streakPart;
  return score.round().clamp(0, 100);
}

String _weekdayLabel(int index) {
  const labels = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  return labels[index];
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<DateTime> weekMondayToSunday(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}