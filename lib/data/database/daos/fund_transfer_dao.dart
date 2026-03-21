import 'package:drift/drift.dart';
import 'package:equity_echo/data/database/database.dart';

part 'fund_transfer_dao.g.dart';

@DriftAccessor(tables: [FundTransfers])
class FundTransferDao extends DatabaseAccessor<AppDatabase>
    with _$FundTransferDaoMixin {
  FundTransferDao(super.db);

  /// Get all fund transfers, newest first
  Future<List<FundTransfer>> getAllFundTransfers() =>
      (select(fundTransfers)
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .get();

  /// Watch all fund transfers (reactive)
  Stream<List<FundTransfer>> watchAllFundTransfers() =>
      (select(fundTransfers)
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .watch();

  /// Get fund transfers for a specific channel
  Future<List<FundTransfer>> getTransfersForChannel(String channelId) =>
      (select(fundTransfers)
            ..where((f) => f.channelId.equals(channelId))
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .get();

  /// Insert a fund transfer
  Future<int> insertFundTransfer(FundTransfersCompanion transfer) =>
      into(fundTransfers).insert(transfer);

  /// Update a fund transfer
  Future<bool> updateFundTransfer(FundTransfer transfer) =>
      update(fundTransfers).replace(transfer);

  /// Delete a fund transfer
  Future<int> deleteFundTransfer(String id) =>
      (delete(fundTransfers)..where((f) => f.id.equals(id))).go();

  /// Delete all fund transfers (for resync)
  Future<int> deleteAllFundTransfers() => delete(fundTransfers).go();

  /// Check for duplicate using SMS body + received date
  Future<bool> existsByRawSms(String rawSmsBody, DateTime smsReceivedDate) async {
    final results = await (select(fundTransfers)
          ..where(
              (f) => f.rawSmsBody.equals(rawSmsBody) & f.smsReceivedDate.equals(smsReceivedDate)))
        .get();
    return results.isNotEmpty;
  }

  /// Get total deposits
  Future<double> getTotalDeposits() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM fund_transfers WHERE action = ?',
      variables: [Variable.withString('deposit')],
      readsFrom: {fundTransfers},
    ).getSingle();
    return result.read<double>('total');
  }

  /// Get total withdrawals
  Future<double> getTotalWithdrawals() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM fund_transfers WHERE action = ?',
      variables: [Variable.withString('withdrawal')],
      readsFrom: {fundTransfers},
    ).getSingle();
    return result.read<double>('total');
  }
}
