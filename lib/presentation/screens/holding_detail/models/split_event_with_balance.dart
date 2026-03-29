import 'package:equity_echo/data/database/database.dart';

class SplitEventWithBalance {
  final StockSplit split;
  final double beforeQty;
  final double afterQty;

  SplitEventWithBalance({
    required this.split,
    required this.beforeQty,
    required this.afterQty,
  });
}
