class StatsModel {
  final int totalDocuments;
  final int approved;
  final int reviewRequired;
  final int rejected;
  final int pending;
  final double averageConfidence;
  final int humanCorrected;
  final int reviewedDocuments;
  final double humanInterventionRate;
  final double autoApprovalRate;

  StatsModel({
    required this.totalDocuments,
    required this.approved,
    required this.reviewRequired,
    required this.rejected,
    required this.pending,
    required this.averageConfidence,
    required this.humanCorrected,
    required this.reviewedDocuments,
    required this.humanInterventionRate,
    required this.autoApprovalRate,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      totalDocuments: json['total_documents'] ?? 0,
      approved: json['approved'] ?? 0,
      reviewRequired: json['review_required'] ?? 0,
      rejected: json['rejected'] ?? 0,
      pending: json['pending'] ?? 0,
      averageConfidence: (json['average_confidence'] ?? 0).toDouble(),
      humanCorrected: json['human_corrected'] ?? 0,
      reviewedDocuments: json['reviewed_documents'] ?? 0,
      humanInterventionRate: (json['human_intervention_rate'] ?? 0).toDouble(),
      autoApprovalRate: (json['auto_approval_rate'] ?? 0).toDouble(),
    );
  }
}
