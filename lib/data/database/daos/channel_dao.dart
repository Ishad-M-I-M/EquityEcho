import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'channel_dao.g.dart';

@DriftAccessor(tables: [Channels])
class ChannelDao extends DatabaseAccessor<AppDatabase> with _$ChannelDaoMixin {
  ChannelDao(super.db);

  /// Get all channels
  Future<List<Channel>> getAllChannels() =>
      (select(channels)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([
              (c) => OrderingTerm(expression: c.id.equals('other')),
              (c) => OrderingTerm(expression: c.name),
            ]))
          .get();

  /// Watch all channels (reactive stream)
  Stream<List<Channel>> watchAllChannels() =>
      (select(channels)
            ..where((c) => c.isDeleted.equals(false))
            ..orderBy([
              (c) => OrderingTerm(expression: c.id.equals('other')),
              (c) => OrderingTerm(expression: c.name),
            ]))
          .watch();

  /// Get a channel by ID
  Future<Channel?> getChannelById(String id) =>
      (select(channels)
            ..where((c) => c.id.equals(id) & c.isDeleted.equals(false)))
          .getSingleOrNull();

  /// Get a channel by sender address
  Future<Channel?> getChannelBySender(String senderAddress) =>
      (select(channels)..where(
            (c) =>
                c.senderAddress.equals(senderAddress) &
                c.isDeleted.equals(false),
          ))
          .getSingleOrNull();

  /// Insert a new channel
  Future<int> insertChannel(ChannelsCompanion channel) =>
      into(channels).insert(channel);

  /// Update a channel
  Future<bool> updateChannel(ChannelsCompanion channel) => update(
    channels,
  ).replace(channel.copyWith(updatedAt: Value(DateTime.now())));

  /// Delete a channel
  /// Delete a channel
  Future<int> deleteChannel(String id, {String? reason, String? reasonOther}) =>
      (update(channels)..where((c) => c.id.equals(id))).write(
        ChannelsCompanion(
          isDeleted: const Value(true),
          deleteReason: Value(reason),
          deleteReasonOther: Value(reasonOther),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Get deleted channels
  Future<List<Channel>> getDeletedChannels() =>
      (select(channels)..where((c) => c.isDeleted.equals(true))).get();

  /// Get modified channels since
  Future<List<Channel>> getModifiedChannelsSince(DateTime since) => (select(
    channels,
  )..where((c) => c.updatedAt.isBiggerThanValue(since))).get();
}
