import 'package:flutter/foundation.dart';

/// Filter criteria for dashboard workout list.
@immutable
class DashboardFilter {
  const DashboardFilter({
    this.startDate,
    this.endDate,
    this.exerciseName,
    this.planDayId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? exerciseName;
  final String? planDayId;

  DashboardFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? exerciseName,
    String? planDayId,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearExerciseName = false,
    bool clearPlanDayId = false,
  }) {
    return DashboardFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      exerciseName: clearExerciseName ? null : (exerciseName ?? this.exerciseName),
      planDayId: clearPlanDayId ? null : (planDayId ?? this.planDayId),
    );
  }

  bool get isDefault =>
      startDate == null &&
      endDate == null &&
      exerciseName == null &&
      planDayId == null;
}
