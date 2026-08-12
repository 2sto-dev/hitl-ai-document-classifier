import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ReviewAction { change, reject }

class ReviewDialogResult {
  final String selectedClass;
  final String notes;

  ReviewDialogResult({required this.selectedClass, required this.notes});
}

class ReviewActionDialog extends StatefulWidget {
  final ReviewAction action;
  final String initialClass;

  const ReviewActionDialog({
    super.key,
    required this.action,
    this.initialClass = '',
  });

  @override
  State<ReviewActionDialog> createState() => _ReviewActionDialogState();
}

class _ReviewActionDialogState extends State<ReviewActionDialog> {
  final _notesController = TextEditingController();
  String _selectedClass = '';

  static const _departments = [
    'HR',
    'Finance',
    'IT',
    'Legal',
    'Operations',
    'Procurement',
  ];

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass.isNotEmpty
        ? widget.initialClass
        : _departments.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.action == ReviewAction.change
            ? 'Change Document Class'
            : 'Reject Document',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.action == ReviewAction.change) ...[
            const Text(
              'Select a new department:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedClass,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedClass = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Review notes (optional):',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            Navigator.of(context).pop(
              ReviewDialogResult(
                selectedClass: _selectedClass,
                notes: _notesController.text,
              ),
            );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
