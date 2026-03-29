import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_bloc.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_event.dart';

void showConvertRightsDialog(BuildContext context, String symbol, VoidCallback onConverted) {
  if (!symbol.contains('.R')) return;
  final defaultTargetSymbol = '${symbol.split('.').first}.N0000';
  
  DateTime selectedDate = DateTime.now();
  final targetSymbolController = TextEditingController(text: defaultTargetSymbol);
  
  final dashState = context.read<DashboardBloc>().state;
  final currentHolding = dashState is DashboardLoaded
      ? dashState.holdings.where((h) => h.symbol == symbol).firstOrNull
      : null;
  final currentQty = currentHolding?.netQuantity ?? 0.0;
  
  final qtyController = TextEditingController(text: currentQty > 0 ? currentQty.toStringAsFixed(0) : '');
  final priceController = TextEditingController();
  bool logDeposit = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.cardDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final qty = double.tryParse(qtyController.text) ?? 0;
          final price = double.tryParse(priceController.text) ?? 0;
          final isValid = qty > 0 && qty <= currentQty && price > 0 && targetSymbolController.text.isNotEmpty;

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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3),
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
                              const Icon(Icons.autorenew, color: Colors.deepPurpleAccent, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Convert Rights',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Convert your $symbol rights into regular shares.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          TextField(
                            controller: targetSymbolController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Target Symbol',
                              hintText: 'e.g. MGT.N0000',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                          const SizedBox(height: 16),
                          
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Conversion Date'),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                            trailing: const Icon(Icons.calendar_today, size: 20),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: qtyController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Target Quantity',
                                    hintText: 'Max: ${currentQty.toStringAsFixed(0)}',
                                  ),
                                  onChanged: (_) => setSheetState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Price Per Share',
                                    hintText: 'e.g., 10.00',
                                  ),
                                  onChanged: (_) => setSheetState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          CheckboxListTile(
                            title: const Text('Log external deposit', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Automatically add a deposit for the conversion cost.', style: TextStyle(fontSize: 11)),
                            value: logDeposit,
                            activeColor: AppTheme.accent,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => logDeposit = v);
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          if (qty > currentQty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.sellRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: AppTheme.sellRed, size: 16),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Quantity exceeds current holding balance.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isValid
                                  ? () {
                                      Navigator.pop(sheetCtx);
                                      const channelId = 'other'; // default
                                      // 1. Add Conversion Trade
                                      context.read<TradeBloc>().add(AddTrade(
                                            channelId: channelId,
                                            action: 'rights_convert',
                                            symbol: symbol,
                                            targetSymbol: targetSymbolController.text.toUpperCase(),
                                            quantity: qty,
                                            price: price,
                                            smsDate: selectedDate,
                                            isManual: true,
                                          ));
                                          
                                      // 2. Add Deposit
                                      if (logDeposit) {
                                        context.read<FundTransferBloc>().add(AddFundTransfer(
                                            channelId: channelId,
                                            action: 'deposit',
                                            amount: qty * price,
                                            smsDate: selectedDate,
                                            isManual: true,
                                        ));
                                      }

                                      context.read<DashboardBloc>().add(RefreshDashboard());
                                      onConverted();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Rights conversion submitted to ${targetSymbolController.text}'),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isValid ? Colors.deepPurpleAccent : AppTheme.divider,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Convert',
                                style: TextStyle(
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
