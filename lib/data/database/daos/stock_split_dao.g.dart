// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_split_dao.dart';

// ignore_for_file: type=lint
mixin _$StockSplitDaoMixin on DatabaseAccessor<AppDatabase> {
  $StockSplitsTable get stockSplits => attachedDatabase.stockSplits;
  StockSplitDaoManager get managers => StockSplitDaoManager(this);
}

class StockSplitDaoManager {
  final _$StockSplitDaoMixin _db;
  StockSplitDaoManager(this._db);
  $$StockSplitsTableTableManager get stockSplits =>
      $$StockSplitsTableTableManager(_db.attachedDatabase, _db.stockSplits);
}
