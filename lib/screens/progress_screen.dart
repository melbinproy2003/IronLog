import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ironlog/core/graph_type.dart';
import 'package:ironlog/providers/progress_provider.dart';
import 'package:ironlog/providers/workout_provider.dart';
import 'package:ironlog/widgets/one_rm_chart.dart';
import 'package:ironlog/widgets/weekly_volume_line_chart.dart';
import 'package:ironlog/widgets/workout_analyzer_chart.dart';

/// Progress: graph type selector, exercise selector, 1RM / weekly volume / workout analyzer.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExerciseNamesProvider);
    final graphType = ref.watch(graphTypeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: exercisesAsync.when(
        data: (names) {
          if (names.isEmpty) {
            return const Center(
              child: Text('Log workouts to see progress.'),
            );
          }
          final selected =
              names.contains(_selectedExercise) ? _selectedExercise! : names.first;
          if (selected != _selectedExercise) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedExercise = selected);
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Exercise',
                    border: OutlineInputBorder(),
                  ),
                  items: names
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedExercise = v ?? names.first),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GraphType>(
                  value: graphType,
                  decoration: const InputDecoration(
                    labelText: 'Graph type',
                    border: OutlineInputBorder(),
                  ),
                  items: GraphType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(graphTypeProvider.notifier).state = v;
                    }
                  },
                ),
                const SizedBox(height: 24),
                _ChartSection(selectedExercise: selected, graphType: graphType),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({
    required this.selectedExercise,
    required this.graphType,
  });

  final String selectedExercise;
  final GraphType graphType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (graphType) {
      case GraphType.oneRM:
        final dataAsync = ref.watch(oneRMChartDataProvider(selectedExercise));
        return dataAsync.when(
          data: (list) => OneRMChart(data: list),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(child: Text('Error: $e')),
          ),
        );
      case GraphType.weeklyVolume:
        final dataAsync =
            ref.watch(weeklyVolumeChartDataProvider(selectedExercise));
        return dataAsync.when(
          data: (list) => WeeklyVolumeLineChart(data: list),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 200,
            child: Center(child: Text('Error: $e')),
          ),
        );
      case GraphType.workoutAnalyzer:
        return WorkoutAnalyzerChart(exerciseName: selectedExercise);
    }
  }
}
