import 'package:flutter/material.dart';

import '../../widgets/kpi_card.dart';
import '../../widgets/status_distribution_chart.dart';
import '../../widgets/department_stats_chart.dart';
import '../../widgets/confusion_matrix_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/stats_model.dart';
import '../../models/accuracy_stats_model.dart';
import '../../models/department_stats_model.dart';
import '../../models/confusion_matrix_model.dart';
import '../../theme/app_theme.dart';

String getGreeting(String title) {
  final hour = DateTime.now().hour;
  final username = title.split('_').first;
  final displayName = username.isEmpty
      ? username
      : '${username[0].toUpperCase()}${username.substring(1)}';
  late final String greeting;

  if (hour >= 5 && hour < 12) {
    greeting = 'Good morning';
  } else if (hour >= 12 && hour < 18) {
    greeting = 'Good afternoon';
  } else {
    greeting = 'Good evening';
  }

  return '$greeting, $displayName! 👋';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<StatsModel> _statsFuture;
  late Future<AccuracyStatsModel> _accuracyFuture;
  late Future<DepartmentStatsModel> _deptStatsFuture;
  late Future<ConfusionMatrixModel> _matrixFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiService.fetchStats();
    _accuracyFuture = ApiService.fetchAccuracyStats();
    _deptStatsFuture = ApiService.fetchDepartmentStats();
    _matrixFuture = ApiService.fetchConfusionMatrix();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getGreeting(AuthService.username ?? ''),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use analytics to monitor document flow, accuracy, and review outcomes.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              const SizedBox.shrink(),
              const SizedBox(height: 24),
              // KPI Cards
              FutureBuilder<StatsModel>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 700 ? 2 : 4;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: columns == 2 ? 1.15 : 1.7,
                          children: [
                            KpiCard(
                              title: "Total Documents",
                              value: "${stats.totalDocuments}",
                              icon: Icons.folder_open,
                            ),
                            FutureBuilder<AccuracyStatsModel>(
                              future: _accuracyFuture,
                              builder: (context, accuracySnapshot) {
                                final value = accuracySnapshot.hasData
                                    ? '${accuracySnapshot.data!.accuracy.toStringAsFixed(1)}%'
                                    : accuracySnapshot.hasError
                                    ? 'Unavailable'
                                    : '...';
                                return KpiCard(
                                  title: "AI Accuracy",
                                  value: value,
                                  icon: Icons.psychology,
                                );
                              },
                            ),
                            KpiCard(
                              title: "In Review",
                              value: "${stats.reviewRequired}",
                              icon: Icons.pending,
                            ),
                            KpiCard(
                              title: "Approved",
                              value: "${stats.approved}",
                              icon: Icons.check_circle,
                            ),
                          ],
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 40),
              // Charts Section
              Text(
                "Analytics",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Charts Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isPhone = constraints.maxWidth < 700;
                  final isWide = constraints.maxWidth > 1200;
                  final crossCount = isPhone ? 1 : (isWide ? 3 : 2);

                  return Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: isPhone
                            ? constraints.maxWidth / 430
                            : 1.2,
                        children: [
                          // Status Distribution Chart
                          Container(
                            padding: EdgeInsets.all(isPhone ? 16 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FutureBuilder<StatsModel>(
                              future: _statsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading chart',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  );
                                } else if (snapshot.hasData) {
                                  return StatusDistributionChart(
                                    stats: snapshot.data!,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          // Department Stats Chart
                          Container(
                            padding: EdgeInsets.all(isPhone ? 16 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FutureBuilder<DepartmentStatsModel>(
                              future: _deptStatsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading chart',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  );
                                } else if (snapshot.hasData) {
                                  return DepartmentStatsChart(
                                    stats: snapshot.data!,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          // Confusion Matrix Chart (spans full width if only 2 columns)
                          Container(
                            padding: EdgeInsets.all(isPhone ? 16 : 20),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FutureBuilder<ConfusionMatrixModel>(
                              future: _matrixFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading chart',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  );
                                } else if (snapshot.hasData) {
                                  return ConfusionMatrixChart(
                                    matrix: snapshot.data!,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
