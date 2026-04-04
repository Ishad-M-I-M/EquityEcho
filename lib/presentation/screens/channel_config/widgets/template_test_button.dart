import 'package:flutter/material.dart';

/// Right-aligned "Test Template" text button.
class TemplateTestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TemplateTestButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.science,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        label: Text(
          'Test Template',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
