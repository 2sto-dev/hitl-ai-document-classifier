class DocumentDetail {
  final String id;
  final String filename;
  final String predictedClass;
  final double confidenceScore;
  final String suggestedDepartment;
  final String finalClass;
  final String summary;
  final List<String> keywords;
  final String uploadedFile;
  final String extractedText;
  final bool humanCorrected;
  final String status;
  final String decisionRoute;
  final double decisionThreshold;
  final String uploadedAt;

  DocumentDetail({
    required this.id,
    required this.filename,
    required this.predictedClass,
    required this.confidenceScore,
    required this.suggestedDepartment,
    required this.finalClass,
    required this.summary,
    required this.keywords,
    required this.uploadedFile,
    required this.extractedText,
    required this.humanCorrected,
    required this.status,
    required this.decisionRoute,
    required this.decisionThreshold,
    required this.uploadedAt,
  });

  factory DocumentDetail.fromJson(Map<String, dynamic> json) {
    final keywords = <String>[];
    if (json['keywords'] is List) {
      for (final item in json['keywords']) {
        if (item != null) {
          keywords.add(item.toString());
        }
      }
    }

    return DocumentDetail(
      id: json['id'] as String,
      filename: json['filename'] as String,
      predictedClass: json['predicted_class'] as String? ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      suggestedDepartment: json['suggested_department'] as String? ?? '',
      finalClass: json['final_class'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      keywords: keywords,
      uploadedFile: json['uploaded_file'] as String? ?? '',
      extractedText: json['extracted_text'] as String? ?? '',
      humanCorrected: json['human_corrected'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      decisionRoute: json['decision_route'] as String? ?? '',
      decisionThreshold:
          (json['decision_threshold'] as num?)?.toDouble() ?? 70.0,
      uploadedAt: json['uploaded_at'] as String? ?? '',
    );
  }
}
