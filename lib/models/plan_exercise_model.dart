import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Planned exercise with double-progression prescription.
/// Double progression: increase weight when all sets hit maxReps.
@immutable
class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exerciseName,
    required this.currentWeight,
    required this.increment,
    required this.sets,
    required this.minReps,
    required this.maxReps,
  });

  final String id;
  final String exerciseName;
  /// Current weight to use for next session.
  final double currentWeight;
  /// Weight increase when progression criteria met (kg).
  final double increment;
  /// Number of sets to perform.
  final int sets;
  /// Minimum reps target per set.
  final int minReps;
  /// Maximum reps target per set (progression threshold).
  final int maxReps;

  PlanExercise copyWith({
    String? id,
    String? exerciseName,
    double? currentWeight,
    double? increment,
    int? sets,
    int? minReps,
    int? maxReps,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      currentWeight: currentWeight ?? this.currentWeight,
      increment: increment ?? this.increment,
      sets: sets ?? this.sets,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
    );
  }
}

/// Hive adapter for [PlanExercise]. TypeId 2.
class PlanExerciseAdapter extends TypeAdapter<PlanExercise> {
  @override
  int get typeId => 2;

  @override
  PlanExercise read(BinaryReader reader) {
    final id = reader.readString();
    final exerciseName = reader.readString();
    final currentWeight = reader.readDouble();
    final increment = reader.readDouble();
    final sets = reader.readInt();
    final minReps = reader.readInt();
    final maxReps = reader.readInt();
    return PlanExercise(
      id: id,
      exerciseName: exerciseName,
      currentWeight: currentWeight,
      increment: increment,
      sets: sets,
      minReps: minReps,
      maxReps: maxReps,
    );
  }

  @override
  void write(BinaryWriter writer, PlanExercise obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.exerciseName);
    writer.writeDouble(obj.currentWeight);
    writer.writeDouble(obj.increment);
    writer.writeInt(obj.sets);
    writer.writeInt(obj.minReps);
    writer.writeInt(obj.maxReps);
  }
}

