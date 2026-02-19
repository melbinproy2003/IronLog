import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Line chart for 1RM progression. Receives prepared (date, oneRm) data.
class OneRMChart extends StatelessWidget {
  const OneRMChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  final List<({DateTime date, double oneRm})> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No 1RM data yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.oneRm))
        .toList();
    final minY = (data.map((d) => d.oneRm).reduce((a, b) => a < b ? a : b)) - 5;
    final maxY = (data.map((d) => d.oneRm).reduce((a, b) => a > b ? a : b)) + 5;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: minY > 0 ? minY : 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
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
                    final d = data[i].date;
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
