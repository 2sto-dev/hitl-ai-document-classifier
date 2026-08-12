class ReviewQueueDocument {
  final String id;
  final String filename;
  final String predictedClass;
  final double confidenceScore;
  final String status;
  final String uploadedAt;

  ReviewQueueDocument({
    required this.id,
    required this.filename,
    required this.predictedClass,
    required this.confidenceScore,
    required this.status,
    required this.uploadedAt,
  });

  factory ReviewQueueDocument.fromJson(Map<String, dynamic> json) {
    return ReviewQueueDocument(
      id: json['id'] as String,
      filename: json['filename'] as String,
      predictedClass: json['predicted_class'] as String? ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      uploadedAt: json['uploaded_at'] as String? ?? '',
    );
  }
}
