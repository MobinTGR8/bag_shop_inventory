import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: tt.bodySmall),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key, required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No chart data available')),
      );
    }

    final maxY = points.fold<double>(
        0, (max, point) => point.value > max ? point.value : max);
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[index].label,
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      points[spot.x.toInt()].value.toStringAsFixed(2),
                      const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                  .toList(),
            ),
          ),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              barWidth: 3,
              color: Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.points, this.barColor});

  final List<ChartPoint> points;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No chart data available')),
      );
    }

    final color = barColor ?? Theme.of(context).colorScheme.primary;
    final maxY = points.fold<double>(
        0, (max, point) => point.value > max ? point.value : max);
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[index].label,
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    color: color,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
          maxY: maxY <= 0 ? 1 : maxY * 1.25,
        ),
      ),
    );
  }
}

class DualBarChartPoint {
  final String label;
  final double primary;
  final double secondary;

  const DualBarChartPoint({
    required this.label,
    required this.primary,
    required this.secondary,
  });
}

class DualBarChart extends StatelessWidget {
  const DualBarChart({super.key, required this.points});

  final List<DualBarChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No chart data available')),
      );
    }

    final maxY = points.fold<double>(
        0,
        (max, point) => point.primary > max
            ? point.primary
            : (point.secondary > max ? point.secondary : max));
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 42),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[index].label,
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 6,
                barRods: [
                  BarChartRodData(
                    toY: points[i].primary,
                    color: primaryColor,
                    width: 10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  BarChartRodData(
                    toY: points[i].secondary,
                    color: secondaryColor,
                    width: 10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
          maxY: maxY <= 0 ? 1 : maxY * 1.25,
        ),
      ),
    );
  }
}
