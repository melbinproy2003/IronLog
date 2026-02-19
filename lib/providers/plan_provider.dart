import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_day_model.dart';
import '../models/plan_model.dart';
import '../services/plan_service.dart';

/// Provides [PlanService]. Override in main with an opened instance.
final planServiceProvider = Provider<PlanService>((ref) {
  throw UnimplementedError(
    'Override planServiceProvider in main with an opened PlanService',
  );
});

/// All plans from storage.
final allPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final service = ref.watch(planServiceProvider);
  await service.open();
  return service.getAllPlans();
});

/// Active plan id (from preferences).
final activePlanIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(planServiceProvider);
  await service.open();
  return service.getActivePlanId();
});

/// Active plan (fetched by id).
final activePlanProvider = FutureProvider<Plan?>((ref) async {
  final id = await ref.watch(activePlanIdProvider.future);
  if (id == null) return null;
  final service = ref.watch(planServiceProvider);
  await service.open();
  return service.getPlanById(id);
});

/// Today's plan day (for MVP: cycles through days sequentially).
final todayPlanDayProvider = FutureProvider<PlanDay?>((ref) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null || plan.days.isEmpty) return null;

  // Simple cycling: use weekday modulo number of days.
  final dayIndex = DateTime.now().weekday % plan.days.length;
  return plan.days[dayIndex];
});

/// Specific plan day by plan id and day id.
final planDayProvider =
    FutureProvider.family<PlanDay?, ({String planId, String dayId})>(
        (ref, params) async {
  final service = ref.watch(planServiceProvider);
  await service.open();
  return service.getPlanDay(params.planId, params.dayId);
});

/// Selected plan day for execution (user-selected from active plan).
final selectedPlanDayProvider = StateProvider<PlanDay?>((ref) => null);

/// Notifier for plan operations (save, delete, activate).
class PlanNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> savePlan(Plan plan) async {
    final service = ref.read(planServiceProvider);
    await service.open();
    await service.savePlan(plan);
    ref.invalidate(allPlansProvider);
    ref.invalidate(activePlanProvider);
  }

  Future<void> deletePlan(String id) async {
    final service = ref.read(planServiceProvider);
    await service.open();
    await service.deletePlan(id);
    ref.invalidate(allPlansProvider);
    ref.invalidate(activePlanIdProvider);
    ref.invalidate(activePlanProvider);
  }

  Future<void> setActivePlanId(String? id) async {
    final service = ref.read(planServiceProvider);
    await service.open();
    await service.setActivePlanId(id);
    ref.invalidate(activePlanIdProvider);
    ref.invalidate(activePlanProvider);
    ref.invalidate(todayPlanDayProvider);
  }
}

final planNotifierProvider =
    AsyncNotifierProvider<PlanNotifier, void>(PlanNotifier.new);
