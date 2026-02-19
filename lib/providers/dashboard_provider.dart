import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_filter_model.dart';
import '../models/workout_model.dart';
import 'plan_provider.dart';
import 'workout_provider.dart';

/// Current dashboard filter. UI can update via [DashboardFilterNotifier].
final dashboardFilterProvider =
    StateNotifierProvider<DashboardFilterNotifier, DashboardFilter>(
        (ref) => DashboardFilterNotifier());

class DashboardFilterNotifier extends StateNotifier<DashboardFilter> {
  DashboardFilterNotifier() : super(const DashboardFilter());

  void setFilter(DashboardFilter filter) {
    state = filter;
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setExerciseName(String? name) {
    state = state.copyWith(exerciseName: name);
  }

  void setPlanDayId(String? id) {
    state = state.copyWith(planDayId: id);
  }

  void setQuickRangeDays(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    state = state.copyWith(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
    );
  }

  void clearFilter() {
    state = const DashboardFilter();
  }
}

/// Workouts filtered by [dashboardFilterProvider]. Used by Dashboard for the workout list.
/// When filter is default, returns today's workouts only (same as previous dashboard behavior).
final filteredWorkoutsProvider =
    FutureProvider<List<Workout>>((ref) async {
  final workouts = await ref.watch(allWorkoutsProvider.future);
  final filter = ref.watch(dashboardFilterProvider);

  var list = List<Workout>.from(workouts);

  if (filter.isDefault) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    list = list.where((w) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      return d == todayStart;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  if (filter.startDate != null) {
    final start = DateTime(
      filter.startDate!.year,
      filter.startDate!.month,
      filter.startDate!.day,
    );
    list = list.where((w) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      return !d.isBefore(start);
    }).toList();
  }
  if (filter.endDate != null) {
    final end = DateTime(
      filter.endDate!.year,
      filter.endDate!.month,
      filter.endDate!.day,
    );
    list = list.where((w) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      return !d.isAfter(end);
    }).toList();
  }
  if (filter.exerciseName != null && filter.exerciseName!.isNotEmpty) {
    list = list
        .where((w) =>
            w.exerciseName.toLowerCase().trim() ==
            filter.exerciseName!.toLowerCase().trim())
        .toList();
  }
  if (filter.planDayId != null && filter.planDayId!.isNotEmpty) {
    list = list
        .where((w) => w.planDayId == filter.planDayId)
        .toList();
  }

  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});
