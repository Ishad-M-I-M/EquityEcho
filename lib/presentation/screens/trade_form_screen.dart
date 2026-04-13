import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/utils/transaction_charges.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_bloc.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_event.dart';
import 'package:equity_echo/presentation/blocs/trade/trade_state.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_state.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_bloc.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_event.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_bloc.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_event.dart';
import 'package:intl/intl.dart';

class TradeFormScreen extends StatefulWidget {
  final String? tradeId;
  final String? initialSymbol;
  final bool isIpo;

  const TradeFormScreen({
    super.key,
    this.tradeId,
    this.initialSymbol,
    this.isIpo = false,
  });

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String _action = 'buy';
  String? _channelId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _showChargesBreakdown = false;
  bool _priceIncludesCharges = false;

  bool get isEditing => widget.tradeId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialSymbol != null) {
      _symbolController.text = widget.initialSymbol!;
    }
    if (widget.isIpo) {
      _action = 'buy';
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Trade'
              : (widget.isIpo ? 'Add IPO Purchase' : 'Add Trade'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<TradeBloc, TradeState>(
        listener: (context, state) {
          if (state is TradeOperationSuccess) {
            context.read<DashboardBloc>().add(RefreshDashboard());
            context.read<ActivityLogBloc>().add(RefreshActivityLog());
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          } else if (state is TradeError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action toggle
                if (!widget.isIpo) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _action = 'buy'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _action == 'buy'
                                  ? AppTheme.buyGreen.withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _action == 'buy'
                                    ? AppTheme.buyGreen
                                    : Theme.of(context).dividerColor,
                                width: _action == 'buy' ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'BUY',
                                style: TextStyle(
                                  color: _action == 'buy'
                                      ? AppTheme.buyGreen
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _action = 'sell'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _action == 'sell'
                                  ? AppTheme.sellRed.withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _action == 'sell'
                                    ? AppTheme.sellRed
                                    : Theme.of(context).dividerColor,
                                width: _action == 'sell' ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'SELL',
                                style: TextStyle(
                                  color: _action == 'sell'
                                      ? AppTheme.sellRed
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Channel selector
                BlocBuilder<ChannelBloc, ChannelState>(
                  builder: (context, state) {
                    if (state is ChannelsLoaded && state.channels.isNotEmpty) {
                      _channelId ??= state.channels.first.id;
                      return DropdownButtonFormField<String>(
                        initialValue: _channelId,
                        decoration: const InputDecoration(
                          labelText: 'Broker Channel',
                        ),
                        items: state.channels
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _channelId = v),
                        validator: (v) => v == null ? 'Select a channel' : null,
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: AppTheme.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'No channels configured. Please add a channel first.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Symbol
                TextFormField(
                  controller: _symbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    hintText: 'e.g., MGT.N0000',
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Symbol is required' : null,
                ),
                const SizedBox(height: 16),

                // Quantity and Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: '0',
                        ),
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (!widget.isIpo) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Price includes charges'),
                    subtitle: Text(
                      _priceIncludesCharges
                          ? 'Entering the final amount paid/received per share.'
                          : 'Entering the raw exchange price per share.',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _priceIncludesCharges,
                    onChanged: (v) => setState(() => _priceIncludesCharges = v),
                    activeThumbColor: AppTheme.accent,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
                const SizedBox(height: 16),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(DateFormat('dd MMM yyyy').format(_date)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (picked != null) setState(() => _time = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            suffixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(_time.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Total value preview / charges breakdown
                ValueListenableBuilder(
                  valueListenable: _quantityController,
                  builder: (context, v1, c1) {
                    return ValueListenableBuilder(
                      valueListenable: _priceController,
                      builder: (context, v2, c2) {
                        final qty =
                            double.tryParse(_quantityController.text) ?? 0;
                        final price =
                            double.tryParse(_priceController.text) ?? 0;

                        final isBuy = _action == 'buy';

                        // Back-calculate raw price if needed
                        double rawPrice = price;
                        if (_priceIncludesCharges && !widget.isIpo) {
                          rawPrice = isBuy
                              ? price / (1 + TransactionCharges.totalRate)
                              : price / (1 - TransactionCharges.totalRate);
                        }

                        final total = qty * rawPrice;
                        if (total == 0) return const SizedBox.shrink();

                        final baseColor = isBuy
                            ? AppTheme.buyGreen
                            : AppTheme.sellRed;

                        // IPO purchases: show plain total only
                        if (widget.isIpo) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Value',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  total.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: baseColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Non-IPO trades: effective total + collapsible breakdown
                        final breakdown = TransactionCharges.compute(total);
                        final effectiveTotal = isBuy
                            ? TransactionCharges.buyCost(total)
                            : TransactionCharges.sellProceeds(total);
                        final effectiveLabel = isBuy
                            ? 'Total Cost'
                            : 'Net Proceeds';

                        return GestureDetector(
                          onTap: () => setState(
                            () =>
                                _showChargesBreakdown = !_showChargesBreakdown,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: baseColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Effective total (always visible)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: baseColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            effectiveLabel,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            _showChargesBreakdown
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        effectiveTotal.toStringAsFixed(2),
                                        style: TextStyle(
                                          color: baseColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Collapsible breakdown
                                if (_showChargesBreakdown) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Trade Value',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        total.toStringAsFixed(2),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_priceIncludesCharges) ...[
                                    _ChargeRow(
                                      label: 'Effective Raw Price',
                                      rate: 'calculated',
                                      amount: rawPrice,
                                    ),
                                  ],
                                  Divider(
                                    height: 16,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  _ChargeRow(
                                    label: 'Brokerage Fee',
                                    rate: '0.640%',
                                    amount: breakdown.brokerageFee,
                                  ),
                                  _ChargeRow(
                                    label: 'CSE Fees',
                                    rate: '0.084%',
                                    amount: breakdown.cseFee,
                                  ),
                                  _ChargeRow(
                                    label: 'CDS Fees',
                                    rate: '0.024%',
                                    amount: breakdown.cdsFee,
                                  ),
                                  _ChargeRow(
                                    label: 'SEC Cess',
                                    rate: '0.072%',
                                    amount: breakdown.secCess,
                                  ),
                                  _ChargeRow(
                                    label: 'Share Trans. Levy',
                                    rate: '0.300%',
                                    amount: breakdown.shareTransactionLevy,
                                  ),
                                  Divider(
                                    height: 16,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Charges (1.12%)',
                                        style: TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        breakdown.totalCharges.toStringAsFixed(
                                          2,
                                        ),
                                        style: TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _action == 'buy'
                          ? AppTheme.buyGreen
                          : AppTheme.sellRed,
                    ),
                    child: Text(
                      isEditing
                          ? 'Update Trade'
                          : (widget.isIpo ? 'Add IPO Purchase' : 'Add Trade'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_channelId == null) return;

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final enteredPrice = double.parse(_priceController.text);
    double rawPrice = enteredPrice;
    if (_priceIncludesCharges && !widget.isIpo) {
      final isBuy = _action == 'buy';
      rawPrice = isBuy
          ? enteredPrice / (1 + TransactionCharges.totalRate)
          : enteredPrice / (1 - TransactionCharges.totalRate);
    }

    if (isEditing) {
      context.read<TradeBloc>().add(
        UpdateTrade(
          id: widget.tradeId!,
          channelId: _channelId!,
          action: _action,
          symbol: _symbolController.text.trim().toUpperCase(),
          quantity: double.parse(_quantityController.text),
          price: rawPrice,
          smsDate: dateTime,
        ),
      );
    } else {
      context.read<TradeBloc>().add(
        AddTrade(
          channelId: _channelId!,
          action: _action,
          symbol: _symbolController.text.trim().toUpperCase(),
          quantity: double.parse(_quantityController.text),
          price: rawPrice,
          smsDate: dateTime,
          isManual: true,
          isIpo: widget.isIpo,
        ),
      );

      if (widget.isIpo) {
        context.read<FundTransferBloc>().add(
          AddFundTransfer(
            channelId: _channelId!,
            action: 'ipo_deposit',
            amount: double.parse(_quantityController.text) * rawPrice,
            smsDate: dateTime,
            rawSmsBody: _symbolController.text.trim().toUpperCase(),
            isManual: true,
          ),
        );
      }
    }
  }
}

/// A single fee row shown in the charges breakdown card.
class _ChargeRow extends StatelessWidget {
  final String label;
  final String rate;
  final double amount;

  const _ChargeRow({
    required this.label,
    required this.rate,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rate,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
