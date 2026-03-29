import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';

class DeleteResult {
  final bool confirmed;
  final String? reason;
  final String? reasonOther;

  DeleteResult({required this.confirmed, this.reason, this.reasonOther});
}

class DeleteConfirmationDialog extends StatefulWidget {
  final String title;
  final String content;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static Future<DeleteResult?> show(BuildContext context, {required String title, required String content}) {
    return showDialog<DeleteResult>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(title: title, content: content),
    );
  }

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  String? _selectedReason;
  late TextEditingController _otherController;

  final List<String> _reasons = [
    'Duplicate SMS',
    'Manual Entry Error',
    'Test Entry',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController();
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.content, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Text('Please select a reason (optional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            RadioGroup<String?>(
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                  if (value != 'Other') {
                    _otherController.clear();
                  }
                });
              },
              child: Column(
                children: _reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.sellRed,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                decoration: const InputDecoration(
                  labelText: 'Please specify',
                  isDense: true,
                ),
                autofocus: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, DeleteResult(confirmed: false)),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, DeleteResult(
              confirmed: true,
              reason: _selectedReason,
              reasonOther: _selectedReason == 'Other' ? _otherController.text.trim() : null,
            ));
          },
          child: Text('Delete', style: TextStyle(color: AppTheme.sellRed, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
