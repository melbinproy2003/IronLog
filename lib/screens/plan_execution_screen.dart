import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/exercise_set_model.dart';
import '../models/plan_day_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/workout_model.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/date_picker_bar.dart';
import '../widgets/exercise_card.dart';
import 'plan_day_selector.dart';

/// Screen for executing a planned workout day.
/// Shows exercise details clearly and allows logging sets.
class PlanExecutionScreen extends ConsumerStatefulWidget {
  const PlanExecutionScreen({
    super.key,
    required this.planId,
    this.planDayId,
  });

  final String planId;
  final String? planDayId;

  @override
  ConsumerState<PlanExecutionScreen> createState() => _PlanExecutionScreenState();
}

class _PlanExecutionScreenState extends ConsumerState<PlanExecutionScreen> {
  final Map<String, Workout> _workoutsByExerciseId = {};
  DateTime _selectedDate = DateTime.now();
  String? _selectedDayId;
  bool _isLoadingWorkouts = false;
  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();
    _selectedDayId = widget.planDayId;
  }

  void _onDateChanged(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoadingWorkouts = true;
    });
    await _loadWorkoutsForDate(date);
  }

  void _onDaySelected(String? dayId) async {
    setState(() {
      _selectedDayId = dayId;
      _workoutsByExerciseId.clear();
      _isLoadingWorkouts = true;
      _hasLoadedInitial = false;
    });
    if (dayId != null) {
      await _loadWorkoutsForDate(_selectedDate);
    } else {
      setState(() => _isLoadingWorkouts = false);
    }
  }

  /// Loads workouts for the current plan day and date.
  /// If workouts exist for this date, loads them.
  /// Otherwise, uses most recent workout's weight or plan's currentWeight.
  Future<void> _loadWorkoutsForDate(DateTime date) async {
    if (_selectedDayId == null) {
      setState(() => _isLoadingWorkouts = false);
      return;
    }

    final hive = ref.read(hiveServiceProvider);
    await hive.open();
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final planRepo = ref.read(planRepositoryProvider);
    final planService = ref.read(planServiceProvider);
    await planService.open();

    // Check for existing workouts on this date
    final existingWorkouts = workoutRepo.getWorkoutsForPlanDay(
      planId: widget.planId,
      planDayId: _selectedDayId!,
      date: date,
    );

    final planDay = planRepo.getPlanDay(widget.planId, _selectedDayId!);
    if (planDay == null) {
      setState(() => _isLoadingWorkouts = false);
      return;
    }

    if (existingWorkouts.isNotEmpty) {
      // Load existing workouts - group by exercise name
      final workoutsByExerciseName = <String, Workout>{};
      for (final workout in existingWorkouts) {
        workoutsByExerciseName[workout.exerciseName] = workout;
      }

      // Map to exercise IDs and merge with planned structure
      final loadedWorkouts = <String, Workout>{};
      for (final exercise in planDay.exercises) {
        final existingWorkout = workoutsByExerciseName[exercise.exerciseName];
        
        if (existingWorkout != null) {
          // Merge saved sets with planned structure
          final mergedSets = _mergeSetsWithPlan(
            savedSets: existingWorkout.sets,
            plannedSets: exercise.sets,
            defaultWeight: exercise.currentWeight,
          );
          
          // Preserve workout ID and progressionApplied flag from existing workout
          // Ensure progressionApplied is always a valid bool (handle old data)
          final preservedProgressionApplied = existingWorkout.progressionApplied;
          loadedWorkouts[exercise.id] = existingWorkout.copyWith(
            sets: mergedSets,
            date: date, // Ensure date matches selected date
            planId: widget.planId,
            planDayId: _selectedDayId,
            targetReps: exercise.maxReps,
            progressionApplied: preservedProgressionApplied, // Explicitly preserve the flag
          );
        } else {
          // No saved workout for this exercise - initialize fresh
          loadedWorkouts[exercise.id] = createNewWorkout(
            date: date,
            exerciseName: exercise.exerciseName,
            targetReps: exercise.maxReps,
          ).copyWith(
            planId: widget.planId,
            planDayId: _selectedDayId,
            sets: List.generate(
              exercise.sets,
              (_) => ExerciseSet(weight: exercise.currentWeight, reps: 0),
            ),
          );
        }
      }

      setState(() {
        _workoutsByExerciseId.clear();
        _workoutsByExerciseId.addAll(loadedWorkouts);
        _isLoadingWorkouts = false;
      });
    } else {
      // No workouts for this date - check for most recent workout
      final mostRecent = workoutRepo.getMostRecentWorkoutForPlanDay(
        planId: widget.planId,
        planDayId: _selectedDayId!,
      );

      // Initialize workouts with weights from most recent or plan
      final initializedWorkouts = <String, Workout>{};
      for (final exercise in planDay.exercises) {
        double startingWeight = exercise.currentWeight;

        // If we have a most recent workout for this exercise, use its weight
        if (mostRecent != null && mostRecent.exerciseName == exercise.exerciseName) {
          final recentSets = mostRecent.sets.where((s) => s.weight > 0).toList();
          if (recentSets.isNotEmpty) {
            // Use average weight from most recent workout
            final avgWeight = recentSets.map((s) => s.weight).reduce((a, b) => a + b) /
                recentSets.length;
            startingWeight = avgWeight;
          }
        }

        initializedWorkouts[exercise.id] = createNewWorkout(
          date: date,
          exerciseName: exercise.exerciseName,
          targetReps: exercise.maxReps,
        ).copyWith(
          planId: widget.planId,
          planDayId: _selectedDayId,
          sets: List.generate(
            exercise.sets,
            (_) => ExerciseSet(weight: startingWeight, reps: 0),
          ),
        );
      }

      setState(() {
        _workoutsByExerciseId.clear();
        _workoutsByExerciseId.addAll(initializedWorkouts);
        _isLoadingWorkouts = false;
      });
    }
  }

  void _onWorkoutChanged(String exerciseId, Workout workout) {
    setState(() {
      _workoutsByExerciseId[exerciseId] = workout;
    });
  }

  /// Merges saved sets with planned structure.
  /// Always returns a list with exactly [plannedSets] number of sets.
  /// Fills missing slots with empty placeholders using [defaultWeight].
  List<ExerciseSet> _mergeSetsWithPlan({
    required List<ExerciseSet> savedSets,
    required int plannedSets,
    required double defaultWeight,
  }) {
    final merged = <ExerciseSet>[];
    
    // Use saved sets up to plannedSets count
    for (var i = 0; i < plannedSets; i++) {
      if (i < savedSets.length) {
        // Use saved set
        merged.add(savedSets[i]);
      } else {
        // Fill with empty placeholder
        // Use weight from last saved set if available, otherwise use defaultWeight
        final placeholderWeight = savedSets.isNotEmpty && savedSets.last.weight > 0
            ? savedSets.last.weight
            : defaultWeight;
        merged.add(ExerciseSet(weight: placeholderWeight, reps: 0));
      }
    }
    
    return merged;
  }

  Future<void> _saveAllWorkouts() async {
    if (_selectedDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a plan day first')),
      );
      return;
    }

    final planDay = await ref.read(
      planDayProvider((planId: widget.planId, dayId: _selectedDayId!)).future,
    );
    if (planDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan day not found')),
      );
      return;
    }

    // Allow partial saving: save workouts that have at least one valid set
    // Note: We save only valid sets, but UI always shows full planned structure
    final workoutsToSave = <Workout>[];
    final loggedRepsByExerciseId = <String, List<int>>{};

    for (final exercise in planDay.exercises) {
      final workout = _workoutsByExerciseId[exercise.id];
      if (workout == null) continue;

      // Filter to only valid sets (weight > 0 and reps > 0)
      // This preserves historical data - we only save what was actually logged
      final validSets = workout.sets.where((s) => s.weight > 0 && s.reps > 0).toList();
      
      // Only save if at least one set is valid
      if (validSets.isNotEmpty) {
        // Preserve workout ID if it's an existing workout (for updates)
        final workoutToSave = workout.copyWith(
          date: _selectedDate,
          planId: widget.planId,
          planDayId: _selectedDayId,
          sets: validSets, // Save only valid sets, not empty placeholders
        );
        workoutsToSave.add(workoutToSave);
        loggedRepsByExerciseId[exercise.id] = validSets.map((s) => s.reps).toList();
      }
    }

    if (workoutsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one set with weight and reps')),
      );
      return;
    }

    // Save all workouts
    // WorkoutNotifier will check progressionApplied flag and apply progression only if needed
    // Existing workouts loaded from _workoutsByExerciseId already have their progressionApplied flag preserved
    for (final workout in workoutsToSave) {
      await ref.read(workoutNotifierProvider.notifier).saveWorkout(workout);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${workoutsToSave.length} workout${workoutsToSave.length != 1 ? 's' : ''}',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePlanAsync = ref.watch(activePlanProvider);

    return activePlanAsync.when(
      data: (plan) {
        if (plan == null || plan.id != widget.planId) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plan Workout')),
            body: const Center(child: Text('Plan not found')),
          );
        }

        final selectedDayId = _selectedDayId ?? plan.days.firstOrNull?.id;
        if (selectedDayId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plan Workout')),
            body: const Center(child: Text('No days in plan')),
          );
        }

        // Update selected day if it changed
        if (_selectedDayId != selectedDayId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedDayId = selectedDayId);
            _loadWorkoutsForDate(_selectedDate);
          });
        }

        final planDayAsync = ref.watch(
          planDayProvider((planId: widget.planId, dayId: selectedDayId)),
        );

        return planDayAsync.when(
          data: (planDay) {
            if (planDay == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Plan Workout')),
                body: const Center(child: Text('Day not found')),
              );
            }

            // Load workouts when plan day is first loaded
            if (!_hasLoadedInitial && !_isLoadingWorkouts) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _hasLoadedInitial = true;
                _loadWorkoutsForDate(_selectedDate);
              });
            }

            if (_isLoadingWorkouts) {
              return Scaffold(
                appBar: AppBar(title: Text(plan.name)),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(plan.name),
                actions: [
                  TextButton(
                    onPressed: _saveAllWorkouts,
                    child: const Text('Save'),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlanDaySelector(
                      plan: plan,
                      selectedDayId: selectedDayId,
                      onDaySelected: _onDaySelected,
                    ),
                    const SizedBox(height: 16),
                    DatePickerBar(
                      selectedDate: _selectedDate,
                      onDateChanged: _onDateChanged,
                    ),
                    const SizedBox(height: 16),
                    ...planDay.exercises.map((exercise) {
                      // Get workout from loaded state, or create default if not loaded yet
                      final workout = _workoutsByExerciseId[exercise.id] ??
                          createNewWorkout(
                            date: _selectedDate,
                            exerciseName: exercise.exerciseName,
                            targetReps: exercise.maxReps,
                          ).copyWith(
                            planId: widget.planId,
                            planDayId: selectedDayId,
                            sets: List.generate(
                              exercise.sets,
                              (_) => ExerciseSet(
                                weight: exercise.currentWeight,
                                reps: 0,
                              ),
                            ),
                          );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.exerciseName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: Icons.repeat,
                                    label: '${exercise.sets} sets',
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.fitness_center,
                                    label: '${exercise.minReps}-${exercise.maxReps} reps',
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.scale,
                                    label: '${exercise.currentWeight}kg',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ExerciseCard(
                                workout: workout,
                                onWorkoutChanged: (w) => _onWorkoutChanged(exercise.id, w),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Plan Workout')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Plan Workout')),
            body: Center(child: Text('Error: $e')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Plan Workout')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Plan Workout')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
