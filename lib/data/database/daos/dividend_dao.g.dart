// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dividend_dao.dart';

// ignore_for_file: type=lint
mixin _$DividendDaoMixin on DatabaseAccessor<AppDatabase> {
  $DividendsTable get dividends => attachedDatabase.dividends;
  DividendDaoManager get managers => DividendDaoManager(this);
}

class DividendDaoManager {
  final _$DividendDaoMixin _db;
  DividendDaoManager(this._db);
  $$DividendsTableTableManager get dividends =>
      $$DividendsTableTableManager(_db.attachedDatabase, _db.dividends);
}
