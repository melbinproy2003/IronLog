import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants.dart';
import 'models/exercise_set_model.dart';
import 'models/plan_day_model.dart';
import 'models/plan_exercise_model.dart';
import 'models/plan_model.dart';
import 'models/workout_model.dart';
import 'providers/plan_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/home_shell.dart';
import 'services/hive_service.dart';
import 'services/plan_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(ProviderScope(
    overrides: [
      hiveServiceProvider.overrideWithValue(hiveService),
      planServiceProvider.overrideWithValue(planService),
    ],
    child: const IronLogApp(),
  ));
}

class IronLogApp extends StatelessWidget {
  const IronLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
