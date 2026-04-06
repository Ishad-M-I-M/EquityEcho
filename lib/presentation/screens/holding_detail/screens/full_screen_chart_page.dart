import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/chart_data_point.dart';
import '../widgets/text_fl_dot_painter.dart';

class FullScreenChartPage extends StatefulWidget {
  final List<ChartDataPoint> dataPoints;
  final NumberFormat currencyFormatter;
  final String symbol;

  const FullScreenChartPage({
    super.key,
    required this.dataPoints,
    required this.currencyFormatter,
    required this.symbol,
  });

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  int _investmentMode = 2; // 1 = Net Cash Flow, 2 = Cost Basis
  double _minX = 0;
  double _maxX = 1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    if (widget.dataPoints.isNotEmpty) {
      _maxX = (widget.dataPoints.length > 1 ? widget.dataPoints.length - 1 : 1).toDouble();
    }
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    double currentInvest = _investmentMode == 2 
        ? widget.dataPoints.last.costBasisInvestment 
        : widget.dataPoints.last.netCashFlowInvestment;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.symbol} Timeline',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cumulative Holding: ${widget.dataPoints.last.runningQuantity.toStringAsFixed(0)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        'Cumulative Invested: ${widget.currencyFormatter.format(currentInvest)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  DropdownButton<int>(
                    value: _investmentMode,
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('Cost Basis')),
                      DropdownMenuItem(value: 1, child: Text('Net Cash Flow')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _investmentMode = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 32, 16),
                child: _buildChart(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final sortedData = widget.dataPoints;

    double minQty = sortedData.map((p) => p.runningQuantity).reduce((a, b) => a < b ? a : b);
    double maxQty = sortedData.map((p) => p.runningQuantity).reduce((a, b) => a > b ? a : b);
    
    double minInvest = sortedData.map((p) => _investmentMode == 2 ? p.costBasisInvestment : p.netCashFlowInvestment).reduce((a, b) => a < b ? a : b);
    double maxInvest = sortedData.map((p) => _investmentMode == 2 ? p.costBasisInvestment : p.netCashFlowInvestment).reduce((a, b) => a > b ? a : b);

    if (maxQty == minQty) {
      maxQty += 1;
      minQty -= 1.clamp(0, double.infinity);
    }
    if (maxInvest == minInvest) {
      maxInvest += 1;
      minInvest -= 1.clamp(0, double.infinity);
    }
    
    maxQty += (maxQty - minQty) * 0.1;

    double normalizeInvest(double p) {
      if (maxInvest == minInvest) return minQty + (maxQty - minQty) / 2;
      return ((p - minInvest) / (maxInvest - minInvest)) * (maxQty - minQty) + minQty;
    }

    final qtySpots = <FlSpot>[];
    final investSpots = <FlSpot>[];

    for (int i = 0; i < sortedData.length; i++) {
      final dp = sortedData[i];
      qtySpots.add(FlSpot(i.toDouble(), dp.runningQuantity));
      
      double inv = _investmentMode == 2 ? dp.costBasisInvestment : dp.netCashFlowInvestment;
      investSpots.add(FlSpot(i.toDouble(), normalizeInvest(inv)));
    }

    return GestureDetector(
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          setState(() {
            double mid = (_minX + _maxX) / 2;
            double currentRange = _maxX - _minX;
            double newRange = currentRange / details.scale;
            if (newRange < 2) newRange = 2;
            if (newRange > sortedData.length - 1) newRange = (sortedData.length - 1).toDouble();
            
            _minX = (mid - newRange / 2).clamp(0, sortedData.length - 1 - newRange);
            _maxX = _minX + newRange;
          });
        } else if (details.focalPointDelta.dx != 0) {
          setState(() {
             double delta = -details.focalPointDelta.dx / (MediaQuery.of(context).size.width / (_maxX - _minX)); 
             double range = _maxX - _minX;
             _minX = (_minX + delta).clamp(0, sortedData.length - 1 - range);
             _maxX = _minX + range;
          });
        }
      },
      child: LineChart(
        LineChartData(
          minX: _minX,
          maxX: _maxX,
          minY: minQty,
          maxY: maxQty,
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                final xIdx = touchResponse.lineBarSpots!.first.x.toInt();
                if (xIdx >= 0 && xIdx < sortedData.length) {
                  final dp = sortedData[xIdx];
                  if (dp.eventType == ChartEventType.split || 
                      dp.eventType == ChartEventType.dividend || 
                      dp.eventType == ChartEventType.rightsConvert) {
                    _handleDialogPopup(dp);
                  }
                }
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];
                final xIdx = touchedSpots.first.x.toInt();
                if (xIdx < 0 || xIdx >= sortedData.length) return [];
                
                final dp = sortedData[xIdx];
                final dateStr = DateFormat('MMM dd, yyyy').format(dp.date);
                double inv = _investmentMode == 2 ? dp.costBasisInvestment : dp.netCashFlowInvestment;
                
                final tooltipItems = <LineTooltipItem?>[];
                for (int i = 0; i < touchedSpots.length; i++) {
                  if (i == 0) {
                    tooltipItems.add(LineTooltipItem(
                      '$dateStr\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Qty: ${dp.runningQuantity.toStringAsFixed(0)}\n',
                          style: TextStyle(color: Colors.blueAccent.shade100, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: 'Invested: ${widget.currencyFormatter.format(inv)}\n',
                          style: TextStyle(color: Colors.greenAccent.shade100, fontWeight: FontWeight.w600),
                        ),
                        if (dp.label.isNotEmpty)
                          TextSpan(
                            text: dp.label,
                            style: const TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ));
                  } else {
                    tooltipItems.add(null);
                  }
                }
                return tooltipItems;
              },
            ),
          ),
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (sortedData.length / 8).ceilToDouble().clamp(1.0, double.infinity),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sortedData.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('MM/yy').format(sortedData[i].date),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                getDotPainter: (spot, percent, barData, index) {
                  return _getPainter(sortedData[index], Colors.blueAccent);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: investSpots,
              isCurved: false,
              color: Colors.greenAccent,
              barWidth: 2,
              dashArray: [4, 4], 
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.greenAccent,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  FlDotPainter _getPainter(ChartDataPoint dp, Color defaultColor) {
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
}
