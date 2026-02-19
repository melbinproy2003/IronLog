import 'package:flutter/material.dart';

import '../models/exercise_set_model.dart';
import '../models/workout_model.dart';
import 'set_tile.dart';

/// Card showing exercise name and list of sets with add/remove.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.workout,
    required this.onWorkoutChanged,
  });

  final Workout workout;
  final ValueChanged<Workout> onWorkoutChanged;

  void _addSet() {
    final newSets = [...workout.sets, const ExerciseSet(weight: 0, reps: 0)];
    onWorkoutChanged(workout.copyWith(sets: newSets));
  }

  void _updateSet(int index, ExerciseSet set) {
    final newSets = workout.sets.toList();
    if (index >= 0 && index < newSets.length) {
      newSets[index] = set;
      onWorkoutChanged(workout.copyWith(sets: newSets));
    }
  }

  void _removeSet(int index) {
    if (workout.sets.length <= 1) return;
    final newSets = workout.sets.toList()..removeAt(index);
    onWorkoutChanged(workout.copyWith(sets: newSets));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.exerciseName.isEmpty ? 'Exercise' : workout.exerciseName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...workout.sets.asMap().entries.map((e) => SetTile(
                  set: e.value,
                  index: e.key,
                  onChanged: (s) => _updateSet(e.key, s),
                  onRemove:
                      workout.sets.length > 1 ? () => _removeSet(e.key) : null,
                )),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}
