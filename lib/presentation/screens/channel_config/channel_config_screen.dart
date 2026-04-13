import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/constants/app_constants.dart';

import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_event.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_state.dart';
import 'package:equity_echo/presentation/widgets/template_test_widget.dart';

import 'dialogs/sms_sender_picker_sheet.dart';
import 'widgets/channel_section_header.dart';
import 'widgets/default_template_toggle.dart';
import 'widgets/placeholder_hints.dart';
import 'widgets/template_instructions.dart';
import 'widgets/template_test_button.dart';

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

  // ── Data loading ───────────────────────────────────────────────────────────

  void _loadChannelData() {
    if (widget.channelId == null || _loaded) return;

    final state = context.read<ChannelBloc>().state;
    if (state is ChannelsLoaded) {
      final channel = state.channels
          .where((c) => c.id == widget.channelId)
          .firstOrNull;
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

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showSenderPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SmsSenderPickerSheet(
        onSelected: (sender) {
          setState(() => _senderController.text = sender);
          Navigator.pop(context);
        },
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
      context.read<ChannelBloc>().add(
        UpdateChannel(
          id: widget.channelId!,
          name: _nameController.text,
          senderAddress: _senderController.text,
          buyTemplate: buyTemplate,
          sellTemplate: sellTemplate,
          fundTemplate: fundTemplate,
          currency: _currency,
          useDefaultBuyTemplate: _useDefaultBuyTemplate,
          useDefaultSellTemplate: _useDefaultSellTemplate,
        ),
      );
    } else {
      context.read<ChannelBloc>().add(
        AddChannel(
          name: _nameController.text,
          senderAddress: _senderController.text,
          buyTemplate: buyTemplate,
          sellTemplate: sellTemplate,
          fundTemplate: fundTemplate,
          currency: _currency,
          useDefaultBuyTemplate: _useDefaultBuyTemplate,
          useDefaultSellTemplate: _useDefaultSellTemplate,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete Channel?'),
        content: const Text(
          'This will remove the channel configuration. '
          'Existing trades and fund transfers will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChannelBloc>().add(DeleteChannel(widget.channelId!));
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.sellRed)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.pop();
          } else if (state is ChannelError) {
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
                _buildChannelInfoSection(),
                const SizedBox(height: 28),
                _buildBuyTemplateSection(),
                const SizedBox(height: 28),
                _buildSellTemplateSection(),
                const SizedBox(height: 28),
                _buildFundTemplateSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildChannelInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChannelSectionHeader('Channel Info'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Channel Name',
            hintText: 'e.g., Softlogic Stockbrokers',
          ),
          validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _senderController,
          decoration: InputDecoration(
            labelText: 'SMS Sender Address',
            hintText: 'e.g., Softlogic or +94771234567',
            suffixIcon: IconButton(
              icon: Icon(Icons.search, color: AppTheme.accent),
              tooltip: 'Browse SMS senders',
              onPressed: () => _showSenderPicker(context),
            ),
          ),
          validator: (v) =>
              v?.isEmpty == true ? 'Sender address is required' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _currency,
          decoration: const InputDecoration(labelText: 'Currency'),
          items: [
            'LKR',
            'USD',
            'EUR',
            'GBP',
            'INR',
            'AUD',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _currency = v ?? 'LKR'),
        ),
      ],
    );
  }

  Widget _buildBuyTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelSectionHeader('Buy Template', color: AppTheme.buyGreen),
        const SizedBox(height: 8),
        DefaultTemplateToggle(
          label: 'Use Default Template',
          value: _useDefaultBuyTemplate,
          defaultTemplate: AppConstants.defaultBuyTemplate,
          onChanged: (v) => setState(() => _useDefaultBuyTemplate = v),
        ),
        if (!_useDefaultBuyTemplate) ...[
          const SizedBox(height: 8),
          const PlaceholderHints(
            placeholders: [
              '{{symbol}}',
              '{{quantity}}',
              '{{price}}',
              '{{date}}',
              '{{time}}',
              '{{*}}',
            ],
          ),
          const SizedBox(height: 4),
          const TemplateInstructions(),
          const SizedBox(height: 8),
          TextFormField(
            controller: _buyTemplateController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Paste a BUY SMS and replace symbol, qty, price with placeholders',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TemplateTestButton(
            onPressed: () => setState(
              () => _activeTestTemplate = _buyTemplateController.text,
            ),
          ),
          if (_activeTestTemplate == _buyTemplateController.text &&
              _buyTemplateController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            TemplateTestWidget(template: _buyTemplateController.text),
          ],
        ] else ...[
          const SizedBox(height: 6),
          TemplateTestButton(
            onPressed: () => setState(
              () => _activeTestTemplate = AppConstants.defaultBuyTemplate,
            ),
          ),
          if (_activeTestTemplate == AppConstants.defaultBuyTemplate) ...[
            const SizedBox(height: 10),
            TemplateTestWidget(template: AppConstants.defaultBuyTemplate),
          ],
        ],
      ],
    );
  }

  Widget _buildSellTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelSectionHeader('Sell Template', color: AppTheme.sellRed),
        const SizedBox(height: 8),
        DefaultTemplateToggle(
          label: 'Use Default Template',
          value: _useDefaultSellTemplate,
          defaultTemplate: AppConstants.defaultSellTemplate,
          onChanged: (v) => setState(() => _useDefaultSellTemplate = v),
        ),
        if (!_useDefaultSellTemplate) ...[
          const SizedBox(height: 8),
          const PlaceholderHints(
            placeholders: [
              '{{symbol}}',
              '{{quantity}}',
              '{{price}}',
              '{{date}}',
              '{{time}}',
              '{{*}}',
            ],
          ),
          const SizedBox(height: 4),
          const TemplateInstructions(),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sellTemplateController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Paste a SELL SMS and replace symbol, qty, price with placeholders',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TemplateTestButton(
            onPressed: () => setState(
              () => _activeTestTemplate = _sellTemplateController.text,
            ),
          ),
          if (_activeTestTemplate == _sellTemplateController.text &&
              _sellTemplateController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            TemplateTestWidget(template: _sellTemplateController.text),
          ],
        ] else ...[
          const SizedBox(height: 6),
          TemplateTestButton(
            onPressed: () => setState(
              () => _activeTestTemplate = AppConstants.defaultSellTemplate,
            ),
          ),
          if (_activeTestTemplate == AppConstants.defaultSellTemplate) ...[
            const SizedBox(height: 10),
            TemplateTestWidget(template: AppConstants.defaultSellTemplate),
          ],
        ],
      ],
    );
  }

  Widget _buildFundTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelSectionHeader(
          'Fund Transfer Template',
          color: AppTheme.fundBlue,
        ),
        const SizedBox(height: 4),
        const PlaceholderHints(
          placeholders: ['{{amount}}', '{{date}}', '{{time}}', '{{*}}'],
        ),
        const SizedBox(height: 4),
        const TemplateInstructions(isFund: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fundTemplateController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Paste a fund transfer SMS and replace amount with {{amount}}',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TemplateTestButton(
          onPressed: () => setState(
            () => _activeTestTemplate = _fundTemplateController.text,
          ),
        ),
        if (_activeTestTemplate == _fundTemplateController.text &&
            _fundTemplateController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          TemplateTestWidget(template: _fundTemplateController.text),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _save,
        child: Text(_isEditing ? 'Update Channel' : 'Save Channel'),
      ),
    );
  }
}
