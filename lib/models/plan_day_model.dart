import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'plan_exercise_model.dart';

/// A single day within a structured training plan (e.g. Push, Pull).
@immutable
class PlanDay {
  const PlanDay({
    required this.id,
    required this.name,
    required this.dayIndex,
    required this.exercises,
  });

  final String id;
  final String name;
  final int dayIndex;
  final List<PlanExercise> exercises;

  PlanDay copyWith({
    String? id,
    String? name,
    int? dayIndex,
    List<PlanExercise>? exercises,
  }) {
    return PlanDay(
      id: id ?? this.id,
      name: name ?? this.name,
      dayIndex: dayIndex ?? this.dayIndex,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// Hive adapter for [PlanDay]. TypeId 3.
class PlanDayAdapter extends TypeAdapter<PlanDay> {
  @override
  int get typeId => 3;

  @override
  PlanDay read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final dayIndex = reader.readInt();
    final count = reader.readInt();
    final exercises = <PlanExercise>[
      for (var i = 0; i < count; i++) reader.read() as PlanExercise,
    ];
    return PlanDay(
      id: id,
      name: name,
      dayIndex: dayIndex,
      exercises: exercises,
    );
  }

  @override
  void write(BinaryWriter writer, PlanDay obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.dayIndex);
    writer.writeInt(obj.exercises.length);
    for (final ex in obj.exercises) {
      writer.write(ex);
    }
  }
}

