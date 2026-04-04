import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/constants/app_constants.dart';

import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_event.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_state.dart';
import 'package:equity_echo/presentation/widgets/template_test_widget.dart';

class ChannelConfigScreen extends StatefulWidget {
  final String? channelId;

  const ChannelConfigScreen({super.key, this.channelId});

  @override
  State<ChannelConfigScreen> createState() => _ChannelConfigScreenState();
}

class _ChannelConfigScreenState extends State<ChannelConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _senderController = TextEditingController();
  final _buyTemplateController = TextEditingController();
  final _sellTemplateController = TextEditingController();
  final _fundTemplateController = TextEditingController();
  String _currency = 'LKR';
  bool _useDefaultBuyTemplate = true;
  bool _useDefaultSellTemplate = true;
  String? _activeTestTemplate;
  bool _isEditing = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    _buyTemplateController.dispose();
    _sellTemplateController.dispose();
    _fundTemplateController.dispose();
    super.dispose();
  }

  void _loadChannelData() {
    if (widget.channelId == null || _loaded) return;

    final state = context.read<ChannelBloc>().state;
    if (state is ChannelsLoaded) {
      final channel = state.channels.where((c) => c.id == widget.channelId).firstOrNull;
      if (channel != null) {
        _nameController.text = channel.name;
        _senderController.text = channel.senderAddress;
        _buyTemplateController.text = channel.buyTemplate ?? '';
        _sellTemplateController.text = channel.sellTemplate ?? '';
        _fundTemplateController.text = channel.fundTemplate ?? '';
        _currency = channel.currency;
        _useDefaultBuyTemplate = channel.useDefaultBuyTemplate;
        _useDefaultSellTemplate = channel.useDefaultSellTemplate;
        _isEditing = true;
        _loaded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadChannelData();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Channel' : 'New Channel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.sellRed),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: BlocListener<ChannelBloc, ChannelState>(
        listener: (context, state) {
          if (state is ChannelOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop();
          } else if (state is ChannelError) {
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
                // ── Basic Info ──
                _SectionHeader('Channel Info'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Channel Name',
                    hintText: 'e.g., Softlogic Stockbrokers',
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senderController,
                  decoration: const InputDecoration(
                    labelText: 'SMS Sender Address',
                    hintText: 'e.g., Softlogic or +94771234567',
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Sender address is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: ['LKR', 'USD', 'EUR', 'GBP', 'INR', 'AUD']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'LKR'),
                ),

                const SizedBox(height: 28),

                // ── Buy Template ──
                _SectionHeader('Buy Template', color: AppTheme.buyGreen),
                const SizedBox(height: 8),
                _DefaultTemplateToggle(
                  label: 'Use Default Template',
                  value: _useDefaultBuyTemplate,
                  defaultTemplate: AppConstants.defaultBuyTemplate,
                  onChanged: (v) => setState(() => _useDefaultBuyTemplate = v),
                ),
                if (!_useDefaultBuyTemplate) ...[
                  const SizedBox(height: 8),
                  _PlaceholderHints(
                    placeholders: ['{{symbol}}', '{{quantity}}', '{{price}}', '{{date}}', '{{time}}', '{{*}}'],
                  ),
                  const SizedBox(height: 4),
                  const _TemplateInstructions(),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _buyTemplateController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Paste a BUY SMS and replace symbol, qty, price with placeholders',
                      hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TestButton(
                    onPressed: () => setState(
                        () => _activeTestTemplate = _buyTemplateController.text),
                  ),
                  if (_activeTestTemplate == _buyTemplateController.text &&
                      _buyTemplateController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TemplateTestWidget(template: _buyTemplateController.text),
                  ],
                ] else ...[
                  // Show test button for default template too
                  const SizedBox(height: 6),
                  _TestButton(
                    onPressed: () => setState(
                        () => _activeTestTemplate = AppConstants.defaultBuyTemplate),
                  ),
                  if (_activeTestTemplate == AppConstants.defaultBuyTemplate) ...[
                    const SizedBox(height: 10),
                    TemplateTestWidget(template: AppConstants.defaultBuyTemplate),
                  ],
                ],

                const SizedBox(height: 28),

                // ── Sell Template ──
                _SectionHeader('Sell Template', color: AppTheme.sellRed),
                const SizedBox(height: 8),
                _DefaultTemplateToggle(
                  label: 'Use Default Template',
                  value: _useDefaultSellTemplate,
                  defaultTemplate: AppConstants.defaultSellTemplate,
                  onChanged: (v) => setState(() => _useDefaultSellTemplate = v),
                ),
                if (!_useDefaultSellTemplate) ...[
                  const SizedBox(height: 8),
                  _PlaceholderHints(
                    placeholders: ['{{symbol}}', '{{quantity}}', '{{price}}', '{{date}}', '{{time}}', '{{*}}'],
                  ),
                  const SizedBox(height: 4),
                  const _TemplateInstructions(),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sellTemplateController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Paste a SELL SMS and replace symbol, qty, price with placeholders',
                      hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TestButton(
                    onPressed: () => setState(
                        () => _activeTestTemplate = _sellTemplateController.text),
                  ),
                  if (_activeTestTemplate == _sellTemplateController.text &&
                      _sellTemplateController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TemplateTestWidget(template: _sellTemplateController.text),
                  ],
                ] else ...[
                  const SizedBox(height: 6),
                  _TestButton(
                    onPressed: () => setState(
                        () => _activeTestTemplate = AppConstants.defaultSellTemplate),
                  ),
                  if (_activeTestTemplate == AppConstants.defaultSellTemplate) ...[
                    const SizedBox(height: 10),
                    TemplateTestWidget(template: AppConstants.defaultSellTemplate),
                  ],
                ],

                const SizedBox(height: 28),

                // ── Fund Transfer Template ──
                _SectionHeader('Fund Transfer Template',
                    color: AppTheme.fundBlue),
                const SizedBox(height: 4),
                _PlaceholderHints(
                  placeholders: ['{{amount}}', '{{date}}', '{{time}}', '{{*}}'],
                ),
                const SizedBox(height: 4),
                const _TemplateInstructions(isFund: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fundTemplateController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Paste a fund transfer SMS and replace amount with {{amount}}',
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 6),
                _TestButton(
                  onPressed: () => setState(
                      () => _activeTestTemplate = _fundTemplateController.text),
                ),
                if (_activeTestTemplate == _fundTemplateController.text &&
                    _fundTemplateController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  TemplateTestWidget(template: _fundTemplateController.text),
                ],

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(_isEditing ? 'Update Channel' : 'Save Channel'),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final buyTemplate = _buyTemplateController.text.isEmpty
        ? null
        : _buyTemplateController.text;
    final sellTemplate = _sellTemplateController.text.isEmpty
        ? null
        : _sellTemplateController.text;
    final fundTemplate = _fundTemplateController.text.isEmpty
        ? null
        : _fundTemplateController.text;

    if (_isEditing) {
      context.read<ChannelBloc>().add(UpdateChannel(
            id: widget.channelId!,
            name: _nameController.text,
            senderAddress: _senderController.text,
            buyTemplate: buyTemplate,
            sellTemplate: sellTemplate,
            fundTemplate: fundTemplate,
            currency: _currency,
            useDefaultBuyTemplate: _useDefaultBuyTemplate,
            useDefaultSellTemplate: _useDefaultSellTemplate,
          ));
    } else {
      context.read<ChannelBloc>().add(AddChannel(
            name: _nameController.text,
            senderAddress: _senderController.text,
            buyTemplate: buyTemplate,
            sellTemplate: sellTemplate,
            fundTemplate: fundTemplate,
            currency: _currency,
            useDefaultBuyTemplate: _useDefaultBuyTemplate,
            useDefaultSellTemplate: _useDefaultSellTemplate,
          ));
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete Channel?'),
        content: const Text(
            'This will remove the channel configuration. Existing trades and fund transfers will NOT be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ChannelBloc>()
                  .add(DeleteChannel(widget.channelId!));
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader(this.title, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color ?? AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color ?? AppTheme.accent,
          ),
        ),
      ],
    );
  }
}

/// Toggle widget for switching between default and custom templates.
/// Shows the default template as a read-only preview when enabled.
class _DefaultTemplateToggle extends StatelessWidget {
  final String label;
  final bool value;
  final String defaultTemplate;
  final ValueChanged<bool> onChanged;

  const _DefaultTemplateToggle({
    required this.label,
    required this.value,
    required this.defaultTemplate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
        if (value) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Default Template',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  defaultTemplate,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlaceholderHints extends StatelessWidget {
  final List<String> placeholders;
  const _PlaceholderHints({required this.placeholders});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: placeholders
          .map((p) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _TestButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _TestButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.science, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        label: Text(
          'Test Template',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }
}

class _TemplateInstructions extends StatelessWidget {
  final bool isFund;
  const _TemplateInstructions({this.isFund = false});

  @override
  Widget build(BuildContext context) {
    final fields = isFund
        ? '{{amount}}'
        : '{{symbol}}, {{quantity}}, {{price}}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 14, color: AppTheme.warning),
              const SizedBox(width: 6),
              Text(
                'How to set up',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paste a real SMS and replace $fields with placeholders. '
            'Dates and times are auto-detected — no need to replace them.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
