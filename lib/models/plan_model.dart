import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'plan_day_model.dart';

/// A structured training plan composed of multiple days.
@immutable
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.days,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<PlanDay> days;

  Plan copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<PlanDay>? days,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      days: days ?? this.days,
    );
  }
}

/// Hive adapter for [Plan]. TypeId 4.
class PlanAdapter extends TypeAdapter<Plan> {
  @override
  int get typeId => 4;

  @override
  Plan read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final createdAtMillis = reader.readInt();
    final count = reader.readInt();
    final days = <PlanDay>[
      for (var i = 0; i < count; i++) reader.read() as PlanDay,
    ];
    return Plan(
      id: id,
      name: name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      days: days,
    );
  }

  @override
  void write(BinaryWriter writer, Plan obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.days.length);
    for (final day in obj.days) {
      writer.write(day);
    }
  }
}

