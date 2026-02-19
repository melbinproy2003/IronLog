import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/exercise_set_model.dart';
import '../models/workout_model.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import '../services/hive_service.dart';
import '../widgets/date_picker_bar.dart';
import '../widgets/exercise_card.dart';

/// Screen for logging free workouts (not tied to a plan).
/// Allows custom exercises and sets without modifying plan progression.
class FreeWorkoutScreen extends ConsumerStatefulWidget {
  const FreeWorkoutScreen({super.key});

  @override
  ConsumerState<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends ConsumerState<FreeWorkoutScreen> {
  late Workout _workout;
  late TextEditingController _exerciseNameController;
  bool _hasInitializedWeight = false;

  @override
  void initState() {
    super.initState();
    _workout = createNewWorkout(
      date: DateTime.now(),
      exerciseName: '',
      targetReps: kDefaultTargetReps,
    ).copyWith(sets: [const ExerciseSet(weight: 0, reps: 0)]);
    _exerciseNameController = TextEditingController(text: _workout.exerciseName);
  }

  /// Gets the default weight for an exercise name.
  /// Priority: 1) Active plan currentWeight, 2) Last workout weight, 3) Default 0
  Future<double> _getDefaultWeightForExercise(String exerciseName) async {
    // Priority 1: Check active plan
    final activePlan = await ref.read(activePlanProvider.future);
    if (activePlan != null) {
      // Search all plan days for matching exercise
      for (final day in activePlan.days) {
        for (final exercise in day.exercises) {
          if (exercise.exerciseName.toLowerCase().trim() ==
              exerciseName.toLowerCase().trim()) {
            return exercise.currentWeight;
          }
        }
      }
    }

    // Priority 2: Check last workout for this exercise
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.open();
    final lastWorkout = hiveService.getMostRecentWorkoutForExercise(exerciseName);

    if (lastWorkout != null) {
      final validSets = lastWorkout.sets.where((s) => s.weight > 0).toList();
      if (validSets.isNotEmpty) {
        // Use average weight from last workout
        final avgWeight = validSets.map((s) => s.weight).reduce((a, b) => a + b) /
            validSets.length;
        return avgWeight;
      }
    }

    // Priority 3: Default 0
    return 0.0;
  }

  void _onExerciseNameChanged(String value) async {
    setState(() => _workout = _workout.copyWith(exerciseName: value));
    
    // Update weight when exercise name changes (if not already initialized)
    if (value.trim().isNotEmpty && !_hasInitializedWeight) {
      final defaultWeight = await _getDefaultWeightForExercise(value.trim());
      if (mounted && _workout.sets.isNotEmpty) {
        setState(() {
          _hasInitializedWeight = true;
          final updatedSets = _workout.sets.map((set) {
            // Only update if weight is 0 (default)
            return set.weight == 0
                ? set.copyWith(weight: defaultWeight)
                : set;
          }).toList();
          _workout = _workout.copyWith(sets: updatedSets);
        });
      }
    }
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _workout = _workout.copyWith(date: date);
    });
  }

  void _onWorkoutChanged(Workout w) {
    setState(() => _workout = w);
  }

  Future<void> _save() async {
    final rawName = _exerciseNameController.text;
    final displayName = canonicalExerciseName(rawName);
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an exercise name')),
      );
      return;
    }

    final validSets = _workout.sets
        .where((s) => s.weight > 0 && s.reps > 0)
        .toList();
    if (validSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one set with weight and reps')),
      );
      return;
    }

    final toSave = _workout.copyWith(
      sets: validSets,
      exerciseName: displayName,
      planId: null, // Explicitly no plan
      planDayId: null,
    );

    await ref.read(workoutNotifierProvider.notifier).saveWorkout(toSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved')),
      );
      // Reset form for quick entry
      _exerciseNameController.clear();
      setState(() {
        _hasInitializedWeight = false;
        _workout = createNewWorkout(
          date: _workout.date,
          exerciseName: '',
          targetReps: kDefaultTargetReps,
        ).copyWith(sets: [const ExerciseSet(weight: 0, reps: 0)]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Workout'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free workout - not tied to any plan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DatePickerBar(
              selectedDate: _workout.date,
              onDateChanged: _onDateChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exerciseNameController,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                border: OutlineInputBorder(),
              ),
              onChanged: _onExerciseNameChanged,
            ),
            const SizedBox(height: 8),
            ExerciseCard(
              workout: _workout,
              onWorkoutChanged: _onWorkoutChanged,
            ),
          ],
        ),
      ),
    );
  }
}
