import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/stats_model.dart';
import '../models/accuracy_stats_model.dart';
import '../models/department_stats_model.dart';
import '../models/confusion_matrix_model.dart';
import '../models/review_queue_model.dart';
import '../models/document_detail_model.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<http.Response> _authenticatedJsonRequest(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) {
    return AuthService.authenticatedRequest((authHeaders) {
      return send({...authHeaders, 'Content-Type': 'application/json'});
    });
  }

  static Future<StatsModel> fetchStats() async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(Uri.parse('$baseUrl/stats/'), headers: headers)
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return StatsModel.fromJson(json);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  static Future<AccuracyStatsModel> fetchAccuracyStats() async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(Uri.parse('$baseUrl/stats/accuracy/'), headers: headers)
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AccuracyStatsModel.fromJson(json);
      }

      throw Exception('Failed to load accuracy: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching accuracy: $e');
    }
  }

  static Future<DepartmentStatsModel> fetchDepartmentStats() async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(Uri.parse('$baseUrl/stats/departments/'), headers: headers)
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DepartmentStatsModel.fromJson(json);
      } else {
        throw Exception(
          'Failed to load department stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching department stats: $e');
    }
  }

  static Future<ConfusionMatrixModel> fetchConfusionMatrix() async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(
              Uri.parse('$baseUrl/stats/confusion-matrix/'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ConfusionMatrixModel.fromJson(json);
      } else {
        throw Exception(
          'Failed to load confusion matrix: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching confusion matrix: $e');
    }
  }

  static Future<List<ReviewQueueDocument>> fetchReviewQueue() async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(Uri.parse('$baseUrl/review-queue/'), headers: headers)
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((item) => ReviewQueueDocument.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load review queue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching review queue: $e');
    }
  }

  static Future<DocumentDetail> fetchDocumentDetail(String id) async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .get(Uri.parse('$baseUrl/documents/$id/'), headers: headers)
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DocumentDetail.fromJson(json);
      } else {
        throw Exception(
          'Failed to load document detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching document detail: $e');
    }
  }

  static Future<List<DocumentDetail>> fetchDocumentHistory() async {
    final response = await _authenticatedJsonRequest((headers) {
      return http
          .get(Uri.parse('$baseUrl/documents/'), headers: headers)
          .timeout(const Duration(seconds: 15));
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load history: ${response.statusCode}');
    }

    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => DocumentDetail.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> reviewDocument(
    String id,
    String action, {
    String? finalClass,
    String? reviewNotes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'action': action,
        'review_notes': reviewNotes ?? '',
      };

      if (finalClass != null) {
        payload['final_class'] = finalClass;
      }

      final response = await _authenticatedJsonRequest((headers) {
        return http
            .post(
              Uri.parse('$baseUrl/documents/$id/review/'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to submit review: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting review: $e');
    }
  }

  static Future<String> uploadDocument({
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest((
        authHeaders,
      ) async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/upload/'),
        );
        request.headers.addAll(authHeaders);
        request.fields['filename'] = filename;
        request.files.add(
          http.MultipartFile.fromBytes(
            'uploaded_file',
            bytes,
            filename: filename,
          ),
        );
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 180),
        );
        return http.Response.fromStream(streamedResponse);
      });

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['id'].toString();
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }

  static Future<Map<String, dynamic>> sendAiPrompt(String text) async {
    try {
      final response = await _authenticatedJsonRequest((headers) {
        return http
            .post(
              Uri.parse('$baseUrl/ai/analyze/'),
              headers: headers,
              body: jsonEncode({'text': text}),
            )
            .timeout(const Duration(seconds: 60));
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } else {
        throw Exception('AI analyze failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending AI prompt: $e');
    }
  }
}
