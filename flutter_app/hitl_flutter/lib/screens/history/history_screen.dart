import 'package:flutter/material.dart';

import '../../models/document_detail_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<DocumentDetail>> _history;

  @override
  void initState() {
    super.initState();
    _history = ApiService.fetchDocumentHistory();
  }

  Future<void> _refresh() async {
    setState(() => _history = ApiService.fetchDocumentHistory());
    await _history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Decision History',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Permanent audit trail for automatic and HITL decisions.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<DocumentDetail>>(
                  future: _history,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('History error: ${snapshot.error}'));
                    }

                    final documents = snapshot.data ?? [];
                    if (documents.isEmpty) {
                      return const Center(child: Text('No decisions recorded yet.'));
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        itemCount: documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          final needsHuman =
                              document.decisionRoute == 'human_review';
                          final label = needsHuman
                              ? 'Human review required'
                              : 'Auto-approved';
                          final color = needsHuman
                              ? AppColors.warning
                              : AppColors.success;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: color.withAlpha(110)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(
                                      avatar: Icon(
                                        needsHuman
                                            ? Icons.person_search
                                            : Icons.auto_awesome,
                                        color: color,
                                        size: 18,
                                      ),
                                      label: Text(label),
                                    ),
                                    Chip(label: Text(document.predictedClass)),
                                    Chip(
                                      label: Text(
                                        '${document.confidenceScore.toStringAsFixed(1)}%',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rule: confidence ${needsHuman ? '<' : '≥'} ${document.decisionThreshold.toStringAsFixed(0)}%',
                                  style: const TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
