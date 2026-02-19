/// Type of graph to display on the Progress screen.
enum GraphType {
  oneRM,
  weeklyVolume,
  workoutAnalyzer,
}

extension GraphTypeExtension on GraphType {
  String get label {
    switch (this) {
      case GraphType.oneRM:
        return '1RM';
      case GraphType.weeklyVolume:
        return 'Weekly volume';
      case GraphType.workoutAnalyzer:
        return 'Workout analyzer';
    }
  }
}
