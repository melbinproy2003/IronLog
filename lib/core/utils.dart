/// Pure helper functions: date formatting, 1RM formula, name normalization.
/// No UI or state; used by services and optionally by UI for display.
library;

/// Estimated one-rep max from weight and reps.
/// Formula: 1RM = weight × (1 + reps / 30)
double estimated1RM(double weight, int reps) {
  if (reps <= 0) return 0;
  return weight * (1 + reps / 30);
}

/// Total volume for a list of sets: sum of (weight × reps) per set.
double totalVolume(List<({double weight, int reps})> sets) {
  return sets.fold<double>(
    0,
    (sum, s) => sum + (s.weight * s.reps),
  );
}

/// Volume from exercise sets: sum of weight × reps. Used by services.
double volumeFromSets(Iterable<({double weight, int reps})> sets) {
  return sets.fold<double>(0, (sum, s) => sum + (s.weight * s.reps));
}

/// Format [date] as yyyy-MM-dd for display and storage keys.
String formatDateKey(DateTime date) {
  final y = date.year;
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Start of week (Monday) for the given date.
DateTime startOfWeek(DateTime date) {
  final weekday = date.weekday;
  final daysFromMonday = weekday - DateTime.monday;
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}

/// Normalize exercise names for internal keys: trim, collapse spaces, lowercase.
String normalizeExerciseKey(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final singleSpaced = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  return singleSpaced.toLowerCase();
}

/// Canonical display name for exercises: trim, collapse spaces, Title Case.
String canonicalExerciseName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final singleSpaced = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  final parts = singleSpaced.split(' ');
  final cased = parts
      .map(
        (w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .where((w) => w.isNotEmpty)
      .toList();
  return cased.join(' ');
}
