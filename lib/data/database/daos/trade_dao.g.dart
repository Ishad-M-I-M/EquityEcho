// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_dao.dart';

// ignore_for_file: type=lint
mixin _$TradeDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChannelsTable get channels => attachedDatabase.channels;
  $TradesTable get trades => attachedDatabase.trades;
  $StockSplitsTable get stockSplits => attachedDatabase.stockSplits;
  TradeDaoManager get managers => TradeDaoManager(this);
}

class TradeDaoManager {
  final _$TradeDaoMixin _db;
  TradeDaoManager(this._db);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$TradesTableTableManager get trades =>
      $$TradesTableTableManager(_db.attachedDatabase, _db.trades);
  $$StockSplitsTableTableManager get stockSplits =>
      $$StockSplitsTableTableManager(_db.attachedDatabase, _db.stockSplits);
}
