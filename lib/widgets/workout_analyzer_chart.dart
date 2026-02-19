import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ironlog/core/utils.dart';
import 'package:ironlog/models/workout_model.dart';
import 'package:ironlog/providers/progress_provider.dart';

/// Line chart: X = date, Y = total volume. Dot markers. Session list below.
class WorkoutAnalyzerChart extends ConsumerWidget {
  const WorkoutAnalyzerChart({
    super.key,
    required this.exerciseName,
    this.height = 200,
  });

  final String exerciseName;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(workoutAnalyzerDataProvider(exerciseName));

    return dataAsync.when(
      data: (points) {
        if (points.isEmpty) {
          return SizedBox(
            height: height,
            child: Center(
              child: Text(
                'No workout data for this exercise',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VolumeLineChart(points: points, height: height),
            const SizedBox(height: 16),
            Text(
              'Past sessions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _SessionList(points: points),
          ],
        );
      },
      loading: () => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: height,
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _VolumeLineChart extends StatelessWidget {
  const _VolumeLineChart({
    required this.points,
    required this.height,
  });

  final List<WorkoutAnalyzerPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No volume data',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalVolume))
        .toList();
    final maxY = points.map((p) => p.totalVolume).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.secondary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < points.length) {
                    final d = points[i].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${d.month}/${d.day}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.points});

  final List<WorkoutAnalyzerPoint> points;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: points.length,
      itemBuilder: (context, index) {
        final p = points[points.length - 1 - index]; // newest first
        return _SessionTile(point: p);
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.point});

  final WorkoutAnalyzerPoint point;

  @override
  Widget build(BuildContext context) {
    final setsSummary = point.workout.sets
        .map((s) => '${s.weight.toStringAsFixed(0)}×${s.reps}')
        .join(' · ');
    final dateStr = formatDateKey(point.workout.date);
    final volumeStr = point.totalVolume >= 1000
        ? '${(point.totalVolume / 1000).toStringAsFixed(1)}k'
        : point.totalVolume.toInt().toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(dateStr),
        subtitle: Text(
          'Volume: $volumeStr kg',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sets: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Expanded(
                  child: Text(
                    setsSummary.isEmpty ? 'No sets' : setsSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
