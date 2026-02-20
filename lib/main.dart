import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants.dart';
import 'models/exercise_set_model.dart';
import 'models/plan_day_model.dart';
import 'models/plan_exercise_model.dart';
import 'models/plan_model.dart';
import 'models/workout_model.dart';
import 'providers/auth_provider.dart';
import 'providers/firestore_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/sync_on_auth_wrapper.dart';
import 'services/hive_service.dart';
import 'services/pending_sync_service.dart';
import 'services/plan_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseSetAdapter());
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(PlanExerciseAdapter());
  Hive.registerAdapter(PlanDayAdapter());
  Hive.registerAdapter(PlanAdapter());
  final hiveService = HiveService();
  await hiveService.open();
  final planService = PlanService();
  await planService.open();
  final pendingSyncService = PendingSyncService();
  await pendingSyncService.open();
  runApp(ProviderScope(
    overrides: [
      hiveServiceProvider.overrideWithValue(hiveService),
      planServiceProvider.overrideWithValue(planService),
      pendingSyncServiceProvider.overrideWithValue(pendingSyncService),
    ],
    child: const IronLogApp(),
  ));
}

class IronLogApp extends ConsumerWidget {
  const IronLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return MaterialApp(
      title: kAppName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) => user != null ? const SyncOnAuthWrapper() : const AuthScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) {
          debugPrint('Auth error: $err');
          return const AuthScreen();
        },
      ),
    );
  }
}
