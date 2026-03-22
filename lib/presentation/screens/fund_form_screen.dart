import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_bloc.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_event.dart';
import 'package:equity_echo/presentation/blocs/fund_transfer/fund_transfer_state.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_state.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_bloc.dart';
import 'package:equity_echo/presentation/blocs/activity_log/activity_log_event.dart';
import 'package:intl/intl.dart';

class FundFormScreen extends StatefulWidget {
  final String? initialAction;
  const FundFormScreen({super.key, this.initialAction});

  @override
  State<FundFormScreen> createState() => _FundFormScreenState();
}

class _FundFormScreenState extends State<FundFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _action = 'deposit';
  String? _channelId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      _action = widget.initialAction!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fund Transfer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<FundTransferBloc, FundTransferState>(
        listener: (context, state) {
          if (state is FundTransferOperationSuccess) {
            context.read<DashboardBloc>().add(RefreshDashboard());
            context.read<ActivityLogBloc>().add(RefreshActivityLog());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop();
          } else if (state is FundTransferError) {
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
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _action = 'deposit'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _action == 'deposit'
                                ? AppTheme.fundBlue.withValues(alpha: 0.15)
                                : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _action == 'deposit'
                                  ? AppTheme.fundBlue
                                  : AppTheme.divider,
                              width: _action == 'deposit' ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'DEPOSIT',
                              style: TextStyle(
                                color: _action == 'deposit'
                                    ? AppTheme.fundBlue
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
                        onTap: () => setState(() => _action = 'withdrawal'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _action == 'withdrawal'
                                ? AppTheme.warning.withValues(alpha: 0.15)
                                : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _action == 'withdrawal'
                                  ? AppTheme.warning
                                  : AppTheme.divider,
                              width: _action == 'withdrawal' ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'WITHDRAWAL',
                              style: TextStyle(
                                color: _action == 'withdrawal'
                                    ? AppTheme.warning
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

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Amount is required';
                    if (double.tryParse(v!) == null) return 'Invalid amount';
                    return null;
                  },
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

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _action == 'deposit'
                          ? AppTheme.fundBlue
                          : AppTheme.warning,
                    ),
                    child: const Text('Add Fund Transfer'),
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

    context.read<FundTransferBloc>().add(AddFundTransfer(
          channelId: _channelId!,
          action: _action,
          amount: double.parse(_amountController.text),
          smsDate: dateTime,
          isManual: true,
        ));
  }
}
