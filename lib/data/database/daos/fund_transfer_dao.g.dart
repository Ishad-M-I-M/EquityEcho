// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_transfer_dao.dart';

// ignore_for_file: type=lint
mixin _$FundTransferDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChannelsTable get channels => attachedDatabase.channels;
  $FundTransfersTable get fundTransfers => attachedDatabase.fundTransfers;
  FundTransferDaoManager get managers => FundTransferDaoManager(this);
}

class FundTransferDaoManager {
  final _$FundTransferDaoMixin _db;
  FundTransferDaoManager(this._db);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db.attachedDatabase, _db.channels);
  $$FundTransfersTableTableManager get fundTransfers =>
      $$FundTransfersTableTableManager(_db.attachedDatabase, _db.fundTransfers);
}
