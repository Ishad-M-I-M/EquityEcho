import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/data/models/activity_item.dart';

/// Displays an activity item (trade or fund transfer) as a list tile
class ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ActivityTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isTrade = item.type == ActivityType.trade;
    final isBuy = item.tradeAction?.name == 'buy';
    final isDeposit =
        item.fundAction?.name == 'deposit' ||
        item.fundAction?.name == 'ipoDeposit';
    final isIpoDeposit = item.fundAction?.name == 'ipoDeposit';

    Color actionColor;
    IconData actionIcon;
    String actionLabel;

    if (isTrade) {
      actionColor = isBuy ? AppTheme.buyGreen : AppTheme.sellRed;
      actionIcon = isBuy ? Icons.arrow_downward : Icons.arrow_upward;
      actionLabel = isBuy ? 'BUY' : 'SELL';
    } else {
      if (isIpoDeposit) {
        actionColor = AppTheme.accent;
        actionIcon = Icons.new_releases;
        actionLabel = 'IPO DEPOSIT';
      } else {
        actionColor = isDeposit ? AppTheme.fundBlue : AppTheme.warning;
        actionIcon = isDeposit ? Icons.account_balance_wallet : Icons.output;
        actionLabel = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Action icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(actionIcon, color: actionColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isTrade && item.isIpo) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'IPO',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (isTrade && item.isAdjustment) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADJ',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      if (isTrade)
                        Expanded(
                          child: Text(
                            item.symbol ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (isIpoDeposit && item.rawSmsBody.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.rawSmsBody,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      if (item.isManual)
                        Icon(
                          Icons.edit_note,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isTrade)
                    Text(
                      '${item.quantity?.toStringAsFixed(0)} × ${item.price?.toStringAsFixed(2)} = ${item.totalValue?.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      '${item.amount?.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: actionColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM dd').format(item.date),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(item.date),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.channelName,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
