import 'package:flutter/material.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/services/template_parser.dart';

/// Widget to test a template against a sample SMS
class TemplateTestWidget extends StatefulWidget {
  final String? template;
  final Function(String template)? onTemplateChanged;

  const TemplateTestWidget({super.key, this.template, this.onTemplateChanged});

  @override
  State<TemplateTestWidget> createState() => _TemplateTestWidgetState();
}

class _TemplateTestWidgetState extends State<TemplateTestWidget> {
  final _sampleController = TextEditingController();
  ParseResult? _result;
  String? _error;
  String? _regexPattern;

  @override
  void dispose() {
    _sampleController.dispose();
    super.dispose();
  }

  void _testTemplate() {
    if (widget.template == null || widget.template!.isEmpty) {
      setState(() {
        _error = 'No template configured';
        _result = null;
        _regexPattern = null;
      });
      return;
    }

    try {
      final parser = TemplateParser(widget.template!);
      final result = parser.parse(
        _sampleController.text,
        smsReceivedDate: DateTime.now(),
      );
      setState(() {
        _result = result;
        _regexPattern = parser.regexPattern;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _result = null;
        _regexPattern = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Template',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sampleController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Paste a sample SMS message here...',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _testTemplate,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Test'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sellRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.sellRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppTheme.sellRed, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _result!.matched
                  ? AppTheme.buyGreen.withValues(alpha: 0.08)
                  : AppTheme.sellRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _result!.matched
                    ? AppTheme.buyGreen.withValues(alpha: 0.3)
                    : AppTheme.sellRed.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _result!.matched ? Icons.check_circle : Icons.cancel,
                      color: _result!.matched
                          ? AppTheme.buyGreen
                          : AppTheme.sellRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _result!.matched ? 'MATCHED' : 'NO MATCH',
                      style: TextStyle(
                        color: _result!.matched
                            ? AppTheme.buyGreen
                            : AppTheme.sellRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_result!.matched) ...[
                  const SizedBox(height: 10),
                  _ExtractedField('Symbol', _result!.symbol),
                  _ExtractedField('Quantity', _result!.quantity?.toString()),
                  _ExtractedField('Price', _result!.price?.toString()),
                  _ExtractedField('Amount', _result!.amount?.toString()),
                  _ExtractedField('Date/Time', _result!.dateTime?.toString()),
                ],
              ],
            ),
          ),
        ],
        if (_regexPattern != null) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Generated Regex',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _regexPattern!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ExtractedField extends StatelessWidget {
  final String label;
  final String? value;

  const _ExtractedField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
