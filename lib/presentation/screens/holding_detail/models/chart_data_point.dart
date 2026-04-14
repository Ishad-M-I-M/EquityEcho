enum ChartEventType { buy, sell, split, dividend, rightsConvert }

class ChartDataPoint {
  final DateTime date;
  final double runningQuantity;
  final double price;
  final ChartEventType eventType;
  final String label;
  final double costBasisInvestment;
  final double netCashFlowInvestment;

  ChartDataPoint({
    required this.date,
    required this.runningQuantity,
    required this.price,
    required this.eventType,
    this.label = '',
    this.costBasisInvestment = 0.0,
    this.netCashFlowInvestment = 0.0,
  });
}
