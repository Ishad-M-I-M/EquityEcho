import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels])
class ChannelDao extends DatabaseAccessor<AppDatabase>
    with _$ChannelDaoMixin {
  ChannelDao(super.db);

  /// Get all channels
  Future<List<Channel>> getAllChannels() => select(channels).get();

  /// Watch all channels (reactive stream)
  Stream<List<Channel>> watchAllChannels() => select(channels).watch();

  /// Get a channel by ID
  Future<Channel?> getChannelById(String id) =>
      (select(channels)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Get a channel by sender address
  Future<Channel?> getChannelBySender(String senderAddress) =>
      (select(channels)..where((c) => c.senderAddress.equals(senderAddress)))
          .getSingleOrNull();

  /// Insert a new channel
  Future<int> insertChannel(ChannelsCompanion channel) =>
      into(channels).insert(channel);

  /// Update a channel
  Future<bool> updateChannel(ChannelsCompanion channel) =>
      update(channels).replace(Channel(
        id: channel.id.value,
        name: channel.name.value,
        senderAddress: channel.senderAddress.value,
        buyTemplate: channel.buyTemplate.value,
        sellTemplate: channel.sellTemplate.value,
        fundTemplate: channel.fundTemplate.value,
        currency: channel.currency.value,
        createdAt: channel.createdAt.value,
        updatedAt: DateTime.now(),
      ));

  /// Delete a channel
  Future<int> deleteChannel(String id) =>
      (delete(channels)..where((c) => c.id.equals(id))).go();
}
