import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/workout_model.dart';

/// Local persistence for workouts. CRUD and queries only; no progression/coach logic.
class HiveService {
  Box<Workout>? _box;

  /// Opens the workout box. Call once at app startup (after Hive.initFlutter).
  Future<void> open() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Workout>(kWorkoutBoxName);
  }

  Box<Workout> get _store {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('HiveService not opened. Call open() first.');
    }
    return box;
  }

  /// Saves a workout. Uses [Workout.id] as key; overwrites if id exists.
  Future<void> saveWorkout(Workout workout) async {
    await _store.put(workout.id, workout);
  }

  /// Deletes a workout by id.
  Future<void> deleteWorkout(String id) async {
    await _store.delete(id);
  }

  /// Returns workout by id, or null.
  Workout? getWorkout(String id) => _store.get(id);

  /// Returns all workouts in the box.
  List<Workout> getAllWorkouts() {
    return _store.values.toList();
  }

  /// Returns workouts whose date is in [start] (inclusive) to [end] (inclusive).
  List<Workout> getWorkoutsInRange(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return _store.values.where((w) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      return !d.isBefore(startDay) && !d.isAfter(endDay);
    }).toList();
  }

  /// Workouts on the given calendar day (any time that day).
  List<Workout> getWorkoutsOnDate(DateTime date) {
    return getWorkoutsInRange(date, date);
  }

  /// Unique exercise names across all stored workouts.
  ///
  /// Internally normalizes names by key (trim/case/spacing) to avoid duplicates,
  /// but returns nicely formatted display names.
  List<String> getAllExerciseNames() {
    final byKey = <String, String>{};
    for (final w in _store.values) {
      final key = normalizeExerciseKey(w.exerciseName);
      if (key.isEmpty) continue;
      byKey.putIfAbsent(key, () => canonicalExerciseName(w.exerciseName));
    }
    final values = byKey.values.toList()..sort();
    return values;
  }

  /// Finds workouts for a specific plan day on a specific date.
  /// Returns workouts matching planId, planDayId, and date.
  List<Workout> getWorkoutsForPlanDay({
    required String planId,
    required String planDayId,
    required DateTime date,
  }) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _store.values.where((w) {
      if (w.planId != planId || w.planDayId != planDayId) return false;
      final workoutDate = DateTime(w.date.year, w.date.month, w.date.day);
      return workoutDate == targetDate;
    }).toList();
  }

  /// Finds the most recent workout for a specific plan day (any date).
  /// Returns the workout with the latest date, or null if none exists.
  Workout? getMostRecentWorkoutForPlanDay({
    required String planId,
    required String planDayId,
  }) {
    final matchingWorkouts = _store.values
        .where((w) => w.planId == planId && w.planDayId == planDayId)
        .toList();

    if (matchingWorkouts.isEmpty) return null;

    matchingWorkouts.sort((a, b) => b.date.compareTo(a.date));
    return matchingWorkouts.first;
  }

  /// Finds the most recent workout for a specific exercise name (any date, any plan).
  /// Returns the workout with the latest date, or null if none exists.
  Workout? getMostRecentWorkoutForExercise(String exerciseName) {
    final normalizedName = exerciseName.toLowerCase().trim();
    final matchingWorkouts = _store.values
        .where((w) => w.exerciseName.toLowerCase().trim() == normalizedName)
        .toList();

    if (matchingWorkouts.isEmpty) return null;

    matchingWorkouts.sort((a, b) => b.date.compareTo(a.date));
    return matchingWorkouts.first;
  }
}
