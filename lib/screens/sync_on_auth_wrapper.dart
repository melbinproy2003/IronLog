import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import 'home_shell.dart';

/// Wraps [HomeShell] and triggers fetchAndSync + syncPending when user is authenticated.
class SyncOnAuthWrapper extends ConsumerStatefulWidget {
  const SyncOnAuthWrapper({super.key});

  @override
  ConsumerState<SyncOnAuthWrapper> createState() => _SyncOnAuthWrapperState();
}

class _SyncOnAuthWrapperState extends ConsumerState<SyncOnAuthWrapper> {
  bool _synced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authStateProvider).value;
    if (user != null && !_synced) {
      _synced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync(
            user.uid,
            email: user.email,
            displayName: user.displayName,
          ));
    }
  }

  Future<void> _sync(
    String uid, {
    String? email,
    String? displayName,
  }) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    try {
      await firestoreService.createUserProfileIfNotExists(
        uid,
        email: email,
        displayName: displayName,
      );
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
    }
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final planRepo = ref.read(planRepositoryProvider);
    await workoutRepo.fetchAndSync(uid);
    await planRepo.fetchAndSync(uid);
    await workoutRepo.syncPending(uid);
    await planRepo.syncPending(uid);
    if (mounted) {
      ref.invalidate(allWorkoutsProvider);
      ref.invalidate(allPlansProvider);
      ref.invalidate(activePlanProvider);
      ref.invalidate(activePlanIdProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeShell();
  }
}
