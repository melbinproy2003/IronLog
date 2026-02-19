import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Line chart for weekly volume. X = week start, Y = volume. Dot markers.
class WeeklyVolumeLineChart extends StatelessWidget {
  const WeeklyVolumeLineChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  final List<({DateTime weekStart, double volume})> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No volume data yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.volume))
        .toList();
    final maxY = data.map((d) => d.volume).reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = 0.0;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
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
                  if (i >= 0 && i < data.length) {
                    final d = data[i].weekStart;
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
