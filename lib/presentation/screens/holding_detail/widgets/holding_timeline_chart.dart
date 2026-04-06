import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/chart_data_point.dart';
import 'text_fl_dot_painter.dart';
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
      _maxX = (widget.dataPoints.length > 1 ? widget.dataPoints.length - 1 : 1).toDouble();
    }
  }

  @override
  void didUpdateWidget(HoldingTimelineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints.length != widget.dataPoints.length) {
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedData = widget.dataPoints;

    double minQty = sortedData.map((p) => p.runningQuantity).reduce((a, b) => a < b ? a : b);
    double maxQty = sortedData.map((p) => p.runningQuantity).reduce((a, b) => a > b ? a : b);
    
    double minPrice = sortedData.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    double maxPrice = sortedData.map((p) => p.price).reduce((a, b) => a > b ? a : b);

    if (maxQty == minQty) {
      maxQty += 1;
      minQty -= 1.clamp(0, double.infinity);
    }
    if (maxPrice == minPrice) {
      maxPrice += 1;
      minPrice -= 1.clamp(0, double.infinity);
    }
    
    maxQty += (maxQty - minQty) * 0.1;

    double normalizePrice(double p) {
      if (maxPrice == minPrice) return minQty + (maxQty - minQty) / 2;
      return ((p - minPrice) / (maxPrice - minPrice)) * (maxQty - minQty) + minQty;
    }

    final qtySpots = <FlSpot>[];
    final priceSpots = <FlSpot>[];

    for (int i = 0; i < sortedData.length; i++) {
      final dp = sortedData[i];
      qtySpots.add(FlSpot(i.toDouble(), dp.runningQuantity));
      priceSpots.add(FlSpot(i.toDouble(), normalizePrice(dp.price)));
    }

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          GestureDetector(
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
                                text: 'Price: ${widget.currencyFormatter.format(dp.price)}\n',
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
                      interval: (sortedData.length / 4).ceilToDouble().clamp(1.0, double.infinity),
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
                    spots: priceSpots,
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
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.fullscreen),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                 Navigator.push(
                   context, 
                   MaterialPageRoute(
                     builder: (_) => FullScreenChartPage(
                       dataPoints: sortedData, 
                       currencyFormatter: widget.currencyFormatter,
                       symbol: widget.symbol,
                     ),
                   ),
                 );
              },
            ),
          ),
        ],
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
