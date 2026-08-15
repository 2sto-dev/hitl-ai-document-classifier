import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stats_model.dart';
import '../theme/app_theme.dart';

class StatusDistributionChart extends StatelessWidget {
  final StatsModel stats;

  const StatusDistributionChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total =
        stats.approved + stats.reviewRequired + stats.rejected + stats.pending;

    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Document Status Distribution',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                if (stats.approved > 0)
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: stats.approved.toDouble(),
                    title:
                        '${(stats.approved / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (stats.reviewRequired > 0)
                  PieChartSectionData(
                    color: const Color(0xFFFFA726),
                    value: stats.reviewRequired.toDouble(),
                    title:
                        '${(stats.reviewRequired / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (stats.rejected > 0)
                  PieChartSectionData(
                    color: const Color(0xFFEF5350),
                    value: stats.rejected.toDouble(),
                    title:
                        '${(stats.rejected / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (stats.pending > 0)
                  PieChartSectionData(
                    color: const Color(0xFFB0BEC5),
                    value: stats.pending.toDouble(),
                    title:
                        '${(stats.pending / total * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: AppColors.primary,
              label: 'Approved (${stats.approved})',
            ),
            _LegendItem(
              color: const Color(0xFFFFA726),
              label: 'Review (${stats.reviewRequired})',
            ),
            _LegendItem(
              color: const Color(0xFFEF5350),
              label: 'Rejected (${stats.rejected})',
            ),
            _LegendItem(
              color: const Color(0xFFB0BEC5),
              label: 'Pending (${stats.pending})',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
