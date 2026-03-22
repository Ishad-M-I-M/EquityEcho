import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
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

  const TradeFormScreen({super.key, this.tradeId, this.initialSymbol, this.isIpo = false});

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
        title: Text(isEditing ? 'Edit Trade' : (widget.isIpo ? 'Add IPO Purchase' : 'Add Trade')),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop();
          } else if (state is TradeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                                  : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _action == 'buy'
                                    ? AppTheme.buyGreen
                                    : AppTheme.divider,
                                width: _action == 'buy' ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'BUY',
                                style: TextStyle(
                                  color: _action == 'buy'
                                      ? AppTheme.buyGreen
                                      : AppTheme.textSecondary,
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
                                  : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _action == 'sell'
                                    ? AppTheme.sellRed
                                    : AppTheme.divider,
                                width: _action == 'sell' ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'SELL',
                                style: TextStyle(
                                  color: _action == 'sell'
                                      ? AppTheme.sellRed
                                      : AppTheme.textSecondary,
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
                        decoration:
                            const InputDecoration(labelText: 'Broker Channel'),
                        items: state.channels
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _channelId = v),
                        validator: (v) =>
                            v == null ? 'Select a channel' : null,
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
                          Icon(Icons.warning_amber,
                              color: AppTheme.warning, size: 18),
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
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
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

                // Total value preview
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
                        final total = qty * price;
                        if (total == 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _action == 'buy'
                                ? AppTheme.buyGreen.withValues(alpha: 0.08)
                                : AppTheme.sellRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Value',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                total.toStringAsFixed(2),
                                style: TextStyle(
                                  color: _action == 'buy'
                                      ? AppTheme.buyGreen
                                      : AppTheme.sellRed,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
                      backgroundColor:
                          _action == 'buy' ? AppTheme.buyGreen : AppTheme.sellRed,
                    ),
                    child: Text(isEditing ? 'Update Trade' : (widget.isIpo ? 'Add IPO Purchase' : 'Add Trade')),
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

    if (isEditing) {
      context.read<TradeBloc>().add(UpdateTrade(
            id: widget.tradeId!,
            channelId: _channelId!,
            action: _action,
            symbol: _symbolController.text.toUpperCase(),
            quantity: double.parse(_quantityController.text),
            price: double.parse(_priceController.text),
            smsDate: dateTime,
          ));
    } else {
      context.read<TradeBloc>().add(AddTrade(
            channelId: _channelId!,
            action: _action,
            symbol: _symbolController.text.toUpperCase(),
            quantity: double.parse(_quantityController.text),
            price: double.parse(_priceController.text),
            smsDate: dateTime,
            isManual: true,
          ));
          
      if (widget.isIpo) {
        context.read<FundTransferBloc>().add(AddFundTransfer(
              channelId: _channelId!,
              action: 'ipo_deposit',
              amount: double.parse(_quantityController.text) * double.parse(_priceController.text),
              smsDate: dateTime,
              isManual: true,
            ));
      }
    }
  }
}
