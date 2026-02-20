/// Firestore path builders. All paths are scoped by [uid].
/// Structure: users/{uid}, users/{uid}/plans/{planId}, users/{uid}/workouts/{workoutId}.
class FirestorePaths {
  FirestorePaths._();

  static String user(String uid) => 'users/$uid';

  static String userPlans(String uid) => 'users/$uid/plans';

  static String plan(String uid, String planId) => 'users/$uid/plans/$planId';

  static String userWorkouts(String uid) => 'users/$uid/workouts';

  static String workout(String uid, String workoutId) =>
      'users/$uid/workouts/$workoutId';
}
