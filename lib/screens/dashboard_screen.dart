import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/dashboard_filter_sheet.dart';
import '../widgets/exercise_card.dart';
import 'plan_execution_screen.dart';
import 'workout_screen.dart';

/// Dashboard: today's workout, fatigue warning, plan day, filtered workout list.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredWorkoutsProvider);
    final fatigueAsync = ref.watch(fatigueWarningProvider);
    final nextWorkoutAsync = ref.watch(firstNextWorkoutSuggestionProvider);
    final todayPlanDayAsync = ref.watch(todayPlanDayProvider);
    final activePlanAsync = ref.watch(activePlanProvider);

    final filter = ref.watch(dashboardFilterProvider);
    final hasActiveFilter = !filter.isDefault;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilter
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => showDashboardFilterSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allWorkoutsProvider);
          ref.invalidate(filteredWorkoutsProvider);
          ref.invalidate(fatigueWarningProvider);
          ref.invalidate(firstNextWorkoutSuggestionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fatigueAsync.when(
                data: (message) {
                  if (message == null || message.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (fatigueAsync.hasValue && fatigueAsync.value != null &&
                  (fatigueAsync.value ?? '').isNotEmpty)
                const SizedBox(height: 16),
              nextWorkoutAsync.when(
                data: (suggestion) {
                  if (suggestion == null) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Workout Plan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log more sessions to generate suggestion.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Card(
                    color: suggestion.isDeload
                        ? Theme.of(context).colorScheme.errorContainer
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                suggestion.isDeload
                                    ? Icons.warning_amber_rounded
                                    : Icons.fitness_center,
                                color: suggestion.isDeload
                                    ? Theme.of(context)
                                        .colorScheme.onErrorContainer
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Next Workout Plan',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: suggestion.isDeload
                                            ? Theme.of(context)
                                                .colorScheme.onErrorContainer
                                            : null,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.exerciseName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: suggestion.isDeload
                                      ? Theme.of(context)
                                          .colorScheme.onErrorContainer
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          if (suggestion.nextSuggestedWeight != null)
                            Text(
                              'Suggested weight: ${suggestion.nextSuggestedWeight!.toStringAsFixed(1)} kg',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: suggestion.isDeload
                                        ? Theme.of(context)
                                            .colorScheme.onErrorContainer
                                        : null,
                                  ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            suggestion.reason,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: suggestion.isDeload
                                      ? Theme.of(context)
                                          .colorScheme.onErrorContainer
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Workout Plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Loading…'),
                      ],
                    ),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Workout Plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Error: $e'),
                      ],
                    ),
                  ),
                ),
              ),
              todayPlanDayAsync.when(
                data: (planDay) {
                  if (planDay == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: InkWell(
                          onTap: () {
                            activePlanAsync.whenData((plan) {
                              if (plan != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PlanExecutionScreen(
                                      planId: plan.id,
                                      planDayId: planDay.id,
                                    ),
                                  ),
                                );
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Plan Day',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        planDay.name,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Text(
                hasActiveFilter ? 'Filtered workouts' : "Today's workout",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              filteredAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          hasActiveFilter
                              ? 'No workouts match the filter.'
                              : 'No workout logged today.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: list
                        .map((w) => _WorkoutSummaryCard(workout: w))
                        .toList(),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Loading…'),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  const _WorkoutSummaryCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final setsSummary = workout.sets
        .map((s) => '${s.weight.toStringAsFixed(0)}×${s.reps}')
        .join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(workout.exerciseName),
        subtitle: Text(setsSummary.isEmpty ? 'No sets' : setsSummary),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkoutScreen(initialWorkout: workout),
            ),
          );
        },
      ),
    );
  }
}
