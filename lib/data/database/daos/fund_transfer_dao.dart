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
            ..where((f) => f.isDeleted.equals(false))
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .get();

  /// Watch all fund transfers (reactive)
  Stream<List<FundTransfer>> watchAllFundTransfers() =>
      (select(fundTransfers)
            ..where((f) => f.isDeleted.equals(false))
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .watch();

  /// Get fund transfers for a specific channel
  Future<List<FundTransfer>> getTransfersForChannel(String channelId) =>
      (select(fundTransfers)
            ..where(
              (f) => f.isDeleted.equals(false) & f.channelId.equals(channelId),
            )
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .get();

  /// Insert a fund transfer
  Future<int> insertFundTransfer(FundTransfersCompanion transfer) =>
      into(fundTransfers).insert(transfer);

  /// Update a fund transfer
  Future<bool> updateFundTransfer(FundTransfer transfer) =>
      update(fundTransfers).replace(transfer);

  Future<int> deleteFundTransfer(
    String id, {
    String? reason,
    String? reasonOther,
  }) async {
    return (update(fundTransfers)..where((f) => f.id.equals(id))).write(
      FundTransfersCompanion(
        isDeleted: const Value(true),
        deleteReason: Value(reason),
        deleteReasonOther: Value(reasonOther),
      ),
    );
  }

  /// Restore a fund transfer
  Future<int> restoreFundTransfer(String id) async {
    return (update(fundTransfers)..where((f) => f.id.equals(id))).write(
      const FundTransfersCompanion(
        isDeleted: Value(false),
        deleteReason: Value(null),
        deleteReasonOther: Value(null),
      ),
    );
  }

  /// Get deleted fund transfers
  Future<List<FundTransfer>> getDeletedFundTransfers() =>
      (select(fundTransfers)
            ..where((f) => f.isDeleted.equals(true))
            ..orderBy([(f) => OrderingTerm.desc(f.smsDate)]))
          .get();

  /// Delete all fund transfers (for resync)
  Future<int> deleteAllFundTransfers() => delete(fundTransfers).go();

  /// Check for duplicate using SMS body + received date
  Future<bool> existsByRawSms(
    String rawSmsBody,
    DateTime smsReceivedDate,
  ) async {
    final results =
        await (select(fundTransfers)..where(
              (f) =>
                  f.rawSmsBody.equals(rawSmsBody) &
                  f.smsReceivedDate.equals(smsReceivedDate),
            ))
            .get();
    return results.isNotEmpty;
  }

  /// Get total deposits
  Future<double> getTotalDeposits() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM fund_transfers WHERE action IN (?, ?) AND is_deleted = 0',
      variables: [
        Variable.withString('deposit'),
        Variable.withString('ipo_deposit'),
      ],
      readsFrom: {fundTransfers},
    ).getSingle();
    return result.read<double>('total');
  }

  /// Get total withdrawals
  Future<double> getTotalWithdrawals() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM fund_transfers WHERE action = ? AND is_deleted = 0',
      variables: [Variable.withString('withdrawal')],
      readsFrom: {fundTransfers},
    ).getSingle();
    return result.read<double>('total');
  }
}
