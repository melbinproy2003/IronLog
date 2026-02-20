import '../models/plan_day_model.dart';
import '../models/plan_exercise_model.dart';
import '../models/plan_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pending_sync_service.dart';
import '../services/plan_service.dart';

/// Repository for plans: Hive (via PlanService) first, then Firestore sync when authenticated.
/// Active plan id is synced to Firestore user profile.
class PlanRepository {
  PlanRepository({
    required PlanService planService,
    required FirestoreService firestoreService,
    required AuthService authService,
    required PendingSyncService pendingSync,
  })  : _planService = planService,
        _firestore = firestoreService,
        _auth = authService,
        _pendingSync = pendingSync;

  final PlanService _planService;
  final FirestoreService _firestore;
  final AuthService _auth;
  final PendingSyncService _pendingSync;

  Future<void> savePlan(Plan plan) async {
    await _planService.savePlan(plan);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.savePlan(uid, plan.id, _planToMap(plan));
      } catch (_) {
        _pendingSync.addPendingPlanId(plan.id);
      }
    }
  }

  Future<void> deletePlan(String id) async {
    await _planService.deletePlan(id);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.deletePlan(uid, id);
      } catch (_) {}
    }
  }

  List<Plan> getAllPlans() => _planService.getAllPlans();

  Plan? getPlanById(String id) => _planService.getPlanById(id);

  Future<void> setActivePlanId(String? planId) async {
    await _planService.setActivePlanId(planId);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.setUserProfile(uid, activePlanId: planId);
      } catch (_) {}
    }
  }

  /// Syncs pending plans (saved locally while offline) to Firestore.
  Future<void> syncPending(String uid) async {
    final ids = _pendingSync.getPendingPlanIds();
    for (final id in ids) {
      final plan = _planService.getPlanById(id);
      if (plan == null) {
        _pendingSync.removePendingPlanId(id);
        continue;
      }
      try {
        await _firestore.savePlan(uid, id, _planToMap(plan));
        _pendingSync.removePendingPlanId(id);
      } catch (_) {}
    }
  }

  Future<String?> getActivePlanId() => _planService.getActivePlanId();

  PlanDay? getPlanDay(String planId, String dayId) =>
      _planService.getPlanDay(planId, dayId);

  List<PlanExercise> getPlannedExercisesForDay(PlanDay day) =>
      _planService.getPlannedExercisesForDay(day);

  Plan updatePlanAfterSession({
    required Plan plan,
    required String dayId,
    required Map<String, List<int>> loggedRepsByExerciseId,
  }) =>
      _planService.updatePlanAfterSession(
        plan: plan,
        dayId: dayId,
        loggedRepsByExerciseId: loggedRepsByExerciseId,
      );

  Future<void> updateAndSavePlanAfterSession({
    required Plan plan,
    required String dayId,
    required Map<String, List<int>> loggedRepsByExerciseId,
  }) async {
    await _planService.updateAndSavePlanAfterSession(
      plan: plan,
      dayId: dayId,
      loggedRepsByExerciseId: loggedRepsByExerciseId,
    );
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        final updated = _planService.getPlanById(plan.id);
        if (updated != null) {
          await _firestore.savePlan(uid, updated.id, _planToMap(updated));
        }
      } catch (_) {
        _pendingSync.addPendingPlanId(plan.id);
      }
    }
  }

  /// Fetches plans and user profile from Firestore for [uid], merges into Hive.
  Future<void> fetchAndSync(String uid) async {
    try {
      final plans = await _firestore.getPlans(uid);
      for (final map in plans) {
        final plan = _planFromMap(map);
        if (plan != null) await _planService.savePlan(plan);
      }
      final profile = await _firestore.getUserProfile(uid);
      final activeId = profile?['activePlanId'] as String?;
      if (activeId != null) await _planService.setActivePlanId(activeId);
    } catch (_) {}
  }


  static Map<String, dynamic> _planToMap(Plan p) {
    return {
      'id': p.id,
      'name': p.name,
      'createdAt': p.createdAt.millisecondsSinceEpoch,
      'days': p.days.map((d) => _planDayToMap(d)).toList(),
    };
  }

  static Map<String, dynamic> _planDayToMap(PlanDay d) {
    return {
      'id': d.id,
      'name': d.name,
      'dayIndex': d.dayIndex,
      'exercises': d.exercises.map((e) => _planExerciseToMap(e)).toList(),
    };
  }

  static Map<String, dynamic> _planExerciseToMap(PlanExercise e) {
    return {
      'id': e.id,
      'exerciseName': e.exerciseName,
      'currentWeight': e.currentWeight,
      'increment': e.increment,
      'sets': e.sets,
      'minReps': e.minReps,
      'maxReps': e.maxReps,
    };
  }

  static Plan? _planFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final id = map['id'] as String?;
    final name = map['name'] as String?;
    final createdAtMillis = map['createdAt'] as int?;
    final daysList = map['days'] as List<dynamic>?;
    if (id == null || name == null || createdAtMillis == null) return null;
    final days = <PlanDay>[];
    if (daysList != null) {
      for (final d in daysList) {
        if (d is! Map) continue;
        final day = _planDayFromMap(Map<String, dynamic>.from(d));
        if (day != null) days.add(day);
      }
    }
    return Plan(
      id: id,
      name: name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      days: days,
    );
  }

  static PlanDay? _planDayFromMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final name = map['name'] as String?;
    final dayIndex = (map['dayIndex'] as num?)?.toInt();
    final exList = map['exercises'] as List<dynamic>?;
    if (id == null || name == null || dayIndex == null) return null;
    final exercises = <PlanExercise>[];
    if (exList != null) {
      for (final e in exList) {
        if (e is! Map) continue;
        final ex = _planExerciseFromMap(Map<String, dynamic>.from(e));
        if (ex != null) exercises.add(ex);
      }
    }
    return PlanDay(id: id, name: name, dayIndex: dayIndex, exercises: exercises);
  }

  static PlanExercise? _planExerciseFromMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final exerciseName = map['exerciseName'] as String?;
    final currentWeight = (map['currentWeight'] as num?)?.toDouble() ?? 0.0;
    final increment = (map['increment'] as num?)?.toDouble() ?? 0.0;
    final sets = (map['sets'] as num?)?.toInt() ?? 0;
    final minReps = (map['minReps'] as num?)?.toInt() ?? 0;
    final maxReps = (map['maxReps'] as num?)?.toInt() ?? 0;
    if (id == null || exerciseName == null) return null;
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
}
