class AccuracyStatsModel {
  final int totalReviewed;
  final int correctPredictions;
  final int humanCorrections;
  final double accuracy;

  const AccuracyStatsModel({
    required this.totalReviewed,
    required this.correctPredictions,
    required this.humanCorrections,
    required this.accuracy,
  });

  factory AccuracyStatsModel.fromJson(Map<String, dynamic> json) {
    return AccuracyStatsModel(
      totalReviewed: (json['total_reviewed'] as num?)?.toInt() ?? 0,
      correctPredictions: (json['correct_predictions'] as num?)?.toInt() ?? 0,
      humanCorrections: (json['human_corrections'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    );
  }
}
