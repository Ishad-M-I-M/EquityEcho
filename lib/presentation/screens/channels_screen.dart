import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_echo/core/theme/app_theme.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_bloc.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_event.dart';
import 'package:equity_echo/presentation/blocs/channel/channel_state.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reload channels when entering this screen
    context.read<ChannelBloc>().add(LoadChannels());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broker Channels'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<ChannelBloc, ChannelState>(
        builder: (context, state) {
          if (state is ChannelLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChannelsLoaded) {
            final displayChannels = state.channels
                .where((c) => c.id != 'other')
                .toList();

            if (displayChannels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sms, size: 48, color: AppTheme.accent),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No channels configured',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your broker\'s SMS channel to start tracking',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/channel/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Channel'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayChannels.length,
              itemBuilder: (context, index) {
                final channel = displayChannels[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.business,
                        color: AppTheme.accent,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      channel.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Sender: ${channel.senderAddress}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicators
                        if (channel.useDefaultBuyTemplate ||
                            channel.buyTemplate != null)
                          _PatternBadge('B', AppTheme.buyGreen),
                        if (channel.useDefaultSellTemplate ||
                            channel.sellTemplate != null)
                          _PatternBadge('S', AppTheme.sellRed),
                        if (channel.fundTemplate != null)
                          _PatternBadge('F', AppTheme.fundBlue),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () => context.push('/channel/${channel.id}'),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/channel/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PatternBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PatternBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 3),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
