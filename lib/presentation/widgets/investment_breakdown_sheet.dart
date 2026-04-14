import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';

/// Modal bottom sheet with a PieChart showing the funding sources
/// of the user's current portfolio book value.
class InvestmentBreakdownSheet extends StatefulWidget {
  final DashboardLoaded state;
  final NumberFormat currencyFormatter;

  const InvestmentBreakdownSheet({
    super.key,
    required this.state,
    required this.currencyFormatter,
  });

  static Future<void> show(
    BuildContext context, {
    required DashboardLoaded state,
    required NumberFormat currencyFormatter,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvestmentBreakdownSheet(
        state: state,
        currencyFormatter: currencyFormatter,
      ),
    );
  }

  @override
  State<InvestmentBreakdownSheet> createState() =>
      _InvestmentBreakdownSheetState();
}

class _InvestmentBreakdownSheetState extends State<InvestmentBreakdownSheet> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final fmt = widget.currencyFormatter;

    // Build slices — each must be > 0 to appear in pie
    final rawUnknown = s.investmentUnknown;

    final slices = <_Slice>[
      _Slice(
        label: 'Regular Deposits',
        value: s.regularDeposits,
        color: AppTheme.fundBlue,
        icon: Icons.arrow_downward,
      ),
      _Slice(
        label: 'IPO Deposits',
        value: s.ipoDeposits,
        color: AppTheme.accent,
        icon: Icons.new_releases,
      ),
      if (s.totalRealizedGain > 0)
        _Slice(
          label: 'Realized Gains',
          value: s.totalRealizedGain,
          color: const Color(0xFFFFB84D), // warning amber
          icon: Icons.trending_up,
        ),
      _Slice(
        label: 'Charges Paid',
        value: s.chargesPaid,
        color: AppTheme.sellRed,
        icon: Icons.remove_circle_outline,
        isCost: true,
      ),
      if (rawUnknown.abs() > 0.01)
        _Slice(
          label: rawUnknown > 0 ? 'Other / Dividends' : 'Unaccounted',
          value: rawUnknown.abs(),
          color: const Color(0xFF7B8FA6),
          icon: rawUnknown > 0 ? Icons.help_outline : Icons.warning_amber,
        ),
    ];

    // Only show positive-value slices in the pie
    final pieSlices = slices.where((s) => !s.isCost && s.value > 0).toList();

    final total = s.totalBookValue;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Total Invested',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              fmt.format(total),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Current portfolio cost basis',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Pie chart
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 55,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, PieTouchResponse? r) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            r == null ||
                            r.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = r.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: _buildSections(pieSlices, total),
                  centerSpaceColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Legend + all rows
            ...slices.map(
              (slice) => _LegendRow(
                slice: slice,
                total: total,
                formatter: fmt,
                highlighted: slice.isCost
                    ? false
                    : pieSlices.indexOf(slice) == _touchedIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<_Slice> pieSlices,
    double total,
  ) {
    return List.generate(pieSlices.length, (i) {
      final slice = pieSlices[i];
      final isTouched = i == _touchedIndex;
      final pct = total > 0 ? (slice.value / total * 100) : 0.0;
      return PieChartSectionData(
        color: slice.color,
        value: slice.value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 72 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black26)],
        ),
      );
    });
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isCost;

  const _Slice({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isCost = false,
  });
}

class _LegendRow extends StatelessWidget {
  final _Slice slice;
  final double total;
  final NumberFormat formatter;
  final bool highlighted;

  const _LegendRow({
    required this.slice,
    required this.total,
    required this.formatter,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (slice.value / total * 100) : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? slice.color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? Border.all(color: slice.color.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: slice.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(slice.icon, color: slice.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slice.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  slice.isCost
                      ? '− ${formatter.format(slice.value)}'
                      : formatter.format(slice.value),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: slice.color,
                  ),
                ),
              ],
            ),
          ),
          if (!slice.isCost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: slice.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: slice.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
