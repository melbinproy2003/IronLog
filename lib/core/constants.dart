/// Application-wide constants for IronLog.
/// Progression thresholds and defaults used by the progression engine.
library;

/// Hive box name for workout persistence.
const String kWorkoutBoxName = 'workouts';

/// Hive box name for training plans.
const String kPlansBoxName = 'plans';

/// Key used to store the active plan id in a preferences box.
const String kActivePlanIdKey = 'active_plan_id';

/// App display name.
const String kAppName = 'IronLog';

/// Default target reps per set when not specified.
const int kDefaultTargetReps = 8;

/// Weight increment when user hits target reps for 2-3 sessions (kg).
const double kProgressionWeightIncrementKg = 2.5;

/// Weight reduction factor when user fails target reps for 2 sessions (e.g. 0.95 = -5%).
const double kProgressionWeightReduceFactor = 0.95;

/// Weekly volume increase threshold for fatigue warning (e.g. 1.2 = 20% increase).
const double kVolumeIncreaseFatigueThreshold = 1.2;

/// Number of consecutive weeks 1RM must drop to suggest deload.
const int kDeloadWeeks1RMDrop = 2;

/// Sessions hitting target reps required before suggesting weight increase.
const int kSessionsToSuggestIncreaseMin = 2;
const int kSessionsToSuggestIncreaseMax = 3;

/// Sessions failing target reps before suggesting weight decrease.
const int kSessionsToSuggestDecrease = 2;
