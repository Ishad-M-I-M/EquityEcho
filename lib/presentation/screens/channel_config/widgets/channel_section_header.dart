import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';

/// Coloured left-bar section header used throughout the channel config form.
class ChannelSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const ChannelSectionHeader(this.title, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color ?? AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color ?? AppTheme.accent,
          ),
        ),
      ],
    );
  }
}
