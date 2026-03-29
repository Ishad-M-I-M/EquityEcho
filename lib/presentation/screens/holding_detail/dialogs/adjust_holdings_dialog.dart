import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';

void showAdjustDialog(BuildContext context, String symbol, VoidCallback onAdjusted) {
  final qtyController = TextEditingController();
  final priceController = TextEditingController();

  // Get current tracked holding state
  final dashState = context.read<DashboardBloc>().state;
  final currentHolding = dashState is DashboardLoaded
      ? dashState.holdings.where((h) => h.symbol == symbol).firstOrNull
      : null;
  final currentQty = currentHolding?.netQuantity ?? 0.0;
  final currentAvgCost = currentHolding?.avgCostWithCharges ?? 0.0;
  final currentPool = currentQty * currentAvgCost;
  const channelId = 'other';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final targetQty = double.tryParse(qtyController.text) ?? 0;
          final targetAvgPrice = double.tryParse(priceController.text) ?? 0;
          final targetPool = targetQty * targetAvgPrice;

          final diffQty = targetQty - currentQty;
          final diffValue = targetPool - currentPool;

          final hasDiff = diffQty != 0 && targetAvgPrice > 0;
          double effectiveAdjPrice = 0;
          bool isAddition = false;
          bool isValid = false;

          if (hasDiff) {
            effectiveAdjPrice = diffValue / diffQty;
            isAddition = diffQty > 0;
            isValid = effectiveAdjPrice > 0;
          }

          ChargesBreakdown? breakdown;
          double rawAdjPrice = 0;
          double adjustmentTotalValueForRecord = 0;

          if (isValid) {
            rawAdjPrice = isAddition
                ? effectiveAdjPrice / (1 + TransactionCharges.totalRate)
                : effectiveAdjPrice / (1 - TransactionCharges.totalRate);
            adjustmentTotalValueForRecord = diffQty.abs() * rawAdjPrice;
            breakdown = TransactionCharges.compute(adjustmentTotalValueForRecord);
          }

          Widget detailRow(String label, String value, {Color? color}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  Text(value,
                      style: TextStyle(
                          color: color ?? Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune, color: AppTheme.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Adjust $symbol Holdings',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Correct your tracked portfolio to match your actual statement.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Current state: ${currentQty.toStringAsFixed(0)} shares @ ${currentAvgCost.toStringAsFixed(2)} average',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Target Total Quantity',
                              hintText: 'Enter your total shares...',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Target Average Cost (incl. charges)',
                              hintText: 'Enter your statement average...',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                          const SizedBox(height: 20),

                          // Preview
                          if (isValid) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isAddition
                                            ? 'Adjustment: Addition'
                                            : 'Adjustment: Removal',
                                        style: TextStyle(
                                          color: isAddition ? AppTheme.buyGreen : AppTheme.sellRed,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${diffQty.abs().toStringAsFixed(0)} shares @ ${effectiveAdjPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAddition
                                        ? 'Creating a BUY entry to increase cost basis to your target.'
                                        : 'Creating a SELL entry to reduce holdings and cost basis.',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Divider(height: 20, color: Theme.of(context).dividerColor),
                                  detailRow(
                                    'Raw Trade Value',
                                    adjustmentTotalValueForRecord.toStringAsFixed(2),
                                  ),
                                  detailRow(
                                    'Applicable Charges (1.12%)',
                                    breakdown!.totalCharges.toStringAsFixed(2),
                                    color: AppTheme.warning,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isAddition ? 'Net Addition Value' : 'Net Removal Value',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        (isAddition
                                                ? TransactionCharges.buyCost(adjustmentTotalValueForRecord)
                                                : TransactionCharges.sellProceeds(adjustmentTotalValueForRecord))
                                            .toStringAsFixed(2),
                                        style: TextStyle(
                                          color: isAddition ? AppTheme.buyGreen : AppTheme.sellRed,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else if (hasDiff && !isValid) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.sellRed.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.error_outline, color: AppTheme.sellRed, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Impossible Adjustment',
                                          style: TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'The target states requires increasing quantity while decreasing total value (or vice-versa), which cannot be mapped to a single trade. Please check your targets.',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (targetQty > 0 && targetAvgPrice > 0 && diffQty == 0) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: AppTheme.accent, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Current quantity matches target. No shares to add or remove.'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isValid
                                  ? () {
                                      Navigator.pop(sheetCtx);
                                      context.read<TradeBloc>().add(AddTrade(
                                            channelId: channelId,
                                            action: isAddition ? 'buy' : 'sell',
                                            symbol: symbol,
                                            quantity: diffQty.abs(),
                                            price: rawAdjPrice,
                                            smsDate: DateTime.now(),
                                            isManual: true,
                                            isAdjustment: true,
                                          ));
                                      context.read<DashboardBloc>().add(RefreshDashboard());
                                      onAdjusted();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Adjustment: Created ${isAddition ? "BUY" : "SELL"} entry for ${diffQty.abs().toStringAsFixed(0)} shares.',
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isValid
                                    ? (isAddition ? AppTheme.buyGreen : AppTheme.sellRed)
                                    : Theme.of(context).dividerColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isValid ? 'Apply Adjustment' : 'Invalid Targets',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
