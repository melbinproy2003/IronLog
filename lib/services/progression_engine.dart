import '../core/constants.dart';
import '../core/utils.dart';
import '../models/workout_model.dart';
import 'stats_service.dart';

/// Result of progression analysis for one exercise.
class ProgressionResult {
  const ProgressionResult({
    this.suggestWeightChangeKg,
    this.fatigueWarning = false,
    this.suggestDeload = false,
    this.messages = const [],
    this.nextSuggestedWeight,
    this.isDeloadWeek = false,
  });

  /// If non-null, suggest adding this many kg (positive) or reducing (negative).
  final double? suggestWeightChangeKg;

  /// True if weekly volume increased >20% and user should be warned.
  final bool fatigueWarning;

  /// True if 1RM dropped for 2+ weeks; suggest deload.
  final bool suggestDeload;

  final List<String> messages;

  /// Suggested weight for next workout (calculated from last weight + change).
  final double? nextSuggestedWeight;

  /// True if this is a deload week (weight reduced to 90%).
  final bool isDeloadWeek;
}

/// Rule-based progression logic. Stateless; pass in workout history.
///
/// Rules: (1) Target reps hit 2–3 sessions → +2.5 kg.
/// (2) Target reps failed 2 sessions → -5% weight.
/// (3) Weekly volume up >20% → fatigue warning.
/// (4) 1RM down for 2 consecutive weeks → suggest deload.
class ProgressionEngine {
  /// Analyzes recent [workouts] for [exerciseName] and returns suggestions.
  /// [workouts] should be ordered by date ascending (oldest first).
  static ProgressionResult analyze({
    required List<Workout> workouts,
    required String exerciseName,
  }) {
    final forExercise = workouts
        .where((w) => w.exerciseName == exerciseName)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (forExercise.isEmpty) {
      return const ProgressionResult();
    }

    final messages = <String>[];
    double? suggestWeightChangeKg;
    var fatigueWarning = false;
    var suggestDeload = false;

    // Rule: target reps hit 2-3 sessions -> suggest +2.5 kg
    final hitSessions = _countSessionsHittingTarget(forExercise);
    if (hitSessions >= kSessionsToSuggestIncreaseMin &&
        hitSessions <= kSessionsToSuggestIncreaseMax) {
      suggestWeightChangeKg = kProgressionWeightIncrementKg;
      messages.add('Add ${kProgressionWeightIncrementKg} kg');
    }

    // Rule: target reps failed 2 sessions -> suggest -5% weight
    final failSessions = _countSessionsFailingTarget(forExercise);
    if (failSessions >= kSessionsToSuggestDecrease) {
      final lastWeight = _lastUsedWeight(forExercise);
      if (lastWeight != null && lastWeight > 0) {
        final reduced = lastWeight * kProgressionWeightReduceFactor;
        suggestWeightChangeKg = reduced - lastWeight; // negative
        messages.add('Reduce weight by 5% (try ${reduced.toStringAsFixed(1)} kg)');
      }
    }

    // Rule: weekly volume up >20% -> fatigue warning
    final weeklyVolumes = StatsService.weeklyVolumePerExercise(workouts);
    final volumes = weeklyVolumes[exerciseName];
    if (volumes != null && volumes.length >= 2) {
      final prev = volumes[volumes.length - 2].volume;
      final curr = volumes[volumes.length - 1].volume;
      if (prev > 0 && curr >= prev * kVolumeIncreaseFatigueThreshold) {
        fatigueWarning = true;
        messages.add('High volume jump – consider recovery');
      }
    }

    // Rule: 1RM down for 2 consecutive weeks -> suggest deload
    final weekly1RM = StatsService.weeklyBest1RMPerExercise(workouts);
    final weeklyForExercise = weekly1RM[exerciseName];
    if (weeklyForExercise != null && weeklyForExercise.length >= 3) {
      final last = weeklyForExercise.last.oneRm;
      final prev1 = weeklyForExercise[weeklyForExercise.length - 2].oneRm;
      final prev2 = weeklyForExercise[weeklyForExercise.length - 3].oneRm;
      if (last < prev1 && prev1 < prev2) {
        suggestDeload = true;
        messages.add('1RM dropped for 2 weeks – consider deload');
      }
    }

    // Calculate nextSuggestedWeight and isDeloadWeek
    double? nextSuggestedWeight;
    var isDeloadWeek = false;
    final lastWeight = _lastUsedWeight(forExercise);

    if (lastWeight != null && lastWeight > 0) {
      if (suggestDeload) {
        // Deload: reduce to 90% of last weight
        nextSuggestedWeight = lastWeight * 0.9;
        isDeloadWeek = true;
      } else if (suggestWeightChangeKg != null) {
        // Normal progression: last weight + change
        nextSuggestedWeight = lastWeight + suggestWeightChangeKg;
      }
    }

    return ProgressionResult(
      suggestWeightChangeKg: suggestWeightChangeKg,
      fatigueWarning: fatigueWarning,
      suggestDeload: suggestDeload,
      messages: messages,
      nextSuggestedWeight: nextSuggestedWeight,
      isDeloadWeek: isDeloadWeek,
    );
  }

  static int _countSessionsHittingTarget(List<Workout> forExercise) {
    var count = 0;
    for (final w in forExercise.reversed) {
      final target = w.targetReps ?? kDefaultTargetReps;
      final hit = w.sets.any((s) => s.reps >= target);
      if (hit) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  static int _countSessionsFailingTarget(List<Workout> forExercise) {
    var count = 0;
    for (final w in forExercise.reversed) {
      final target = w.targetReps ?? kDefaultTargetReps;
      final hit = w.sets.any((s) => s.reps >= target);
      if (!hit && w.sets.isNotEmpty) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  static double? _lastUsedWeight(List<Workout> forExercise) {
    if (forExercise.isEmpty) return null;
    final last = forExercise.last;
    if (last.sets.isEmpty) return null;
    return last.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }
}
