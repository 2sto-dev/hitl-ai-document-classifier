import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/document_detail_model.dart';
import '../../models/review_queue_model.dart';
import '../../services/api_service.dart';
import '../../widgets/review_action_dialog.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<List<ReviewQueueDocument>> _queueFuture;
  DocumentDetail? _selectedDocument;
  String? _selectedDocumentId;
  bool _isSubmitting = false;
  final TextEditingController _promptController = TextEditingController();
  bool _isAnalyzing = false;
  bool _isUploading = false;
  String? _attachedFileName;
  List<int>? _pendingFileBytes;
  String _aiDepartment = '';
  String _aiSummary = '';
  List<String> _aiKeywords = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  void _loadQueue() {
    _queueFuture = ApiService.fetchReviewQueue();
    _selectedDocument = null;
    _selectedDocumentId = null;
    _attachedFileName = null;
  }

  Future<void> _selectDocument(String id) async {
    final detail = await ApiService.fetchDocumentDetail(id);
    if (!mounted) return;
    setState(() {
      _selectedDocument = detail;
      _selectedDocumentId = detail.id;
      _attachedFileName = detail.filename;
      _pendingFileBytes = null;
      _aiDepartment = '';
      _aiSummary = '';
      _aiKeywords = [];
    });
  }

  Future<void> _attachDocument() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Could not read the selected file.');
      }

      if (!mounted) return;
      setState(() {
        _attachedFileName = file.name;
        _pendingFileBytes = bytes;
        _selectedDocument = null;
        _selectedDocumentId = null;
        _promptController.clear();
        _aiDepartment = '';
        _aiSummary = '';
        _aiKeywords = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} attached. Press Send to analyze.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Attach failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _buildAiPrompt(DocumentDetail document, String userPrompt) {
    final prompt = userPrompt.isNotEmpty
        ? userPrompt
        : 'Summarize the document and identify the receiving department.';

    return '''
You are an AI review assistant for an enterprise document classifier.

User request:
$prompt

Attached document:
Filename: ${document.filename}
Predicted department: ${document.predictedClass}
Confidence: ${document.confidenceScore.toStringAsFixed(1)}%
Suggested department: ${document.suggestedDepartment.isNotEmpty ? document.suggestedDepartment : 'N/A'}

Document text:
${document.extractedText}
''';
  }

  Future<void> _sendAiPrompt() async {
    var document = _selectedDocument;
    final promptText = _promptController.text.trim();

    if (document == null && _pendingFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach or select a document first.')),
      );
      return;
    }

    if (document != null &&
        promptText.isEmpty &&
        document.extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a prompt or attach a document.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiDepartment = '';
      _aiSummary = '';
      _aiKeywords = [];
    });

    try {
      if (_pendingFileBytes != null) {
        final documentId = await ApiService.uploadDocument(
          filename: _attachedFileName!,
          bytes: _pendingFileBytes!,
        );
        final detail = await ApiService.fetchDocumentDetail(documentId);
        if (!mounted) return;
        document = detail;
        setState(() {
          _selectedDocument = detail;
          _selectedDocumentId = detail.id;
          _pendingFileBytes = null;
          _queueFuture = ApiService.fetchReviewQueue();
        });

        // Upload processing already asks Ollama for these values. Avoid a
        // second long-running Ollama request unless the user asked a specific
        // follow-up question.
        if (promptText.isEmpty) {
          setState(() {
            _aiDepartment = detail.suggestedDepartment;
            _aiSummary = detail.summary;
            _aiKeywords = detail.keywords;
          });
          return;
        }
      }

      final combined = _buildAiPrompt(document!, promptText);
      final result = await ApiService.sendAiPrompt(combined);
      if (!mounted) return;
      setState(() {
        _aiDepartment = (result['department'] ?? '').toString();
        _aiSummary = (result['summary'] ?? '').toString();
        final kw = result['keywords'];
        if (kw is List) {
          _aiKeywords = kw.map((e) => e.toString()).toList();
        } else {
          _aiKeywords = [];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI analyze failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _submitReview(
    String action, {
    String? finalClass,
    String? notes,
  }) async {
    if (_selectedDocumentId == null) return;

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.reviewDocument(
        _selectedDocumentId!,
        action,
        finalClass: finalClass,
        reviewNotes: notes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );

      setState(() {
        _selectedDocument = null;
        _selectedDocumentId = null;
        _loadQueue();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Review failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildQueueItem(ReviewQueueDocument document) {
    final selected = document.id == _selectedDocumentId;
    return Card(
      color: selected ? AppColors.secondary : AppColors.card,
      child: ListTile(
        title: Text(
          document.filename,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Predicted: ${document.predictedClass} · ${document.confidenceScore.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: selected ? AppColors.accent : Colors.white38,
          size: 16,
        ),
        onTap: () => _selectDocument(document.id),
      ),
    );
  }

  Widget _buildDocumentPreview({bool compact = false}) {
    if (_selectedDocument == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a document from the queue or attach a PDF to review',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_isUploading || _isAnalyzing)
                  ? null
                  : _attachDocument,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: const Text('Attach PDF'),
            ),
          ],
        ),
      );
    }

    final document = _selectedDocument!;
    final pdfUrl = document.uploadedFile.startsWith('http')
        ? document.uploadedFile
        : '${ApiConfig.serverUrl}${document.uploadedFile}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          document.filename,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openPdfDocument(pdfUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Open PDF'),
            ),
            OutlinedButton.icon(
              onPressed: (_isUploading || _isAnalyzing)
                  ? null
                  : _attachDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload another PDF'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildAnalysisSection(document, compact: compact),
      ],
    );
  }

  Widget _buildPromptPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask AI about a document',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Tooltip(
                message: 'Attach PDF',
                child: IconButton.filledTonal(
                  onPressed: (_isUploading || _isAnalyzing)
                      ? null
                      : _attachDocument,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Attach a PDF, then ask AI what to extract, summarize, or classify...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF0B2230),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) {
                    if (!_isAnalyzing) {
                      _sendAiPrompt();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isAnalyzing ? null : AppColors.buttonGradient,
                  color: _isAnalyzing ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _isAnalyzing
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x669303C5),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                ),
                child: ElevatedButton.icon(
                  onPressed: (_isAnalyzing || _isUploading)
                      ? null
                      : _sendAiPrompt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 17),
                  label: const Text(
                    'Send',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _attachedFileName == null
                    ? Icons.upload_file
                    : Icons.picture_as_pdf,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _attachedFileName ?? 'No document attached yet',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPdfDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid PDF URL.')));
      }
      return;
    }

    final launched = await launchUrlString(uri.toString());
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open PDF.')));
    }
  }

  Widget _buildAnalysisSection(
    DocumentDetail document, {
    bool compact = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Predicted Department', document.predictedClass),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Confidence',
          '${document.confidenceScore.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Suggested Department',
          document.suggestedDepartment.isNotEmpty
              ? document.suggestedDepartment
              : 'N/A',
        ),
        const SizedBox(height: 16),
        Text(
          'Keywords',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: document.keywords.map((keyword) {
            return Chip(
              label: Text(keyword),
              backgroundColor: const Color(0xFF0F3B4F),
              labelStyle: const TextStyle(color: Colors.white),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Summary',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (compact)
          Text(
            _aiSummary.isNotEmpty
                ? _aiSummary
                : (document.summary.isNotEmpty
                      ? document.summary
                      : document.extractedText),
            style: const TextStyle(color: Colors.white60),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                // If AI produced a summary from the prompt, show it first
                _aiSummary.isNotEmpty
                    ? _aiSummary
                    : (document.summary.isNotEmpty
                          ? document.summary
                          : document.extractedText),
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_aiDepartment.isNotEmpty) ...[
          _buildInfoRow('AI Predicted Department', _aiDepartment),
          const SizedBox(height: 8),
          _buildInfoRow('AI Keywords', _aiKeywords.join(', ')),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        if (document.confidenceScore < document.decisionThreshold)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitReview(
                        'approve',
                        finalClass: document.predictedClass,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Approve'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final result = await showDialog<ReviewDialogResult>(
                          context: context,
                          builder: (context) => ReviewActionDialog(
                            action: ReviewAction.change,
                            initialClass: document.predictedClass,
                          ),
                        );
                        if (result != null) {
                          _submitReview(
                            'change',
                            finalClass: result.selectedClass,
                            notes: result.notes,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Change Class'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final result = await showDialog<ReviewDialogResult>(
                          context: context,
                          builder: (context) =>
                              ReviewActionDialog(action: ReviewAction.reject),
                        );
                        if (result != null) {
                          _submitReview('reject', notes: result.notes);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Reject'),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withAlpha(140)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Auto-approved (${document.confidenceScore.toStringAsFixed(1)}% ≥ ${document.decisionThreshold.toStringAsFixed(0)}%) — no human action required',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return compact ? content : Expanded(child: content);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Review Workspace',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildPromptPanel(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ReviewQueueDocument>>(
                future: _queueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading queue: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final queue = snapshot.data ?? [];
                  if (isMobile) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (queue.isNotEmpty) ...[
                            const Text(
                              'Review Queue',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...queue.take(4).map(_buildQueueItem),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _buildDocumentPreview(compact: true),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Review Queue',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: queue.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No documents pending review',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: queue.length,
                                      itemBuilder: (context, index) =>
                                          _buildQueueItem(queue[index]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Flexible(
                        flex: 65,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _buildDocumentPreview(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
