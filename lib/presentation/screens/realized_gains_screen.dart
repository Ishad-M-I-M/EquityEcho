import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/data/models/holding.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:equity_echo/presentation/blocs/dashboard/dashboard_state.dart';

class RealizedGainsScreen extends StatefulWidget {
  const RealizedGainsScreen({super.key});

  @override
  State<RealizedGainsScreen> createState() => _RealizedGainsScreenState();
}

class _RealizedGainsScreenState extends State<RealizedGainsScreen> {
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realized Gains')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final currencyFormatter = NumberFormat.currency(
              symbol: '${state.currency} ',
              decimalDigits: 2,
            );

            // Filter out symbols that don't have any realized gains or losses
            final symbolsWithGains = state.holdings
                .where((h) => h.realizedGain != 0.0)
                .toList()
              ..sort((a, b) => b.realizedGain.compareTo(a.realizedGain));

            if (symbolsWithGains.isEmpty) {
              return Center(
                child: Text(
                  'No realized gains yet.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Bar chart summary ──────────────────────────────────────
                _RealizedGainsBarChart(
                  holdings: symbolsWithGains,
                  currencyFormatter: currencyFormatter,
                  touchedIndex: _touchedBarIndex,
                  onTouch: (i) => setState(() => _touchedBarIndex = i),
                  onTap: (symbol) => context.push('/holding/$symbol'),
                ),
                const SizedBox(height: 20),

                // ── Total summary row ──────────────────────────────────────
                _TotalSummaryRow(
                  holdings: symbolsWithGains,
                  formatter: currencyFormatter,
                ),
                const SizedBox(height: 16),

                // ── Per-symbol list ────────────────────────────────────────
                ...symbolsWithGains.map(
                  (holding) => _GainListTile(
                    holding: holding,
                    formatter: currencyFormatter,
                    onTap: () => context.push('/holding/${holding.symbol}'),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ── Bar chart ────────────────────────────────────────────────────────────────

class _RealizedGainsBarChart extends StatelessWidget {
  final List<Holding> holdings;
  final NumberFormat currencyFormatter;
  final int touchedIndex;
  final void Function(int) onTouch;
  final void Function(String symbol) onTap;

  const _RealizedGainsBarChart({
    required this.holdings,
    required this.currencyFormatter,
    required this.touchedIndex,
    required this.onTouch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxAbs = holdings
        .map((h) => h.realizedGain.abs())
        .reduce((a, b) => a > b ? a : b);

    // Limit x-axis to first 12 symbols (sorted desc) to keep chart readable
    final visible = holdings.length > 12 ? holdings.sublist(0, 12) : holdings;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Gain / Loss by Symbol',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (holdings.length > 12) ...[
                const Spacer(),
                Text(
                  'Top 12 shown',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAbs * 1.25,
                minY: -(maxAbs * 1.25),
                barTouchData: BarTouchData(
                  touchCallback:
                      (FlTouchEvent event, BarTouchResponse? response) {
                    if (response != null &&
                        response.spot != null &&
                        event.isInterestedForInteractions) {
                      onTouch(response.spot!.touchedBarGroupIndex);
                      if (event is FlTapUpEvent) {
                        final idx = response.spot!.touchedBarGroupIndex;
                        if (idx >= 0 && idx < visible.length) {
                          onTap(visible[idx].symbol);
                        }
                      }
                    } else {
                      onTouch(-1);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.85),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = visible[groupIndex];
                      return BarTooltipItem(
                        '${h.symbol}\n',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text: currencyFormatter.format(h.realizedGain),
                            style: TextStyle(
                              color: h.realizedGain >= 0
                                  ? AppTheme.buyGreen
                                  : AppTheme.sellRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= visible.length) {
                          return const SizedBox.shrink();
                        }
                        final sym = visible[i].symbol;
                        return SideTitleWidget(
                          meta: meta,
                          child: Transform.rotate(
                            angle: -1.5708, // -90°
                            child: Text(
                              sym,
                              style: TextStyle(
                                fontSize: 10,
                                color: i == touchedIndex
                                    ? AppTheme.accent
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                fontWeight: i == touchedIndex
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAbs / 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == 0
                        ? Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.8)
                        : Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.3),
                    strokeWidth: value == 0 ? 1.5 : 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(visible.length, (i) {
                  final h = visible[i];
                  final isPos = h.realizedGain >= 0;
                  final isTouched = i == touchedIndex;
                  final barColor =
                      isPos ? AppTheme.buyGreen : AppTheme.sellRed;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: h.realizedGain,
                        color: isTouched
                            ? barColor
                            : barColor.withValues(alpha: 0.75),
                        width: isTouched ? 18 : 14,
                        borderRadius: isPos
                            ? const BorderRadius.vertical(
                                top: Radius.circular(5))
                            : const BorderRadius.vertical(
                                bottom: Radius.circular(5)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxAbs * 1.25,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Total summary row ─────────────────────────────────────────────────────────

class _TotalSummaryRow extends StatelessWidget {
  final List<Holding> holdings;
  final NumberFormat formatter;

  const _TotalSummaryRow({required this.holdings, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final total = holdings.fold(0.0, (s, h) => s + h.realizedGain);
    final wins = holdings.where((h) => h.realizedGain > 0).length;
    final losses = holdings.where((h) => h.realizedGain < 0).length;
    final color = total >= 0 ? AppTheme.buyGreen : AppTheme.sellRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net Realized Gain',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              Text(
                formatter.format(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _PillBadge(
                  label: '$wins 📈', color: AppTheme.buyGreen),
              const SizedBox(width: 8),
              _PillBadge(
                  label: '$losses 📉', color: AppTheme.sellRed),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Per-symbol list tile ──────────────────────────────────────────────────────

class _GainListTile extends StatelessWidget {
  final Holding holding;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const _GainListTile({
    required this.holding,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = holding.realizedGain >= 0;
    final color = isPositive ? AppTheme.accent : AppTheme.sellRed;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  holding.symbol,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              formatter.format(holding.realizedGain),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

