import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/core/di/injection.dart';
import 'package:equity_echo/core/utils/return_calculator.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/models/holding.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';

/// "What-If" return calculator.
///
/// Estimates the gain (and annualized return) of a hypothetical buy → sell,
/// either for an existing holding (using its average cost & first purchase
/// date) or for a brand-new / intended purchase entered manually.
class WhatIfScreen extends StatefulWidget {
  /// When provided, opens in "existing holding" mode pre-selected to this
  /// symbol (used when launched from a holding's detail screen).
  final String? initialSymbol;

  const WhatIfScreen({super.key, this.initialSymbol});

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  static const _existing = 'existing';
  static const _newBuy = 'new';

  String _mode = _existing;

  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _symbolController = TextEditingController();

  String? _selectedSymbol;
  DateTime? _buyDate;
  DateTime _sellDate = DateTime.now();
  bool _buyIncludesCharges = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSymbol != null) {
      _mode = _existing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectHolding(widget.initialSymbol!);
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Holding? _findHolding(List<Holding> holdings, String? symbol) {
    if (symbol == null) return null;
    for (final h in holdings) {
      if (h.symbol == symbol) return h;
    }
    return null;
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toString();

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      if (mode == _newBuy) {
        _buyDate ??= DateTime.now();
      } else if (_selectedSymbol != null) {
        _loadBuyDate(_selectedSymbol!);
      } else {
        _buyDate = null;
      }
    });
  }

  void _selectHolding(String symbol) {
    final state = context.read<DashboardBloc>().state;
    Holding? holding;
    if (state is DashboardLoaded) {
      holding = _findHolding(state.holdings, symbol);
    }
    setState(() {
      _selectedSymbol = symbol;
      _buyDate = null;
      if (holding != null && holding.netQuantity > 0) {
        _quantityController.text = _formatQty(holding.netQuantity);
      }
    });
    _loadBuyDate(symbol);
  }

  /// Loads the earliest acquisition date for [symbol] to anchor the annualized
  /// return. Falls back to the earliest trade, then today.
  Future<void> _loadBuyDate(String symbol) async {
    final trades = await getIt<TradeDao>().getTradesForSymbol(symbol);
    if (!mounted || _selectedSymbol != symbol) return;
    final buys = trades.where((t) => t.action == 'buy').toList();
    final relevant = buys.isNotEmpty ? buys : trades;
    DateTime? earliest;
    for (final t in relevant) {
      if (earliest == null || t.smsDate.isBefore(earliest)) {
        earliest = t.smsDate;
      }
    }
    setState(() => _buyDate = earliest ?? DateTime.now());
  }

  WhatIfResult? _computeResult(List<Holding> activeHoldings) {
    final qty = double.tryParse(_quantityController.text);
    final sellPrice = double.tryParse(_sellPriceController.text);
    if (qty == null || qty <= 0 || sellPrice == null || sellPrice < 0) {
      return null;
    }

    if (_mode == _existing) {
      final holding = _findHolding(activeHoldings, _selectedSymbol);
      if (holding == null || _buyDate == null) return null;
      return ReturnCalculator.compute(
        quantity: qty,
        buyPrice: holding.avgCostWithCharges,
        sellPrice: sellPrice,
        buyDate: _buyDate!,
        sellDate: _sellDate,
        buyPriceIncludesCharges: true,
      );
    }

    final buyPrice = double.tryParse(_buyPriceController.text);
    if (buyPrice == null || buyPrice <= 0 || _buyDate == null) return null;
    return ReturnCalculator.compute(
      quantity: qty,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      buyDate: _buyDate!,
      sellDate: _sellDate,
      buyPriceIncludesCharges: _buyIncludesCharges,
    );
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What-If Calculator')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is! DashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final currency = state.currency;
          final activeHoldings =
              state.holdings.where((h) => h.netQuantity > 0).toList()
                ..sort((a, b) => a.symbol.compareTo(b.symbol));
          final result = _computeResult(activeHoldings);
          final currencyFmt = NumberFormat.currency(
            symbol: '$currency ',
            decimalDigits: 2,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ModeToggle(mode: _mode, onChanged: _setMode),
              const SizedBox(height: 20),
              if (_mode == _existing)
                _buildExistingInputs(activeHoldings, currencyFmt)
              else
                _buildNewInputs(),
              const SizedBox(height: 16),
              _buildSellInputs(),
              const SizedBox(height: 24),
              if (result != null)
                _ResultCard(
                  result: result,
                  currencyFmt: currencyFmt,
                  buyChargesIncluded: _mode == _existing,
                )
              else
                _buildPlaceholder(context),
            ],
          );
        },
      ),
    );
  }

  // ─── Input sections (filled in below) ──────────────────────────────────────

  Widget _buildExistingInputs(
    List<Holding> activeHoldings,
    NumberFormat currencyFmt,
  ) {
    if (activeHoldings.isEmpty) {
      return _InfoBanner(
        icon: Icons.info_outline,
        color: AppTheme.warning,
        message:
            'No active holdings to sell. Switch to "New Purchase" to model a '
            'stock you intend to buy.',
      );
    }

    final holding = _findHolding(activeHoldings, _selectedSymbol);
    final dropdownValue = holding != null ? _selectedSymbol : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Select Holding'),
          hint: const Text('Choose a stock you hold'),
          items: activeHoldings
              .map(
                (h) => DropdownMenuItem(
                  value: h.symbol,
                  child: Text(
                    '${h.symbol}  ·  ${_formatQty(h.netQuantity)} shares',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) _selectHolding(v);
          },
        ),
        if (holding != null) ...[
          const SizedBox(height: 12),
          _HoldingInfoCard(
            holding: holding,
            buyDate: _buyDate,
            currencyFmt: currencyFmt,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity to sell',
              helperText: 'Max ${_formatQty(holding.netQuantity)} shares held',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildNewInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _symbolController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Symbol (optional)',
            hintText: 'e.g., MGT.N0000',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _buyPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Buy Price'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateField(
          label: 'Buy Date',
          date: _buyDate ?? DateTime.now(),
          onTap: () => _pickDate(
            initial: _buyDate ?? DateTime.now(),
            onPicked: (d) => setState(() => _buyDate = d),
          ),
        ),
        SwitchListTile(
          title: const Text('Buy price includes charges'),
          subtitle: Text(
            _buyIncludesCharges
                ? 'Treating the buy price as the all-in cost per share.'
                : 'Standard CSE buy charges (1.12%) will be added.',
            style: const TextStyle(fontSize: 11),
          ),
          value: _buyIncludesCharges,
          onChanged: (v) => setState(() => _buyIncludesCharges = v),
          activeThumbColor: AppTheme.accent,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildSellInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sellPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Sell Price',
                  hintText: 'per share',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'Sell Date',
                date: _sellDate,
                onTap: () => _pickDate(
                  initial: _sellDate,
                  onPicked: (d) => setState(() => _sellDate = d),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            _mode == _existing
                ? 'Select a holding and enter a sell price to see the return.'
                : 'Enter quantity, buy price and sell price to see the return.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatting helpers ───────────────────────────────────────────────────────

String _formatSignedPct(double pct) {
  final sign = pct >= 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(2)}%';
}

String _formatHoldingPeriod(int days) {
  if (days <= 0) return 'Same day';
  final years = days ~/ 365;
  final remDays = days % 365;
  final months = remDays ~/ 30;
  final d = remDays % 30;
  final parts = <String>[];
  if (years > 0) parts.add('${years}y');
  if (months > 0) parts.add('${months}m');
  if (d > 0 && years == 0) parts.add('${d}d');
  final approx = parts.join(' ');
  return '$days days${approx.isNotEmpty ? ' ($approx)' : ''}';
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Existing Holding',
            icon: Icons.inventory_2_outlined,
            selected: mode == _WhatIfScreenState._existing,
            onTap: () => onChanged(_WhatIfScreenState._existing),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleChip(
            label: 'New Purchase',
            icon: Icons.add_shopping_cart_outlined,
            selected: mode == _WhatIfScreenState._newBuy,
            onTap: () => onChanged(_WhatIfScreenState._newBuy),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppTheme.accent
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppTheme.accent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(date)),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _HoldingInfoCard extends StatelessWidget {
  final Holding holding;
  final DateTime? buyDate;
  final NumberFormat currencyFmt;

  const _HoldingInfoCard({
    required this.holding,
    required this.buyDate,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _InfoRow('Shares held', holding.netQuantity.toStringAsFixed(0)),
          const SizedBox(height: 6),
          _InfoRow(
            'Avg cost (incl. charges)',
            currencyFmt.format(holding.avgCostWithCharges),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            'First purchased',
            buyDate == null
                ? 'Loading…'
                : DateFormat('dd MMM yyyy').format(buyDate!),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final WhatIfResult result;
  final NumberFormat currencyFmt;

  /// True when buy-side charges were already included (existing holding).
  final bool buyChargesIncluded;

  const _ResultCard({
    required this.result,
    required this.currencyFmt,
    required this.buyChargesIncluded,
  });

  @override
  Widget build(BuildContext context) {
    final color = result.isProfit ? AppTheme.buyGreen : AppTheme.sellRed;
    final ann = result.annualizedPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero — net gain/loss + return headline metrics
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    result.isProfit ? Icons.trending_up : Icons.trending_down,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.isProfit
                        ? 'Estimated Net Gain'
                        : 'Estimated Net Loss',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currencyFmt.format(result.netGain),
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'Total Return',
                      value: _formatSignedPct(result.returnPct),
                      color: color,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: color.withValues(alpha: 0.25),
                  ),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Annualized',
                      value: ann == null
                          ? '—'
                          : '${_formatSignedPct(ann)} p.a.',
                      color: ann == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detailed figures
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _StatLine(
                'Amount Invested',
                currencyFmt.format(result.totalBuyCost),
                subtitle: 'incl. buy charges',
              ),
              _divider(context),
              _StatLine(
                'Sale Proceeds',
                currencyFmt.format(result.netProceeds),
                subtitle: 'net of sell charges',
              ),
              _divider(context),
              _StatLine(
                'Buy Charges',
                buyChargesIncluded
                    ? 'Already paid'
                    : currencyFmt.format(result.buyCharges),
                color: AppTheme.warning,
              ),
              _divider(context),
              _StatLine(
                'Sell Charges',
                currencyFmt.format(result.sellCharges),
                color: AppTheme.warning,
                subtitle: result.intraDayExempt
                    ? 'intra-day exempt · STL only'
                    : null,
              ),
              _divider(context),
              _StatLine(
                'Holding Period',
                _formatHoldingPeriod(result.holdingDays),
              ),
              _divider(context),
              _StatLine(
                'Annualized Return',
                result.annualizedPct == null
                    ? '—'
                    : '${_formatSignedPct(result.annualizedPct!)} p.a.',
                color: result.annualizedPct == null
                    ? null
                    : (result.isProfit ? AppTheme.buyGreen : AppTheme.sellRed),
                subtitle: 'CAGR',
              ),
            ],
          ),
        ),
        if (result.intraDayExempt) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            icon: Icons.bolt,
            color: AppTheme.accent,
            message:
                'Intra-day trade (same-day buy & sell): the sell leg is exempt '
                'from Brokerage/CSE/CDS/SEC — only the 0.300% Share Transaction '
                'Levy applies.',
          ),
        ],
        if (result.annualizedPct == null) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            icon: Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            message:
                'Annualized return needs a holding period of at least one day '
                '(with a sell date after the buy date).',
          ),
        ],
      ],
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(height: 22, color: Theme.of(context).dividerColor);
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? subtitle;

  const _StatLine(this.label, this.value, {this.color, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
