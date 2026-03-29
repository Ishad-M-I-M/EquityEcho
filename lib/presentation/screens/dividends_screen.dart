import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';

class DividendsScreen extends StatefulWidget {
  const DividendsScreen({super.key});

  @override
  State<DividendsScreen> createState() => _DividendsScreenState();
}

class _DividendsScreenState extends State<DividendsScreen> {
  late Stream<List<Dividend>> _dividendsStream;

  @override
  void initState() {
    super.initState();
    _dividendsStream = getIt<DividendDao>().watchAllDividends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dividends Received'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDividendDialog(context),
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Dividend>>(
        stream: _dividendsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.sellRed)));
          }

          final allDividends = snapshot.data ?? [];
          
          if (allDividends.isEmpty) {
            return Center(
              child: Text(
                'No dividends recorded yet.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            );
          }

          // Group by symbol
          final grouped = <String, double>{};
          for (var div in allDividends) {
            grouped[div.symbol] = (grouped[div.symbol] ?? 0.0) + div.amount;
          }

          final sortedGroups = grouped.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // sort by highest received

          return BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, dashboardState) {
              String currencySymbol = 'LKR ';
              if (dashboardState is DashboardLoaded) {
                currencySymbol = '${dashboardState.currency} ';
              }
              final currencyFormatter = NumberFormat.currency(
                symbol: currencySymbol,
                decimalDigits: 2,
              );

              double totalDividendsVal = grouped.values.fold(0.0, (s, v) => s + v);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.buyGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.buyGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Received',
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(totalDividendsVal),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.buyGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Grouped by Symbol',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...sortedGroups.map((entry) {
                    final symbol = entry.key;
                    final sum = entry.value;

                    return GestureDetector(
                      onTap: () => context.push('/dividends/$symbol'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.card_giftcard, color: AppTheme.accent, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  symbol,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(sum),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.buyGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDividendDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final symbolController = TextEditingController();
    final sharesController = TextEditingController();
    final dpsController = TextEditingController();
    final taxController = TextEditingController();
    bool reinvest = false;

    final dashboardState = context.read<DashboardBloc>().state;
    List<String> availableSymbols = [];
    if (dashboardState is DashboardLoaded) {
      availableSymbols = dashboardState.holdings.map((h) => h.symbol).toList();
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            double shares = double.tryParse(sharesController.text) ?? 0.0;
            double dps = double.tryParse(dpsController.text) ?? 0.0;
            double taxAmount = double.tryParse(taxController.text) ?? 0.0;
            double gross = shares * dps;
            double net = gross - taxAmount;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Add Dividend'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final val = textEditingValue.text.toUpperCase();
                        if (val.isEmpty) {
                          return availableSymbols;
                        }
                        return availableSymbols.where((s) => s.contains(val));
                      },
                      onSelected: (String selection) {
                        symbolController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        // Manually sync if the user types freely
                        controller.addListener(() {
                           symbolController.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Symbol',
                            hintText: 'e.g. JKH',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sharesController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setStateLocal(() {}),
                            decoration: const InputDecoration(
                              labelText: 'No. of Shares',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: dpsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setStateLocal(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Div / Share',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setStateLocal(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tax Deducted (Amount)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gross Dividend', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              Text(net > 0 ? gross.toStringAsFixed(2) : '0.00'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tax Deducted', style: TextStyle(color: AppTheme.sellRed)),
                              Text(taxAmount > 0 ? '-${taxAmount.toStringAsFixed(2)}' : '0.00', style: TextStyle(color: AppTheme.sellRed)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Net Dividend', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(net > 0 ? net.toStringAsFixed(2) : '0.00', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.buyGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: reinvest,
                      onChanged: (val) => setStateLocal(() => reinvest = val ?? false),
                      title: const Text('Reinvest as Deposit', style: TextStyle(fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.accent,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
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
                          setStateLocal(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () async {
                    final symbolStr = symbolController.text.trim().toUpperCase();
                    if (symbolStr.isEmpty || net <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid symbol and amounts')),
                      );
                      return;
                    }
                    
                    Navigator.pop(dialogCtx);
                    
                    final companion = DividendsCompanion.insert(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      symbol: symbolStr,
                      amount: net,
                      tax: drift.Value(taxAmount),
                      shares: drift.Value(shares),
                      dividendPerShare: drift.Value(dps),
                      date: selectedDate,
                    );
                    await getIt<DividendDao>().insertDividend(companion);

                    if (reinvest) {
                      final fundId = '${DateTime.now().millisecondsSinceEpoch}_div';
                      final fundCompanion = FundTransfersCompanion.insert(
                        id: fundId,
                        channelId: 'other', 
                        action: 'deposit',
                        amount: net,
                        smsDate: selectedDate,
                        rawSmsBody: drift.Value('Dividend Received Reinvestment: $symbolStr'),
                        isManual: const drift.Value(true),
                      );
                      await getIt<FundTransferDao>().insertFundTransfer(fundCompanion);
                    }
                    
                    if (!context.mounted) return;
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  },
                  child: Text('Save', style: TextStyle(color: AppTheme.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
