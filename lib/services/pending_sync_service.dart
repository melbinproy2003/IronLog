import 'package:hive_flutter/hive_flutter.dart';

const String _kPendingWorkoutIdsKey = 'pending_workout_ids';
const String _kPendingPlanIdsKey = 'pending_plan_ids';

/// Stores ids of workouts/plans that failed to sync to Firestore (e.g. offline).
/// Used by repositories to sync later.
class PendingSyncService {
  Box<dynamic>? _box;

  Future<void> open() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox('pending_sync');
  }

  Box<dynamic> get _store {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('PendingSyncService not opened. Call open() first.');
    }
    return box;
  }

  void addPendingWorkoutId(String id) {
    final list = List<String>.from(_store.get(_kPendingWorkoutIdsKey) ?? []);
    if (!list.contains(id)) list.add(id);
    _store.put(_kPendingWorkoutIdsKey, list);
  }

  void addPendingPlanId(String id) {
    final list = List<String>.from(_store.get(_kPendingPlanIdsKey) ?? []);
    if (!list.contains(id)) list.add(id);
    _store.put(_kPendingPlanIdsKey, list);
  }

  List<String> getPendingWorkoutIds() {
    final list = _store.get(_kPendingWorkoutIdsKey);
    return list != null ? List<String>.from(list) : [];
  }

  List<String> getPendingPlanIds() {
    final list = _store.get(_kPendingPlanIdsKey);
    return list != null ? List<String>.from(list) : [];
  }

  void removePendingWorkoutId(String id) {
    final list = List<String>.from(_store.get(_kPendingWorkoutIdsKey) ?? []);
    list.remove(id);
    _store.put(_kPendingWorkoutIdsKey, list);
  }

  void removePendingPlanId(String id) {
    final list = List<String>.from(_store.get(_kPendingPlanIdsKey) ?? []);
    list.remove(id);
    _store.put(_kPendingPlanIdsKey, list);
  }
}
