import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';

/// Wraps a list of template placeholder chips (e.g. {{symbol}}, {{price}}).
class PlaceholderHints extends StatelessWidget {
  final List<String> placeholders;

  const PlaceholderHints({super.key, required this.placeholders});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: placeholders
          .map(
            (p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                p,
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
