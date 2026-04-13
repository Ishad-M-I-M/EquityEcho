import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/data/models/holding.dart';

class HoldingStatsCard extends StatelessWidget {
  final Holding holding;
  final NumberFormat currencyFormatter;

  const HoldingStatsCard({
    super.key,
    required this.holding,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _StatRow(
            'Net Quantity',
            '${holding.netQuantity.toStringAsFixed(0)} shares',
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _StatRow(
            'Average Price',
            currencyFormatter.format(holding.avgBuyPrice),
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _StatRow(
            'Average Cost',
            currencyFormatter.format(holding.avgCostWithCharges),
            subtitle: 'incl. charges',
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _StatRow(
            'Total Invested',
            currencyFormatter.format(holding.totalInvested),
            color: AppTheme.buyGreen,
            subtitle: 'incl. charges',
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _StatRow(
            'Total Sold',
            currencyFormatter.format(holding.totalSoldValue),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            subtitle: 'net of charges',
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          _StatRow(
            'Realized Gain',
            currencyFormatter.format(holding.realizedGain),
            color: holding.realizedGain >= 0
                ? AppTheme.accent
                : AppTheme.sellRed,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? subtitle;

  const _StatRow(this.label, this.value, {this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
