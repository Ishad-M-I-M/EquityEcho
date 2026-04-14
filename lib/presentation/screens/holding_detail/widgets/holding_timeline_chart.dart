import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data_point.dart';
import '../models/chart_tab.dart';
import 'holding_chart_core.dart';
import '../screens/full_screen_chart_page.dart';

class HoldingTimelineChart extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final NumberFormat currencyFormatter;
  final String symbol;

  const HoldingTimelineChart({
    super.key,
    required this.dataPoints,
    required this.currencyFormatter,
    required this.symbol,
  });

  @override
  State<HoldingTimelineChart> createState() => _HoldingTimelineChartState();
}

class _HoldingTimelineChartState extends State<HoldingTimelineChart> {
  ChartTab _selectedTab = ChartTab.investment;

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ChartTab>(
            segments: const [
              ButtonSegment(
                value: ChartTab.investment,
                label: Text('Investment'),
                icon: Icon(Icons.show_chart, size: 16),
              ),
              ButtonSegment(
                value: ChartTab.qtyPrice,
                label: Text('Qty & Price'),
                icon: Icon(Icons.stacked_line_chart, size: 16),
              ),
              ButtonSegment(
                value: ChartTab.cashFlow,
                label: Text('Cash Flow'),
                icon: Icon(Icons.bar_chart, size: 16),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (s) => setState(() {
              _selectedTab = s.first;
            }),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Chart body
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              HoldingChartCore(
                dataPoints: widget.dataPoints,
                currencyFormatter: widget.currencyFormatter,
                symbol: widget.symbol,
                selectedTab: _selectedTab,
              ),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenChartPage(
                          dataPoints: widget.dataPoints,
                          currencyFormatter: widget.currencyFormatter,
                          symbol: widget.symbol,
                          initialTab: _selectedTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
