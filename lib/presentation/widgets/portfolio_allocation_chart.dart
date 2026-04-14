import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/data/models/holding.dart';

/// Donut PieChart showing each active holding's share of total portfolio
/// book value. Tapping a slice calls [onHoldingTap] with the symbol.
class PortfolioAllocationChart extends StatefulWidget {
  final List<Holding> holdings;
  final void Function(String symbol) onHoldingTap;

  const PortfolioAllocationChart({
    super.key,
    required this.holdings,
    required this.onHoldingTap,
  });

  @override
  State<PortfolioAllocationChart> createState() =>
      _PortfolioAllocationChartState();
}

class _PortfolioAllocationChartState extends State<PortfolioAllocationChart> {
  int _touchedIndex = -1;
  bool _isByValue = true;

  // Predictable color palette for slices
  static const _palette = [
    Color(0xFF00E5A0), // accent green
    Color(0xFF5CB8FF), // fund blue
    Color(0xFFFFB84D), // amber
    Color(0xFFFF6B6B), // red
    Color(0xFFB48BFF), // purple
    Color(0xFF4DFFC3), // mint
    Color(0xFFFF8C69), // salmon
    Color(0xFF64D2FF), // sky
    Color(0xFFFFD166), // yellow
    Color(0xFFFF70A6), // pink
  ];

  @override
  Widget build(BuildContext context) {
    final active = widget.holdings.where((h) => h.netQuantity > 0).toList()
      ..sort(
        (a, b) => _isByValue
            ? b.currentValue.compareTo(a.currentValue)
            : b.netQuantity.compareTo(a.netQuantity),
      );

    if (active.isEmpty) return const SizedBox.shrink();

    final total = _isByValue
        ? active.fold(0.0, (sum, h) => sum + h.currentValue)
        : active.fold(0.0, (sum, h) => sum + h.netQuantity);
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_large, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Portfolio Allocation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              // Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggle(
                      'Value',
                      _isByValue,
                      () => setState(() => _isByValue = true),
                    ),
                    _buildToggle(
                      'Shares',
                      !_isByValue,
                      () => setState(() => _isByValue = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart
              SizedBox(
                height: 170,
                width: 170,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 46,
                    centerSpaceColor: Theme.of(context).cardColor,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, PieTouchResponse? r) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              r == null ||
                              r.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          final idx = r.touchedSection!.touchedSectionIndex;
                          _touchedIndex = idx;
                          if (event is FlTapUpEvent) {
                            if (idx >= 0 && idx < active.length) {
                              widget.onHoldingTap(active[idx].symbol);
                            }
                          }
                        });
                      },
                    ),
                    sections: _buildSections(active, total),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    active.length > 8 ? 8 : active.length,
                    (i) {
                      final h = active[i];
                      final color = _palette[i % _palette.length];
                      final val = _isByValue ? h.currentValue : h.netQuantity;
                      final pct = val / total * 100;
                      final isTouched = i == _touchedIndex;
                      return GestureDetector(
                        onTap: () => widget.onHoldingTap(h.symbol),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  h.symbol,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isTouched
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isTouched
                                        ? color
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (active.length > 8) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${active.length - 8} more holdings',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppTheme.accent
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<Holding> holdings,
    double total,
  ) {
    return List.generate(holdings.length, (i) {
      final h = holdings[i];
      final color = _palette[i % _palette.length];
      final isTouched = i == _touchedIndex;
      final val = _isByValue ? h.currentValue : h.netQuantity;
      final pct = val / total * 100;

      return PieChartSectionData(
        color: color,
        value: val.toDouble(),
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 58 : 46,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
