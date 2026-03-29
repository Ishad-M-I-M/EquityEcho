import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';
import 'package:equity_echo/data/database/database.dart';

class TradeCard extends StatefulWidget {
  final Trade trade;
  final String currentSymbol;
  final NumberFormat currencyFormatter;
  final VoidCallback onDelete;
  final bool isExempt;

  const TradeCard({
    super.key,
    required this.trade,
    required this.currentSymbol,
    required this.currencyFormatter,
    required this.onDelete,
    this.isExempt = false,
  });

  @override
  State<TradeCard> createState() => _TradeCardState();
}

class _TradeCardState extends State<TradeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final fmt = widget.currencyFormatter;
    
    final isRightsConvert = trade.action == 'rights_convert';
    final isConversionSource = isRightsConvert && trade.symbol == widget.currentSymbol;
    final isConversionTarget = isRightsConvert && trade.targetSymbol == widget.currentSymbol;
    
    final isBuy = trade.action.toLowerCase() == 'buy' || isConversionTarget;
    final color = isRightsConvert ? Colors.deepPurpleAccent : (isBuy ? AppTheme.buyGreen : AppTheme.sellRed);
    final isIpo = trade.isIpo;
    final isExempt = widget.isExempt;
    
    // conversions have NO transaction charges. Sells always do (unless 0 val).
    // buys have charges unless IPO.
    final hasCharges = !isRightsConvert && (!isIpo || !isBuy); 
    
    final breakdown = hasCharges
        ? (isExempt
            ? TransactionCharges.computeExempt(trade.totalValue)
            : TransactionCharges.compute(trade.totalValue))
        : null;

    // Effective total: what you actually pay (buy) or receive (sell)
    // For rights_convert, effective total is just the explicit cost (quantity * price).
    final effectiveTotal = isRightsConvert 
        ? trade.quantity * trade.price
        : (isBuy
            ? TransactionCharges.buyCost(trade.totalValue, isIpo: isIpo, isExempt: isExempt)
            : TransactionCharges.sellProceeds(trade.totalValue, isExempt: isExempt));

    return GestureDetector(
      onTap: hasCharges ? () => setState(() => _expanded = !_expanded) : null,
      onLongPress: widget.onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Main trade row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRightsConvert ? Icons.autorenew : (isBuy ? Icons.arrow_downward : Icons.arrow_upward),
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRightsConvert
                                ? (isConversionSource ? 'CONVERTED OUT' : 'CONVERTED IN')
                                : (isBuy ? 'BOUGHT' : 'SOLD'),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isIpo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'IPO',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          if (isExempt) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'INTRA-DAY',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                          if (trade.isAdjustment) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADJUSTMENT',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(trade.smsDate),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trade.quantity.toStringAsFixed(0)} × ${fmt.format(trade.price)}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(effectiveTotal),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (hasCharges) ...[
                        const SizedBox(height: 2),
                        Text(
                          isBuy ? 'Total Cost' : 'Net Proceeds',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Expand indicator
            if (hasCharges && !_expanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),

            // Expandable charges breakdown
            if (hasCharges && _expanded && breakdown != null) ...[
              Divider(height: 1, color: Theme.of(context).dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    _TradeChargeRow('Trade Value', '', trade.totalValue, fmt, isHeader: true),
                    const SizedBox(height: 4),
                    _TradeChargeRow('Brokerage Fee', '0.640%', breakdown.brokerageFee, fmt),
                    _TradeChargeRow('CSE Fees', '0.084%', breakdown.cseFee, fmt),
                    _TradeChargeRow('CDS Fees', '0.024%', breakdown.cdsFee, fmt),
                    _TradeChargeRow('SEC Cess', '0.072%', breakdown.secCess, fmt),
                    _TradeChargeRow('Share Trans. Levy', '0.300%', breakdown.shareTransactionLevy, fmt),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Charges',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          fmt.format(breakdown.totalCharges),
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBuy ? 'Total Cost' : 'Net Proceeds',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          fmt.format(effectiveTotal),
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradeChargeRow extends StatelessWidget {
  final String label;
  final String rate;
  final double amount;
  final NumberFormat formatter;
  final bool isHeader;

  const _TradeChargeRow(this.label, this.rate, this.amount, this.formatter,
      {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHeader ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isHeader ? 12 : 11,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (rate.isNotEmpty) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    rate,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              color: isHeader ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isHeader ? 12 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
