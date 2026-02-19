import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/plan_provider.dart';
import 'free_workout_screen.dart';
import 'plan_execution_screen.dart';

/// Screen that shows workout options based on active plan status.
/// If active plan exists: shows two buttons (Plan Workout, Free Workout)
/// If no active plan: shows Free Workout screen directly
class WorkoutSelectionScreen extends ConsumerWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlanAsync = ref.watch(activePlanProvider);

    return activePlanAsync.when(
      data: (activePlan) {
        if (activePlan == null) {
          // No active plan - show free workout directly
          return const FreeWorkoutScreen();
        }

        // Active plan exists - show selection screen
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select Workout Type',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlanExecutionScreen(
                              planId: activePlan.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Start Plan Workout'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FreeWorkoutScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('Log Free Workout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Plan: ${activePlan.name}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan Workout: Follows your structured plan with automatic progression.\n\nFree Workout: Log any exercise without affecting your plan.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
