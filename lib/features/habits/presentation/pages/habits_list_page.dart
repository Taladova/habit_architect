import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_only.dart';
import '../providers/habits_controller.dart';
import '../providers/habits_providers.dart';

class HabitsListPage extends ConsumerStatefulWidget {
  const HabitsListPage({super.key});

  @override
  ConsumerState<HabitsListPage> createState() => _HabitsListPageState();
}

class _HabitsListPageState extends ConsumerState<HabitsListPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final habitsController = ref.read(habitsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Architect')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
  key: const Key('addHabitTextField'),
  controller: _controller,
  decoration: const InputDecoration(
    hintText: 'Nouvelle habitude (ex: Lecture)',
    border: OutlineInputBorder(),
  ),
),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
  key: const Key('addHabitButton'),
  onPressed: () async {
    final name = _controller.text;
    _controller.clear();
    await habitsController.addHabit(name);
  },
  child: const Text('Ajouter'),
),
              ],
            ),
          ),
          Expanded(
  child: habitsAsync.when(
    data: (habits) {
      if (habits.isEmpty) {
        return const Center(
          child: Text('Aucune habitude. Ajoute la première 👇'),
        );
      }

      final today = dateOnly(DateTime.now());

      return ListView.separated(
        itemCount: habits.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final h = habits[i];
          final doneToday = h.completedDays.map(dateOnly).contains(today);

          return ListTile(
            key: Key('habitTile_${h.id}'),
            title: Text(h.name),
            subtitle: Text('Complétions: ${h.completedDays.length}'),
            trailing: Icon(
              doneToday ? Icons.check_circle : Icons.circle_outlined,
            ),
            onTap: () => habitsController.toggleToday(h.id),
          );
        },
      );
    },
    loading: () => const Center(
      child: CircularProgressIndicator(key: Key('habitsLoading')),
    ),
    error: (e, st) => const SizedBox.shrink(),
  ),
),
        ],
      ),
    );
  }
}
