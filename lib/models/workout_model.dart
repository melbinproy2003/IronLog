import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'exercise_set_model.dart';

/// A logged workout: date, exercise name, sets, optional target reps.
@immutable
class Workout {
  const Workout({
    required this.id,
    required this.date,
    required this.exerciseName,
    required this.sets,
    this.targetReps,
    this.planId,
    this.planDayId,
    this.adherenceScore,
    this.progressionApplied = false,
  });

  final String id;
  final DateTime date;
  final String exerciseName;
  final List<ExerciseSet> sets;
  final int? targetReps;

  /// Optional reference to the structured plan this workout belongs to.
  final String? planId;

  /// Optional reference to the specific plan day.
  final String? planDayId;

  /// Adherence score to the plan prescription (0.0–1.0).
  final double? adherenceScore;

  /// Whether progression logic has been applied to the plan for this workout.
  /// Prevents duplicate progression when saving the same workout multiple times.
  final bool progressionApplied;

  Workout copyWith({
    String? id,
    DateTime? date,
    String? exerciseName,
    List<ExerciseSet>? sets,
    int? targetReps,
    String? planId,
    String? planDayId,
    double? adherenceScore,
    bool? progressionApplied,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
      planId: planId ?? this.planId,
      planDayId: planDayId ?? this.planDayId,
      adherenceScore: adherenceScore ?? this.adherenceScore,
      progressionApplied: progressionApplied ?? this.progressionApplied,
    );
  }
}

/// Hive adapter for [Workout]. TypeId 1.
class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  int get typeId => 1;

  @override
  Workout read(BinaryReader reader) {
    final id = reader.readString();
    final dateMillis = reader.readInt();
    final exerciseName = reader.readString();
    final setsCount = reader.readInt();
    final sets = <ExerciseSet>[
      for (var i = 0; i < setsCount; i++) reader.read() as ExerciseSet,
    ];
    final hasTargetReps = reader.readBool();
    final targetReps = hasTargetReps ? reader.readInt() : null;

    String? planId;
    String? planDayId;
    double? adherenceScore;
    bool progressionApplied = false;

    // Extra fields are optional; older records may not contain them.
    try {
      final hasExtra = reader.readBool();
      if (hasExtra) {
        final hasPlanId = reader.readBool();
        if (hasPlanId) {
          planId = reader.readString();
        }
        final hasPlanDayId = reader.readBool();
        if (hasPlanDayId) {
          planDayId = reader.readString();
        }
        final hasAdherence = reader.readBool();
        if (hasAdherence) {
          adherenceScore = reader.readDouble();
        }
        // progressionApplied was added later - old data may not have it
        // Try to read it, but if reading fails (end of data), keep default false
        try {
          progressionApplied = reader.readBool();
        } catch (_) {
          // Old data without progressionApplied field: keep default false
          // This happens when the data was written before progressionApplied was added
        }
      }
    } catch (_) {
      // Old data without extra fields: leave plan/adherence/progressionApplied as defaults.
      // progressionApplied is already initialized to false above
    }

    return Workout(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      exerciseName: exerciseName,
      sets: sets,
      targetReps: targetReps,
      planId: planId,
      planDayId: planDayId,
      adherenceScore: adherenceScore,
      progressionApplied: progressionApplied, // Always initialized to false, never null
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeString(obj.exerciseName);
    writer.writeInt(obj.sets.length);
    for (final set in obj.sets) {
      writer.write(set);
    }
    writer.writeBool(obj.targetReps != null);
    if (obj.targetReps != null) {
      writer.writeInt(obj.targetReps!);
    }

    final hasExtra =
        obj.planId != null || obj.planDayId != null || obj.adherenceScore != null || obj.progressionApplied;
    writer.writeBool(hasExtra);
    if (hasExtra) {
      writer.writeBool(obj.planId != null);
      if (obj.planId != null) {
        writer.writeString(obj.planId!);
      }
      writer.writeBool(obj.planDayId != null);
      if (obj.planDayId != null) {
        writer.writeString(obj.planDayId!);
      }
      writer.writeBool(obj.adherenceScore != null);
      if (obj.adherenceScore != null) {
        writer.writeDouble(obj.adherenceScore!);
      }
      writer.writeBool(obj.progressionApplied);
    }
  }
}

