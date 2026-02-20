import '../models/exercise_set_model.dart';
import '../models/workout_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/pending_sync_service.dart';

/// Repository for workouts: Hive first, then Firestore sync when authenticated.
/// All data flow goes through here; no direct HiveService in providers for writes.
class WorkoutRepository {
  WorkoutRepository({
    required HiveService hiveService,
    required FirestoreService firestoreService,
    required AuthService authService,
    required PendingSyncService pendingSync,
  })  : _hive = hiveService,
        _firestore = firestoreService,
        _auth = authService,
        _pendingSync = pendingSync;

  final HiveService _hive;
  final FirestoreService _firestore;
  final AuthService _auth;
  final PendingSyncService _pendingSync;

  /// Saves to Hive first, then syncs to Firestore if user is signed in.
  Future<void> saveWorkout(Workout workout) async {
    await _hive.saveWorkout(workout);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.saveWorkout(uid, workout.id, _workoutToMap(workout));
      } catch (_) {
        _pendingSync.addPendingWorkoutId(workout.id);
      }
    }
  }

  Future<void> deleteWorkout(String id) async {
    await _hive.deleteWorkout(id);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.deleteWorkout(uid, id);
      } catch (_) {}
    }
  }

  Workout? getWorkout(String id) => _hive.getWorkout(id);

  List<Workout> getAllWorkouts() => _hive.getAllWorkouts();

  List<Workout> getWorkoutsInRange(DateTime start, DateTime end) =>
      _hive.getWorkoutsInRange(start, end);

  List<Workout> getWorkoutsOnDate(DateTime date) =>
      _hive.getWorkoutsOnDate(date);

  List<String> getAllExerciseNames() => _hive.getAllExerciseNames();

  List<Workout> getWorkoutsForPlanDay({
    required String planId,
    required String planDayId,
    required DateTime date,
  }) =>
      _hive.getWorkoutsForPlanDay(
          planId: planId, planDayId: planDayId, date: date);

  Workout? getMostRecentWorkoutForPlanDay({
    required String planId,
    required String planDayId,
  }) =>
      _hive.getMostRecentWorkoutForPlanDay(
          planId: planId, planDayId: planDayId);

  Workout? getMostRecentWorkoutForExercise(String exerciseName) =>
      _hive.getMostRecentWorkoutForExercise(exerciseName);

  /// Fetches workouts from Firestore for [uid] and merges into Hive (by id).
  Future<void> fetchAndSync(String uid) async {
    try {
      final remote = await _firestore.getWorkouts(uid);
      for (final map in remote) {
        final workout = _workoutFromMap(map);
        if (workout != null) await _hive.saveWorkout(workout);
      }
    } catch (_) {}
  }

  /// Syncs pending workouts (saved locally while offline) to Firestore.
  Future<void> syncPending(String uid) async {
    final ids = _pendingSync.getPendingWorkoutIds();
    for (final id in ids) {
      final w = _hive.getWorkout(id);
      if (w == null) {
        _pendingSync.removePendingWorkoutId(id);
        continue;
      }
      try {
        await _firestore.saveWorkout(uid, id, _workoutToMap(w));
        _pendingSync.removePendingWorkoutId(id);
      } catch (_) {}
    }
  }

  static Map<String, dynamic> _workoutToMap(Workout w) {
    return {
      'id': w.id,
      'date': w.date.millisecondsSinceEpoch,
      'exerciseName': w.exerciseName,
      'sets': w.sets
          .map((s) => {
                'weight': s.weight,
                'reps': s.reps,
                'completed': s.completed,
              })
          .toList(),
      'targetReps': w.targetReps,
      'planId': w.planId,
      'planDayId': w.planDayId,
      'adherenceScore': w.adherenceScore,
      'progressionApplied': w.progressionApplied,
    };
  }

  static Workout? _workoutFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final id = map['id'] as String?;
    final dateMillis = map['date'] as int?;
    final exerciseName = map['exerciseName'] as String?;
    final setsList = map['sets'] as List<dynamic>?;
    if (id == null || dateMillis == null || exerciseName == null) return null;
    final sets = <ExerciseSet>[];
    if (setsList != null) {
      for (final e in setsList) {
        if (e is! Map) continue;
        final weight = (e['weight'] as num?)?.toDouble() ?? 0.0;
        final reps = (e['reps'] as num?)?.toInt() ?? 0;
        final completed = e['completed'] as bool? ?? true;
        sets.add(ExerciseSet(weight: weight, reps: reps, completed: completed));
      }
    }
    return Workout(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      exerciseName: exerciseName,
      sets: sets,
      targetReps: (map['targetReps'] as num?)?.toInt(),
      planId: map['planId'] as String?,
      planDayId: map['planDayId'] as String?,
      adherenceScore: (map['adherenceScore'] as num?)?.toDouble(),
      progressionApplied: map['progressionApplied'] as bool? ?? false,
    );
  }
}
