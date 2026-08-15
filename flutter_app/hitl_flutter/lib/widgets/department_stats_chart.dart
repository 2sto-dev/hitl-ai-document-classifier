import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/department_stats_model.dart';
import '../theme/app_theme.dart';

class DepartmentStatsChart extends StatelessWidget {
  final DepartmentStatsModel stats;

  const DepartmentStatsChart({super.key, required this.stats});

  String _mobileLabel(String department) {
    const labels = {
      'Finance': 'Fin',
      'Legal': 'Leg',
      'Operations': 'Ops',
      'Procurement': 'Proc',
    };
    return labels[department] ?? department;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final entries = stats.departments.entries.toList();
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: [
        Text(
          'Documents by Department',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 4 : 16,
              16,
              isCompact ? 4 : 16,
              8,
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        const Color.fromRGBO(96, 125, 139, 0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toString(),
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < entries.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              isCompact
                                  ? _mobileLabel(entries[index].key)
                                  : entries[index].key,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
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
                barGroups: List.generate(entries.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entries[index].value.toDouble(),
                        color: AppColors.primary,
                        width: isCompact ? 14 : 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
