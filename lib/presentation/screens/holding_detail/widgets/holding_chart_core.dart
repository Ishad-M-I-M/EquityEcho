import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/chart_data_point.dart';
import '../models/chart_tab.dart';
import 'text_fl_dot_painter.dart';

class HoldingChartCore extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final NumberFormat currencyFormatter;
  final String symbol;
  final ChartTab selectedTab;

  const HoldingChartCore({
    super.key,
    required this.dataPoints,
    required this.currencyFormatter,
    required this.symbol,
    required this.selectedTab,
  });

  @override
  State<HoldingChartCore> createState() => _HoldingChartCoreState();
}

class _HoldingChartCoreState extends State<HoldingChartCore> {
  double _minX = 0;
  double _maxX = 1;

  @override
  void initState() {
    super.initState();
    _resetXAxis();
  }

  void _resetXAxis() {
    if (widget.dataPoints.isNotEmpty) {
      _minX = 0;
      _maxX = (widget.dataPoints.length > 1 ? widget.dataPoints.length - 1 : 1)
          .toDouble();
    }
  }

  @override
  void didUpdateWidget(HoldingChartCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints.length != widget.dataPoints.length ||
        oldWidget.selectedTab != widget.selectedTab) {
      _resetXAxis();
    }
  }

  void _handleDialogPopup(ChartDataPoint dp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dp.label.replaceAll('\n', ' ')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMM dd, yyyy').format(dp.date)}'),
            const SizedBox(height: 8),
            Text('Price: ${widget.currencyFormatter.format(dp.price)}'),
            const SizedBox(height: 8),
            Text('Current Quantity: ${dp.runningQuantity.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onPanZoom(ScaleUpdateDetails details, int dataLen) {
    if (dataLen <= 1)
      return; // Short-circuit to avoid division by zero or negative bounds

    if (details.scale != 1.0) {
      setState(() {
        double mid = (_minX + _maxX) / 2;
        double currentRange = _maxX - _minX;
        if (currentRange == 0) return;

        double newRange = currentRange / details.scale;
        if (newRange < 1) newRange = 1; // Prevent range hitting zero
        if (newRange > dataLen - 1) newRange = (dataLen - 1).toDouble();

        _minX = (mid - newRange / 2).clamp(
          0.0,
          (dataLen - 1 - newRange).toDouble(),
        );
        _maxX = _minX + newRange;
      });
    } else if (details.focalPointDelta.dx != 0) {
      if (_maxX - _minX == 0) return;

      setState(() {
        double delta =
            -details.focalPointDelta.dx /
            (MediaQuery.of(context).size.width / (_maxX - _minX));
        double range = _maxX - _minX;
        _minX = (_minX + delta).clamp(0.0, (dataLen - 1 - range).toDouble());
        _maxX = _minX + range;
      });
    }
  }

  AxisTitles _bottomTitles(List<ChartDataPoint> data, {int divisions = 4}) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: (data.length / divisions).ceilToDouble().clamp(
          1.0,
          double.infinity,
        ),
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= data.length) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              DateFormat('MM/yy').format(data[i].date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          );
        },
      ),
    );
  }

  FlGridData _gridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        strokeWidth: 1,
      ),
    );
  }

  String _compactNumber(double v) {
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  FlDotPainter _getEventPainter(ChartDataPoint dp, Color defaultColor) {
    const double radius = 8;
    switch (dp.eventType) {
      case ChartEventType.split:
        return TextFlDotPainter(
          text: 'S',
          color: Colors.orangeAccent,
          radius: radius,
        );
      case ChartEventType.dividend:
        return TextFlDotPainter(
          text: 'D',
          color: Colors.purpleAccent,
          radius: radius,
        );
      case ChartEventType.rightsConvert:
        return TextFlDotPainter(
          text: 'R',
          color: Colors.redAccent,
          radius: radius,
        );
      case ChartEventType.buy:
      case ChartEventType.sell:
        return FlDotCirclePainter(
          radius: 4,
          color: defaultColor,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        );
    }
  }

  void Function(FlTouchEvent, LineTouchResponse?) _buildTouchCallback(
    List<ChartDataPoint> data,
  ) {
    return (FlTouchEvent event, LineTouchResponse? touchResponse) {
      if (event is FlTapUpEvent &&
          touchResponse != null &&
          touchResponse.lineBarSpots != null) {
        final xIdx = touchResponse.lineBarSpots!.first.x.toInt();
        if (xIdx >= 0 && xIdx < data.length) {
          final dp = data[xIdx];
          if (dp.eventType == ChartEventType.split ||
              dp.eventType == ChartEventType.dividend ||
              dp.eventType == ChartEventType.rightsConvert) {
            _handleDialogPopup(dp);
          }
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) return const SizedBox.shrink();

    switch (widget.selectedTab) {
      case ChartTab.investment:
        return _buildInvestmentChart();
      case ChartTab.qtyPrice:
        return _buildQtyPriceChart();
      case ChartTab.cashFlow:
        return _buildCashFlowChart();
    }
  }

  Widget _buildInvestmentChart() {
    final data = widget.dataPoints;

    double minY = data
        .map((p) => p.costBasisInvestment)
        .reduce((a, b) => a < b ? a : b);
    double maxY = data
        .map((p) => p.costBasisInvestment)
        .reduce((a, b) => a > b ? a : b);
    if (maxY == minY) {
      maxY += 1;
      minY = (minY - 1).clamp(0, double.infinity);
    }
    final padding = (maxY - minY) * 0.1;
    maxY += padding;
    minY = (minY - padding).clamp(0, double.infinity);

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].costBasisInvestment));
    }

    return GestureDetector(
      onScaleUpdate: (d) => _onPanZoom(d, data.length),
      child: LineChart(
        LineChartData(
          minX: _minX,
          maxX: _maxX,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchCallback: _buildTouchCallback(data),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.85),
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final xIdx = touchedSpots.first.x.toInt();
                if (xIdx < 0 || xIdx >= data.length) return [];
                final dp = data[xIdx];
                return [
                  LineTooltipItem(
                    '${DateFormat('MMM dd, yyyy').format(dp.date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Invested: ${widget.currencyFormatter.format(dp.costBasisInvestment)}\n',
                        style: const TextStyle(
                          color: Color(0xFF4DFFC3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: 'Qty: ${dp.runningQuantity.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.blueAccent.shade100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dp.label.isNotEmpty) ...[
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: dp.label,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  ...List.filled(touchedSpots.length - 1, null),
                ];
              },
            ),
          ),
          gridData: _gridData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _compactNumber(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: _bottomTitles(data),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: const Color(0xFF00E5A0),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    _getEventPainter(data[index], const Color(0xFF00E5A0)),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00E5A0).withValues(alpha: 0.25),
                    const Color(0xFF00E5A0).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyPriceChart() {
    final data = widget.dataPoints;

    double minQty = data
        .map((p) => p.runningQuantity)
        .reduce((a, b) => a < b ? a : b);
    double maxQty = data
        .map((p) => p.runningQuantity)
        .reduce((a, b) => a > b ? a : b);
    double minPrice = data.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    double maxPrice = data.map((p) => p.price).reduce((a, b) => a > b ? a : b);

    if (maxQty == minQty) {
      maxQty += 1;
      minQty = (minQty - 1).clamp(0, double.infinity);
    }
    if (maxPrice == minPrice) {
      maxPrice += 1;
      minPrice = (minPrice - 1).clamp(0, double.infinity);
    }
    maxQty += (maxQty - minQty) * 0.1;

    double normalizePrice(double p) {
      if (maxPrice == minPrice) return minQty + (maxQty - minQty) / 2;
      return ((p - minPrice) / (maxPrice - minPrice)) * (maxQty - minQty) +
          minQty;
    }

    final qtySpots = <FlSpot>[];
    final priceSpots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      qtySpots.add(FlSpot(i.toDouble(), data[i].runningQuantity));
      priceSpots.add(FlSpot(i.toDouble(), normalizePrice(data[i].price)));
    }

    return GestureDetector(
      onScaleUpdate: (d) => _onPanZoom(d, data.length),
      child: LineChart(
        LineChartData(
          minX: _minX,
          maxX: _maxX,
          minY: minQty,
          maxY: maxQty,
          lineTouchData: LineTouchData(
            touchCallback: _buildTouchCallback(data),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.85),
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final xIdx = touchedSpots.first.x.toInt();
                if (xIdx < 0 || xIdx >= data.length) return [];
                final dp = data[xIdx];
                final items = <LineTooltipItem?>[];
                for (int i = 0; i < touchedSpots.length; i++) {
                  if (i == 0) {
                    items.add(
                      LineTooltipItem(
                        '${DateFormat('MMM dd, yyyy').format(dp.date)}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Qty: ${dp.runningQuantity.toStringAsFixed(0)}\n',
                            style: TextStyle(
                              color: Colors.blueAccent.shade100,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Price: ${widget.currencyFormatter.format(dp.price)}\n',
                            style: TextStyle(
                              color: Colors.greenAccent.shade100,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (dp.label.isNotEmpty)
                            TextSpan(
                              text: dp.label,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    );
                  } else {
                    items.add(null);
                  }
                }
                return items;
              },
            ),
          ),
          gridData: _gridData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Quantity',
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  fontSize: 10,
                ),
              ),
              axisNameSize: 16,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: Text(
                'Price',
                style: TextStyle(
                  color: Colors.greenAccent.shade100,
                  fontSize: 10,
                ),
              ),
              axisNameSize: 16,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  // Convert normalized value back to real price
                  if (maxPrice == minPrice) return const SizedBox.shrink();
                  final realPrice =
                      ((value - minQty) / (maxQty - minQty)) *
                          (maxPrice - minPrice) +
                      minPrice;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      realPrice.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.greenAccent.shade200,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: _bottomTitles(data),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: qtySpots,
              isCurved: false,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    _getEventPainter(data[index], Colors.blueAccent),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: priceSpots,
              isCurved: false,
              color: Colors.greenAccent,
              barWidth: 2,
              dashArray: [4, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: Colors.greenAccent,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowChart() {
    final data = widget.dataPoints;

    double minY = data
        .map((p) => p.netCashFlowInvestment)
        .reduce((a, b) => a < b ? a : b);
    double maxY = data
        .map((p) => p.netCashFlowInvestment)
        .reduce((a, b) => a > b ? a : b);

    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }
    final padding = (maxY - minY) * 0.15;
    maxY += padding;
    minY -= padding;

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final v = data[i].netCashFlowInvestment;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: v,
              fromY: 0,
              width: data.length > 20 ? 4 : 8,
              borderRadius: BorderRadius.vertical(
                top: v >= 0 ? const Radius.circular(3) : Radius.zero,
                bottom: v < 0 ? const Radius.circular(3) : Radius.zero,
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: v >= 0
                    ? [
                        const Color(0xFF00E5A0).withValues(alpha: 0.6),
                        const Color(0xFF00E5A0),
                      ]
                    : [
                        const Color(0xFFFF6B6B),
                        const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                      ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onScaleUpdate: (d) => _onPanZoom(d, data.length),
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.85),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final idx = group.x;
                if (idx < 0 || idx >= data.length) return null;
                final dp = data[idx];
                return BarTooltipItem(
                  '${DateFormat('MMM dd, yyyy').format(dp.date)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'Net Cash Flow: ${widget.currencyFormatter.format(dp.netCashFlowInvestment)}\n',
                      style: TextStyle(
                        color: dp.netCashFlowInvestment >= 0
                            ? const Color(0xFF4DFFC3)
                            : const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dp.label.isNotEmpty)
                      TextSpan(
                        text: dp.label,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          gridData: _gridData(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _compactNumber(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: _bottomTitles(data),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
