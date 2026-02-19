import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_set_model.dart';
import '../models/workout_model.dart';
import '../services/coach_engine.dart';
import '../services/hive_service.dart';
import '../services/progression_engine.dart';
import '../services/stats_service.dart';
import 'plan_provider.dart';

/// Provides [HiveService]. Override in main with an opened instance after Hive.initFlutter().
final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError(
    'Override hiveServiceProvider in main with an opened HiveService',
  );
});

/// All workouts from storage. Refreshed when [saveWorkout] or [deleteWorkout] is used.
final allWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final hive = ref.watch(hiveServiceProvider);
  await hive.open();
  return hive.getAllWorkouts();
});

/// Workouts for today (calendar day).
final todayWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return workouts
      .where((w) =>
          w.date.year == today.year &&
          w.date.month == today.month &&
          w.date.day == today.day)
      .toList();
});

/// All exercise names (sorted).
final allExerciseNamesProvider = FutureProvider<List<String>>((ref) async {
  final hive = ref.watch(hiveServiceProvider);
  await hive.open();
  return hive.getAllExerciseNames();
});

/// Workouts in the last N days (for progression/coach). Default 56 (8 weeks).
final recentWorkoutsProvider =
    FutureProvider.family<List<Workout>, int>((ref, days) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  final end = DateTime.now();
  final start = end.subtract(Duration(days: days));
  return workouts
      .where((w) => !w.date.isBefore(start) && !w.date.isAfter(end))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

/// Best 1RM per exercise from all stored workouts.
final best1RMPerExerciseProvider = FutureProvider<Map<String, double>>((ref) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  return StatsService.best1RMPerExercise(workouts);
});

/// Progression result for a given exercise (from recent workouts).
final progressionResultProvider =
    FutureProvider.family<ProgressionResult, String>((ref, exerciseName) async {
  final workouts = await ref.watch(recentWorkoutsProvider(56).future);
  return ProgressionEngine.analyze(
    workouts: workouts,
    exerciseName: exerciseName,
  );
});

/// Coach suggestions from recent workout history.
final coachSuggestionsProvider =
    FutureProvider<List<CoachSuggestion>>((ref) async {
  final workouts = await ref.watch(recentWorkoutsProvider(56).future);
  return CoachEngine.suggest(workouts);
});

/// If any exercise has a fatigue warning from progression engine, returns the message; otherwise null.
final fatigueWarningProvider = FutureProvider<String?>((ref) async {
  final names = await ref.watch(allExerciseNamesProvider.future);
  for (final name in names) {
    final result = await ref.watch(progressionResultProvider(name).future);
    if (result.fatigueWarning && result.messages.isNotEmpty) {
      return result.messages.first;
    }
  }
  return null;
});

/// 1RM progression points for chart: (date, oneRm) for [exerciseName].
final oneRMChartDataProvider =
    FutureProvider.family<List<({DateTime date, double oneRm})>, String>(
        (ref, exerciseName) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  return StatsService.oneRMProgression(workouts, exerciseName);
});

/// Weekly volume points for chart: (weekStart, volume) for [exerciseName].
final weeklyVolumeChartDataProvider =
    FutureProvider.family<List<({DateTime weekStart, double volume})>, String>(
        (ref, exerciseName) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  final map = StatsService.weeklyVolumePerExercise(workouts);
  return map[exerciseName] ?? [];
});

/// Suggestion for next workout for a given exercise.
class NextWorkoutSuggestion {
  const NextWorkoutSuggestion({
    required this.exerciseName,
    this.nextSuggestedWeight,
    required this.reason,
    this.isDeload = false,
  });

  final String exerciseName;
  final double? nextSuggestedWeight;
  final String reason;
  final bool isDeload;
}

/// Next workout suggestion for a given exercise (from progression engine).
final nextWorkoutSuggestionProvider =
    FutureProvider.family<NextWorkoutSuggestion?, String>(
        (ref, exerciseName) async {
  final result = await ref.watch(progressionResultProvider(exerciseName).future);
  
  // Return null if no suggestion available
  if (result.nextSuggestedWeight == null) {
    return null;
  }

  // Build reason message from progression result
  String reason;
  if (result.isDeloadWeek) {
    reason = 'Deload week: 1RM dropped for 2 weeks';
  } else if (result.suggestWeightChangeKg != null) {
    if (result.suggestWeightChangeKg! > 0) {
      reason = 'Progression: target reps achieved consistently';
    } else {
      reason = 'Adjustment: reduce weight to maintain form';
    }
  } else {
    reason = 'Continue current progression';
  }

  return NextWorkoutSuggestion(
    exerciseName: exerciseName,
    nextSuggestedWeight: result.nextSuggestedWeight,
    reason: reason,
    isDeload: result.isDeloadWeek,
  );
});

/// First available next workout suggestion (for dashboard display).
/// Returns the first exercise with a suggestion, or null if none exist.
final firstNextWorkoutSuggestionProvider =
    FutureProvider<NextWorkoutSuggestion?>((ref) async {
  final names = await ref.watch(allExerciseNamesProvider.future);
  if (names.isEmpty) return null;

  // Find first exercise with a suggestion
  for (final name in names) {
    final suggestion = await ref.watch(nextWorkoutSuggestionProvider(name).future);
    if (suggestion != null) {
      return suggestion;
    }
  }
  return null;
});

/// Notifier for saving/deleting workouts and invalidating lists.
class WorkoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveWorkout(Workout workout) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.open();
    
    // If this is a planned workout and progression hasn't been applied, update the plan.
    bool shouldApplyProgression = false;
    if (workout.planId != null && workout.planDayId != null && !workout.progressionApplied) {
      shouldApplyProgression = true;
    }
    
    // Save workout first (with progressionApplied flag set if needed)
    Workout workoutToSave = workout;
    if (shouldApplyProgression) {
      workoutToSave = workout.copyWith(progressionApplied: true);
    }
    await hive.saveWorkout(workoutToSave);
    
    // Apply progression logic only if not already applied
    if (shouldApplyProgression) {
      final planService = ref.read(planServiceProvider);
      await planService.open();
      final plan = planService.getPlanById(workout.planId!);
      if (plan != null) {
        final planDay = planService.getPlanDay(workout.planId!, workout.planDayId!);
        if (planDay != null) {
          // Find matching exercise by name
          String? exerciseId;
          for (final ex in planDay.exercises) {
            if (ex.exerciseName == workout.exerciseName) {
              exerciseId = ex.id;
              break;
            }
          }
          
          if (exerciseId != null) {
            final loggedReps = workout.sets.map((s) => s.reps).toList();
            await planService.updateAndSavePlanAfterSession(
              plan: plan,
              dayId: workout.planDayId!,
              loggedRepsByExerciseId: {exerciseId: loggedReps},
            );
            // Invalidate plan providers to refresh UI.
            ref.invalidate(allPlansProvider);
            ref.invalidate(activePlanProvider);
          }
        }
      }
    }
    
    ref.invalidate(allWorkoutsProvider);
    ref.invalidate(todayWorkoutsProvider);
    ref.invalidate(allExerciseNamesProvider);
    ref.invalidate(best1RMPerExerciseProvider);
    ref.invalidate(coachSuggestionsProvider);
  }

  Future<void> deleteWorkout(String id) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.open();
    await hive.deleteWorkout(id);
    ref.invalidate(allWorkoutsProvider);
    ref.invalidate(todayWorkoutsProvider);
    ref.invalidate(allExerciseNamesProvider);
    ref.invalidate(best1RMPerExerciseProvider);
    ref.invalidate(coachSuggestionsProvider);
  }
}

final workoutNotifierProvider =
    AsyncNotifierProvider<WorkoutNotifier, void>(WorkoutNotifier.new);

/// Creates a new workout for the given date and exercise, with empty sets.
Workout createNewWorkout({
  required DateTime date,
  required String exerciseName,
  int? targetReps,
}) {
  return Workout(
    id: const Uuid().v4(),
    date: date,
    exerciseName: exerciseName,
    sets: [],
    targetReps: targetReps,
  );
}
