import '../core/utils.dart';
import '../models/workout_model.dart';

/// Derives best 1RM and weekly volume from workout history. Pure logic; no UI.
class StatsService {
  /// Best estimated 1RM per exercise from [workouts].
  /// For each exercise, takes the max of estimated1RM(weight, reps) across all sets.
  static Map<String, double> best1RMPerExercise(List<Workout> workouts) {
    final map = <String, double>{};
    for (final w in workouts) {
      if (w.exerciseName.isEmpty) continue;
      double best = map[w.exerciseName] ?? 0;
      for (final set in w.sets) {
        final oneRm = estimated1RM(set.weight, set.reps);
        if (oneRm > best) best = oneRm;
      }
      map[w.exerciseName] = best;
    }
    return map;
  }

  /// Best estimated 1RM for a single exercise from [workouts].
  static double best1RMForExercise(List<Workout> workouts, String exerciseName) {
    return best1RMPerExercise(workouts)[exerciseName] ?? 0;
  }

  /// Weekly volume per exercise: exercise -> list of (weekStart, volume) sorted by week.
  static Map<String, List<({DateTime weekStart, double volume})>>
      weeklyVolumePerExercise(List<Workout> workouts) {
    final byExerciseAndWeek = <String, Map<DateTime, double>>{};
    for (final w in workouts) {
      if (w.exerciseName.isEmpty) continue;
      final weekStart = startOfWeek(w.date);
      final vol = volumeFromSets(
        w.sets.map((s) => (weight: s.weight, reps: s.reps)),
      );
      byExerciseAndWeek
          .putIfAbsent(w.exerciseName, () => {})
          .update(weekStart, (v) => v + vol, ifAbsent: () => vol);
    }
    final result = <String, List<({DateTime weekStart, double volume})>>{};
    for (final entry in byExerciseAndWeek.entries) {
      final list = entry.value.entries
          .map((e) => (weekStart: e.key, volume: e.value))
          .toList();
      list.sort((a, b) => a.weekStart.compareTo(b.weekStart));
      result[entry.key] = list;
    }
    return result;
  }

  /// Weekly best 1RM per exercise: exercise -> list of (weekStart, best 1RM that week).
  static Map<String, List<({DateTime weekStart, double oneRm})>>
      weeklyBest1RMPerExercise(List<Workout> workouts) {
    final byExerciseAndWeek = <String, Map<DateTime, double>>{};
    for (final w in workouts) {
      if (w.exerciseName.isEmpty) continue;
      final weekStart = startOfWeek(w.date);
      double best = 0;
      for (final set in w.sets) {
        final oneRm = estimated1RM(set.weight, set.reps);
        if (oneRm > best) best = oneRm;
      }
      if (best > 0) {
        byExerciseAndWeek
            .putIfAbsent(w.exerciseName, () => {})
            .update(weekStart, (v) => v > best ? v : best, ifAbsent: () => best);
      }
    }
    final result = <String, List<({DateTime weekStart, double oneRm})>>{};
    for (final entry in byExerciseAndWeek.entries) {
      final list = entry.value.entries
          .map((e) => (weekStart: e.key, oneRm: e.value))
          .toList();
      list.sort((a, b) => a.weekStart.compareTo(b.weekStart));
      result[entry.key] = list;
    }
    return result;
  }

  /// 1RM progression for an exercise: list of (date, estimated 1RM) from best set per workout, sorted by date.
  static List<({DateTime date, double oneRm})> oneRMProgression(
    List<Workout> workouts,
    String exerciseName,
  ) {
    final filtered = workouts
        .where((w) => w.exerciseName == exerciseName)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final list = <({DateTime date, double oneRm})>[];
    for (final w in filtered) {
      double best = 0;
      for (final set in w.sets) {
        final oneRm = estimated1RM(set.weight, set.reps);
        if (oneRm > best) best = oneRm;
      }
      if (best > 0) {
        list.add((date: w.date, oneRm: best));
      }
    }
    return list;
  }
}
