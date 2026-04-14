import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/chart_data_point.dart';
import '../models/chart_tab.dart';
import '../widgets/holding_chart_core.dart';

class FullScreenChartPage extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final NumberFormat currencyFormatter;
  final String symbol;
  final ChartTab initialTab;

  const FullScreenChartPage({
    super.key,
    required this.dataPoints,
    required this.currencyFormatter,
    required this.symbol,
    this.initialTab = ChartTab.investment,
  });

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  late ChartTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String _tabSummary() {
    if (widget.dataPoints.isEmpty) return '';
    final dp = widget.dataPoints.last;
    switch (_selectedTab) {
      case ChartTab.investment:
        return 'Cost Basis: ${widget.currencyFormatter.format(dp.costBasisInvestment)}';
      case ChartTab.qtyPrice:
        return 'Qty: ${dp.runningQuantity.toStringAsFixed(0)}  |  Price: ${widget.currencyFormatter.format(dp.price)}';
      case ChartTab.cashFlow:
        return 'Net Cash Flow: ${widget.currencyFormatter.format(dp.netCashFlowInvestment)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.symbol} Timeline',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _tabSummary(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SegmentedButton<ChartTab>(
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
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: HoldingChartCore(
                  dataPoints: widget.dataPoints,
                  currencyFormatter: widget.currencyFormatter,
                  symbol: widget.symbol,
                  selectedTab: _selectedTab,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
