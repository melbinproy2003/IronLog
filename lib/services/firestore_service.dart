import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';

/// Firestore access scoped by uid. All methods require [uid]; no Firebase calls in UI.
class FirestoreService {
  FirestoreService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// User document: { activePlanId?: string, email?, displayName?, createdAt? }.
  Future<void> setUserProfile(
    String uid, {
    String? activePlanId,
    String? email,
    String? displayName,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (activePlanId != null) data['activePlanId'] = activePlanId;
    if (email != null) data['email'] = email;
    if (displayName != null) data['displayName'] = displayName;
    await _firestore.doc(FirestorePaths.user(uid)).set(data, SetOptions(merge: true));
  }

  /// Creates user profile if it doesn't exist. Used after first-time sign-in (e.g., Google).
  Future<void> createUserProfileIfNotExists(
    String uid, {
    required String? email,
    required String? displayName,
  }) async {
    final snap = await _firestore.doc(FirestorePaths.user(uid)).get();
    if (!snap.exists) {
      await _firestore.doc(FirestorePaths.user(uid)).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _firestore.doc(FirestorePaths.user(uid)).get();
    return snap.data();
  }

  /// Plans subcollection: document id = planId, data = plan map.
  Future<void> savePlan(String uid, String planId, Map<String, dynamic> data) async {
    await _firestore.doc(FirestorePaths.plan(uid, planId)).set(data);
  }

  Future<void> deletePlan(String uid, String planId) async {
    await _firestore.doc(FirestorePaths.plan(uid, planId)).delete();
  }

  Future<List<Map<String, dynamic>>> getPlans(String uid) async {
    final snap =
        await _firestore.collection(FirestorePaths.userPlans(uid)).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Workouts subcollection: document id = workoutId, data = workout map.
  Future<void> saveWorkout(
      String uid, String workoutId, Map<String, dynamic> data) async {
    await _firestore.doc(FirestorePaths.workout(uid, workoutId)).set(data);
  }

  Future<void> deleteWorkout(String uid, String workoutId) async {
    await _firestore.doc(FirestorePaths.workout(uid, workoutId)).delete();
  }

  Future<List<Map<String, dynamic>>> getWorkouts(String uid) async {
    final snap =
        await _firestore.collection(FirestorePaths.userWorkouts(uid)).get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
