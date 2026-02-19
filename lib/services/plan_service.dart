import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../models/plan_day_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/plan_model.dart';

/// Local persistence and business logic for training plans.
/// Handles CRUD operations and double-progression updates.
class PlanService {
  Box<Plan>? _plansBox;
  Box<String>? _prefsBox;

  /// Opens the plans box and preferences box. Call once at app startup.
  Future<void> open() async {
    if (_plansBox == null || !_plansBox!.isOpen) {
      _plansBox = await Hive.openBox<Plan>(kPlansBoxName);
    }
    if (_prefsBox == null || !_prefsBox!.isOpen) {
      _prefsBox = await Hive.openBox<String>('prefs');
    }
  }

  Box<Plan> get _store {
    final box = _plansBox;
    if (box == null || !box.isOpen) {
      throw StateError('PlanService not opened. Call open() first.');
    }
    return box;
  }

  Box<String> get _prefs {
    final box = _prefsBox;
    if (box == null || !box.isOpen) {
      throw StateError('PlanService not opened. Call open() first.');
    }
    return box;
  }

  /// Saves a plan. Uses [Plan.id] as key; overwrites if id exists.
  Future<void> savePlan(Plan plan) async {
    await _store.put(plan.id, plan);
  }

  /// Deletes a plan by id.
  Future<void> deletePlan(String id) async {
    await _store.delete(id);
    // If deleted plan was active, clear active plan id.
    final activeId = await getActivePlanId();
    if (activeId == id) {
      await setActivePlanId(null);
    }
  }

  /// Returns all plans.
  List<Plan> getAllPlans() {
    return _store.values.toList();
  }

  /// Returns plan by id, or null.
  Plan? getPlanById(String id) => _store.get(id);

  /// Sets the active plan id (or null to clear).
  Future<void> setActivePlanId(String? planId) async {
    if (planId == null) {
      await _prefs.delete(kActivePlanIdKey);
    } else {
      await _prefs.put(kActivePlanIdKey, planId);
    }
  }

  /// Returns the active plan id, or null.
  Future<String?> getActivePlanId() async {
    return _prefs.get(kActivePlanIdKey);
  }

  /// Gets a specific day from a plan by day id.
  PlanDay? getPlanDay(String planId, String dayId) {
    final plan = getPlanById(planId);
    if (plan == null) return null;
    for (final day in plan.days) {
      if (day.id == dayId) return day;
    }
    return null;
  }

  /// Gets exercises for a plan day (convenience method).
  List<PlanExercise> getPlannedExercisesForDay(PlanDay day) {
    return day.exercises;
  }

  /// Updates plan after a session using double-progression logic.
  ///
  /// For each exercise in the day:
  /// - If all logged sets >= maxReps: increase currentWeight by increment
  /// - Else: keep same weight
  ///
  /// Returns updated Plan (does not save automatically).
  Plan updatePlanAfterSession({
    required Plan plan,
    required String dayId,
    required Map<String, List<int>> loggedRepsByExerciseId,
  }) {
    final dayIndex = plan.days.indexWhere((d) => d.id == dayId);
    if (dayIndex == -1) return plan;

    final day = plan.days[dayIndex];
    final updatedExercises = <PlanExercise>[];

    for (final exercise in day.exercises) {
      final loggedReps = loggedRepsByExerciseId[exercise.id] ?? [];
      final completedSets = loggedReps.length;

      // Double progression rule: all sets must hit maxReps to progress.
      final shouldProgress = completedSets >= exercise.sets &&
          loggedReps.every((reps) => reps >= exercise.maxReps);

      final newWeight =
          shouldProgress ? exercise.currentWeight + exercise.increment : exercise.currentWeight;

      updatedExercises.add(exercise.copyWith(currentWeight: newWeight));
    }

    final updatedDay = day.copyWith(exercises: updatedExercises);
    final updatedDays = List<PlanDay>.from(plan.days);
    updatedDays[dayIndex] = updatedDay;

    return plan.copyWith(days: updatedDays);
  }

  /// Convenience method: update plan after session and save.
  Future<void> updateAndSavePlanAfterSession({
    required Plan plan,
    required String dayId,
    required Map<String, List<int>> loggedRepsByExerciseId,
  }) async {
    final updated = updatePlanAfterSession(
      plan: plan,
      dayId: dayId,
      loggedRepsByExerciseId: loggedRepsByExerciseId,
    );
    await savePlan(updated);
  }
}
