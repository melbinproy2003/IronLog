import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_day_model.dart';
import '../models/plan_model.dart';
import '../repositories/plan_repository.dart';
import '../services/pending_sync_service.dart';
import '../services/plan_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'workout_provider.dart';

/// Provides [PlanService]. Override in main with an opened instance.
final planServiceProvider = Provider<PlanService>((ref) {
  throw UnimplementedError(
    'Override planServiceProvider in main with an opened PlanService',
  );
});

/// Plan repository: Hive (via PlanService) first, Firestore sync when authenticated.
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(
    planService: ref.watch(planServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    authService: ref.watch(authServiceProvider),
    pendingSync: ref.watch(pendingSyncServiceProvider),
  );
});

/// All plans from storage (via repository).
final allPlansProvider = FutureProvider<List<Plan>>((ref) async {
  final service = ref.watch(planServiceProvider);
  await service.open();
  return ref.watch(planRepositoryProvider).getAllPlans();
});

/// Active plan id (from preferences).
final activePlanIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(planServiceProvider);
  await service.open();
  return ref.watch(planRepositoryProvider).getActivePlanId();
});

/// Active plan (fetched by id).
final activePlanProvider = FutureProvider<Plan?>((ref) async {
  final id = await ref.watch(activePlanIdProvider.future);
  if (id == null) return null;
  final service = ref.watch(planServiceProvider);
  await service.open();
  return ref.watch(planRepositoryProvider).getPlanById(id);
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
  return ref.watch(planRepositoryProvider).getPlanDay(params.planId, params.dayId);
});

/// Selected plan day for execution (user-selected from active plan).
final selectedPlanDayProvider = StateProvider<PlanDay?>((ref) => null);

/// Notifier for plan operations (save, delete, activate).
class PlanNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> savePlan(Plan plan) async {
    final repo = ref.read(planRepositoryProvider);
    final service = ref.read(planServiceProvider);
    await service.open();
    await repo.savePlan(plan);
    ref.invalidate(allPlansProvider);
    ref.invalidate(activePlanProvider);
  }

  Future<void> deletePlan(String id) async {
    final repo = ref.read(planRepositoryProvider);
    final service = ref.read(planServiceProvider);
    await service.open();
    await repo.deletePlan(id);
    ref.invalidate(allPlansProvider);
    ref.invalidate(activePlanIdProvider);
    ref.invalidate(activePlanProvider);
  }

  Future<void> setActivePlanId(String? id) async {
    final repo = ref.read(planRepositoryProvider);
    final service = ref.read(planServiceProvider);
    await service.open();
    await repo.setActivePlanId(id);
    ref.invalidate(activePlanIdProvider);
    ref.invalidate(activePlanProvider);
    ref.invalidate(todayPlanDayProvider);
  }
}

final planNotifierProvider =
    AsyncNotifierProvider<PlanNotifier, void>(PlanNotifier.new);
