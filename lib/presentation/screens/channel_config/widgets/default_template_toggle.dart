import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';

/// Toggle between the built-in default template and a user-defined custom one.
/// When [value] is true the default template is shown as a read-only preview.
class DefaultTemplateToggle extends StatelessWidget {
  final String label;
  final bool value;
  final String defaultTemplate;
  final ValueChanged<bool> onChanged;

  const DefaultTemplateToggle({
    super.key,
    required this.label,
    required this.value,
    required this.defaultTemplate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        if (value) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Default Template',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  defaultTemplate,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
