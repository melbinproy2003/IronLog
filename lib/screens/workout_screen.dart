import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/exercise_set_model.dart';
import '../models/workout_model.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/date_picker_bar.dart';
import '../widgets/exercise_card.dart';

/// Screen to log or edit a workout: pick date, exercise name, add sets, save.
/// Can also be used for planned workouts when planId and planDayId are provided.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    this.initialWorkout,
    this.planId,
    this.planDayId,
  });

  /// If provided, the screen edits this workout instead of creating a new one.
  final Workout? initialWorkout;
  
  /// If provided with planDayId, pre-fills workout from plan and locks exercise editing.
  final String? planId;
  
  /// Plan day id (required if planId is provided).
  final String? planDayId;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  late Workout _workout;
  late TextEditingController _exerciseNameController;
  bool _isFromPlan = false;
  String? _planDayName;

  @override
  void initState() {
    super.initState();
    _isFromPlan = widget.planId != null && widget.planDayId != null;
    
    if (widget.initialWorkout != null) {
      _workout = widget.initialWorkout!;
    } else if (_isFromPlan) {
      // Will be initialized from plan in build
      _workout = createNewWorkout(
        date: DateTime.now(),
        exerciseName: '',
        targetReps: kDefaultTargetReps,
      ).copyWith(
        planId: widget.planId,
        planDayId: widget.planDayId,
        sets: [const ExerciseSet(weight: 0, reps: 0)],
      );
    } else {
      _workout = createNewWorkout(
        date: DateTime.now(),
        exerciseName: '',
        targetReps: kDefaultTargetReps,
      ).copyWith(sets: [const ExerciseSet(weight: 0, reps: 0)]);
    }
    _exerciseNameController = TextEditingController(text: _workout.exerciseName);
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
    String displayName;
    if (_isFromPlan) {
      // Exercise name is locked from plan
      displayName = _workout.exerciseName;
    } else {
      final rawName = _exerciseNameController.text;
      displayName = canonicalExerciseName(rawName);
      if (displayName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an exercise name')),
        );
        return;
      }
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
      planId: widget.planId,
      planDayId: widget.planDayId,
    );
    
    await ref.read(workoutNotifierProvider.notifier).saveWorkout(toSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved')),
      );
      if (widget.initialWorkout != null || _isFromPlan) {
        // Editing existing workout or planned workout: go back to previous screen.
        Navigator.of(context).pop();
      } else {
        // New workout: reset form for quick entry.
        _exerciseNameController.clear();
        setState(() {
          _workout = createNewWorkout(
            date: _workout.date,
            exerciseName: '',
            targetReps: kDefaultTargetReps,
          ).copyWith(sets: [const ExerciseSet(weight: 0, reps: 0)]);
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final id = _workout.id;
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete workout'),
            content: const Text(
              'Are you sure you want to delete this workout? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    await ref.read(workoutNotifierProvider.notifier).deleteWorkout(id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If from plan, fetch plan day and pre-fill workout
    if (_isFromPlan && widget.planId != null && widget.planDayId != null) {
      final planDayAsync = ref.watch(
        planDayProvider((planId: widget.planId!, dayId: widget.planDayId!)),
      );
      
      return planDayAsync.when(
        data: (planDay) {
          if (planDay != null && _workout.exerciseName.isEmpty) {
            // Pre-fill from plan (only once)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final exercise = planDay.exercises.isNotEmpty ? planDay.exercises.first : null;
                if (exercise != null) {
                  setState(() {
                    _planDayName = planDay.name;
                    _workout = _workout.copyWith(
                      exerciseName: exercise.exerciseName,
                      sets: List.generate(
                        exercise.sets,
                        (_) => ExerciseSet(weight: exercise.currentWeight, reps: 0),
                      ),
                      targetReps: exercise.maxReps,
                    );
                    _exerciseNameController.text = exercise.exerciseName;
                  });
                }
              }
            });
          }
          return _buildBody(context, planDay?.name);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Loading plan...')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load plan: $e')),
        ),
      );
    }
    
    return _buildBody(context, null);
  }
  
  Widget _buildBody(BuildContext context, String? planDayName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialWorkout != null
              ? 'Edit workout'
              : _isFromPlan
                  ? 'Plan Workout'
                  : 'Log workout',
        ),
        actions: [
          if (widget.initialWorkout != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete workout',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isFromPlan && planDayName != null)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          planDayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isFromPlan && planDayName != null) const SizedBox(height: 8),
            DatePickerBar(
              selectedDate: _workout.date,
              onDateChanged: _onDateChanged,
            ),
            const SizedBox(height: 8),
            _isFromPlan
                ? TextField(
                    controller: _exerciseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                      border: OutlineInputBorder(),
                      enabled: false,
                      helperText: 'Exercise locked from plan',
                    ),
                  )
                : TextField(
                    controller: _exerciseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _workout = _workout.copyWith(exerciseName: v)),
                  ),
            const SizedBox(height: 8),
            ExerciseCard(
              workout: _workout,
              onWorkoutChanged: _onWorkoutChanged,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save workout'),
            ),
          ],
        ),
      ),
    );
  }
}
