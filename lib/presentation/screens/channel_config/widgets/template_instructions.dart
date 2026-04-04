import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';

/// Tip box explaining how to build a template from a real SMS.
/// Set [isFund] to true for fund-transfer templates (uses {{amount}}).
class TemplateInstructions extends StatelessWidget {
  final bool isFund;

  const TemplateInstructions({super.key, this.isFund = false});

  @override
  Widget build(BuildContext context) {
    final fields = isFund
        ? '{{amount}}'
        : '{{symbol}}, {{quantity}}, {{price}}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.warning),
              const SizedBox(width: 6),
              Text(
                'How to set up',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paste a real SMS and replace $fields with placeholders. '
            'Dates and times are auto-detected — no need to replace them.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
