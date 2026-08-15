import 'package:flutter/material.dart';
import '../models/confusion_matrix_model.dart';

class ConfusionMatrixChart extends StatelessWidget {
  final ConfusionMatrixModel matrix;

  const ConfusionMatrixChart({super.key, required this.matrix});

  String _shortLabel(String value, int maxLength) {
    return value.length > maxLength ? value.substring(0, maxLength) : value;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final labelWidth = isCompact ? 64.0 : 100.0;
    final cellWidth = isCompact ? 48.0 : 80.0;

    if (matrix.departments.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    // Find max value for color scaling
    int maxValue = 0;
    for (var predicted in matrix.matrix.values) {
      for (var count in predicted.values) {
        if (count > maxValue) maxValue = count;
      }
    }

    if (maxValue == 0) maxValue = 1;

    return Column(
      children: [
        Text(
          'Confusion Matrix (Predicted vs Actual)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 20),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 0 : 16,
                vertical: isCompact ? 8 : 16,
              ),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: const Text(
                          'Predicted →',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...matrix.departments.map((dept) {
                        final label = _shortLabel(dept, 3);
                        return SizedBox(
                          width: cellWidth,
                          child: Center(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Matrix rows
                  Column(
                    children: matrix.departments.map((actualDept) {
                      return Row(
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                actualDept.length > 6
                                    ? '${_shortLabel(actualDept, 3)}...'
                                    : actualDept,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          ...matrix.departments.map((predictedDept) {
                            final count =
                                matrix.matrix[predictedDept]?[actualDept] ?? 0;
                            final opacity = (count / maxValue).clamp(0.0, 1.0);
                            return SizedBox(
                              width: cellWidth,
                              height: isCompact ? 32 : 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(
                                    (255 * opacity).toInt(),
                                    72,
                                    168,
                                    154,
                                  ),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Center(
                                  child: Text(
                                    count.toString(),
                                    style: TextStyle(
                                      color: opacity > 0.5
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        Text(
          'Actual ↓',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
