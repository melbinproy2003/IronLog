import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// A single set: weight, reps, and optional completion flag.
@immutable
class ExerciseSet {
  const ExerciseSet({
    required this.weight,
    required this.reps,
    this.completed = true,
  });

  final double weight;
  final int reps;
  final bool completed;

  ExerciseSet copyWith({
    double? weight,
    int? reps,
    bool? completed,
  }) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
    );
  }
}

/// Hive adapter for [ExerciseSet]. TypeId 0.
class ExerciseSetAdapter extends TypeAdapter<ExerciseSet> {
  @override
  final int typeId = 0;

  @override
  ExerciseSet read(BinaryReader reader) {
    final weight = reader.readDouble();
    final reps = reader.readInt();
    final completed = reader.readBool();
    return ExerciseSet(weight: weight, reps: reps, completed: completed);
  }

  @override
  void write(BinaryWriter writer, ExerciseSet obj) {
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.reps);
    writer.writeBool(obj.completed);
  }
}
