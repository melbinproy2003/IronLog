import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/graph_type.dart';
import '../core/utils.dart';
import '../models/workout_model.dart';
import 'workout_provider.dart';

/// Selected graph type on Progress screen.
final graphTypeProvider =
    StateProvider<GraphType>((ref) => GraphType.oneRM);

/// Workout analyzer data for an exercise: date, total volume, and workout for session list.
class WorkoutAnalyzerPoint {
  const WorkoutAnalyzerPoint({
    required this.date,
    required this.totalVolume,
    required this.workout,
  });

  final DateTime date;
  final double totalVolume;
  final Workout workout;
}

/// Fetches all workouts for [exerciseName], sorts by date, computes total volume per workout.
/// Returns chart points (date, totalVolume) and full workout for session list.
final workoutAnalyzerDataProvider =
    FutureProvider.family<List<WorkoutAnalyzerPoint>, String>(
        (ref, exerciseName) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  final filtered = workouts
      .where((w) =>
          w.exerciseName.toLowerCase().trim() ==
          exerciseName.toLowerCase().trim())
      .toList();
  filtered.sort((a, b) => a.date.compareTo(b.date));

  return filtered.map((w) {
    final vol = volumeFromSets(
      w.sets.map((s) => (weight: s.weight, reps: s.reps)),
    );
    return WorkoutAnalyzerPoint(
      date: w.date,
      totalVolume: vol,
      workout: w,
    );
  }).toList();
});
