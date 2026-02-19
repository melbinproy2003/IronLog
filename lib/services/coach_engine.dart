import '../models/workout_model.dart';
import 'progression_engine.dart';
import 'stats_service.dart';

/// Structured suggestion from the coach.
class CoachSuggestion {
  const CoachSuggestion({required this.text, this.priority = 0});

  final String text;
  final int priority;
}

/// Analyzes workout history and returns human-readable suggestions.
/// Reuses [ProgressionEngine] and [StatsService]; no UI dependency.
class CoachEngine {
  /// Returns list of suggestions based on [workouts].
  /// [workouts] should include recent history (e.g. last 4–8 weeks).
  static List<CoachSuggestion> suggest(List<Workout> workouts) {
    final suggestions = <CoachSuggestion>[];
    if (workouts.isEmpty) {
      suggestions.add(const CoachSuggestion(
        text: 'Log your first workout to get personalized suggestions.',
        priority: 0,
      ));
      return suggestions;
    }

    final exerciseNames = <String>{};
    for (final w in workouts) {
      if (w.exerciseName.isNotEmpty) exerciseNames.add(w.exerciseName);
    }

    // Precompute weekly stats for plateau and volume analysis.
    final weeklyVolume = StatsService.weeklyVolumePerExercise(workouts);
    final weeklyBest1RM = StatsService.weeklyBest1RMPerExercise(workouts);

    for (final name in exerciseNames) {
      final result = ProgressionEngine.analyze(
        workouts: workouts,
        exerciseName: name,
      );

      // Deload and fatigue suggestions.
      if (result.suggestDeload) {
        suggestions.add(CoachSuggestion(
          text: '$name: 1RM dropped for 2 weeks – schedule a deload week.',
          priority: 2,
        ));
      }
      if (result.fatigueWarning) {
        suggestions.add(CoachSuggestion(
          text:
              '$name: Volume spike detected – consider a light day or extra recovery.',
          priority: 2,
        ));
      }

      // Direct weight progression suggestions.
      if (result.suggestWeightChangeKg != null) {
        final kg = result.suggestWeightChangeKg!;
        if (kg > 0) {
          suggestions.add(CoachSuggestion(
            text:
                '$name: Great work – progression suggests adding ${kg.toStringAsFixed(1)} kg next session.',
            priority: 1,
          ));
        } else {
          suggestions.add(CoachSuggestion(
            text:
                '$name: Form or fatigue issue – reduce weight by ${(-kg).toStringAsFixed(1)} kg and focus on quality reps.',
            priority: 1,
          ));
        }
      }

      // Plateau detection: little to no 1RM change over recent weeks.
      final oneRmWeeks = weeklyBest1RM[name];
      if (oneRmWeeks != null && oneRmWeeks.length >= 3) {
        final recent = oneRmWeeks.sublist(
          oneRmWeeks.length - 3,
          oneRmWeeks.length,
        );
        final values = recent.map((e) => e.oneRm).toList();
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final plateauThreshold = 2.5; // 2.5 kg window considered plateau.
        if (max - min < plateauThreshold && !result.suggestDeload) {
          suggestions.add(const CoachSuggestion(
            text:
                'Progress plateau detected – add accessory work (e.g. rows, pauses) or adjust rep range.',
            priority: 1,
          ));
        }

        // Consistent progress: clear upward trend across recent weeks.
        if (values[0] < values[1] && values[1] < values[2]) {
          suggestions.add(CoachSuggestion(
            text:
                '$name: Consistent strength gains – stay on this plan and keep logging.',
            priority: 0,
          ));
        }
      }

      // Volume pattern: big weekly increase without explicit fatigue warning.
      final volumes = weeklyVolume[name];
      if (volumes != null && volumes.length >= 2 && !result.fatigueWarning) {
        final last = volumes.last.volume;
        final prev = volumes[volumes.length - 2].volume;
        if (prev > 0 && last > prev * 1.2) {
          suggestions.add(CoachSuggestion(
            text:
                '$name: Volume increased a lot – consider inserting an easier session.',
            priority: 1,
          ));
        }
      }
    }

    final best1RM = StatsService.best1RMPerExercise(workouts);
    if (best1RM.isNotEmpty && suggestions.isEmpty) {
      suggestions.add(const CoachSuggestion(
        text: 'Keep logging. Add an accessory exercise for variety.',
        priority: 0,
      ));
    }

    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions;
  }
}
