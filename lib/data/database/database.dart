import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:equity_echo/core/constants/app_constants.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/data/database/daos/stock_split_dao.dart';
import 'package:equity_echo/data/database/daos/dividend_dao.dart';

part 'database.g.dart';

// ──────────────────────────────────────────────────────────────────────────────
// TABLE DEFINITIONS
// ──────────────────────────────────────────────────────────────────────────────

/// SMS Channels — one per broker
class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get senderAddress => text().withLength(min: 1, max: 50)();
  TextColumn get buyTemplate => text().nullable()();
  TextColumn get sellTemplate => text().nullable()();
  TextColumn get fundTemplate => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  BoolColumn get useDefaultBuyTemplate =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get useDefaultSellTemplate =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deleteReason => text().nullable()();
  TextColumn get deleteReasonOther => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock trades (BUY/SELL)
class Trades extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text().references(Channels, #id)();
  TextColumn get action => text()(); // 'buy' or 'sell'
  TextColumn get symbol => text()();
  RealColumn get quantity => real()();
  RealColumn get price => real()();
  RealColumn get totalValue => real()();
  DateTimeColumn get smsDate => dateTime()();
  DateTimeColumn get smsReceivedDate => dateTime().nullable()();
  TextColumn get rawSmsBody => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();

  /// True when this trade was an IPO purchase — charges do NOT apply.
  BoolColumn get isIpo => boolean().withDefault(const Constant(false))();

  /// True when this trade is a holdings adjustment entry.
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();

  /// Specifies the target symbol for a rights conversion.
  TextColumn get targetSymbol => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deleteReason => text().nullable()();
  TextColumn get deleteReasonOther => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Fund transfers (DEPOSIT/WITHDRAWAL)
class FundTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text().references(Channels, #id)();
  TextColumn get action => text()(); // 'deposit' or 'withdrawal'
  RealColumn get amount => real()();
  DateTimeColumn get smsDate => dateTime()();
  DateTimeColumn get smsReceivedDate => dateTime().nullable()();
  TextColumn get rawSmsBody => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deleteReason => text().nullable()();
  TextColumn get deleteReasonOther => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock subdivisions (Stock Splits)
class StockSplits extends Table {
  TextColumn get id => text()();
  TextColumn get symbol => text()();
  DateTimeColumn get splitDate => dateTime()();
  IntColumn get oldShares => integer()();
  IntColumn get newShares => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deleteReason => text().nullable()();
  TextColumn get deleteReasonOther => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dividends received
class Dividends extends Table {
  TextColumn get id => text()();
  TextColumn get symbol => text()();
  RealColumn get amount => real()();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get shares => real().withDefault(const Constant(0.0))();
  RealColumn get dividendPerShare => real().withDefault(const Constant(0.0))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get deleteReason => text().nullable()();
  TextColumn get deleteReasonOther => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ──────────────────────────────────────────────────────────────────────────────
// DATABASE
// ──────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Channels, Trades, FundTransfers, StockSplits, Dividends],
  daos: [ChannelDao, TradeDao, FundTransferDao, StockSplitDao, DividendDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with an in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add smsReceivedDate column to both tables
          await m.addColumn(trades, trades.smsReceivedDate);
          await m.addColumn(fundTransfers, fundTransfers.smsReceivedDate);
        }
        if (from < 3) {
          // Create the new stock splits table
          await m.createTable(stockSplits);
        }
        if (from < 4) {
          // Create the new dividends table
          await m.createTable(dividends);
        }
        if (from < 5) {
          await m.addColumn(dividends, dividends.tax);
        }
        if (from < 6) {
          await m.addColumn(dividends, dividends.shares);
          await m.addColumn(dividends, dividends.dividendPerShare);
        }
        if (from < 7) {
          await m.addColumn(trades, trades.isIpo);
        }
        if (from < 8) {
          await m.addColumn(trades, trades.isAdjustment);
        }
        if (from < 9) {
          await m.addColumn(trades, trades.targetSymbol);
        }
        if (from < 10) {
          await m.addColumn(trades, trades.isDeleted);
          await m.addColumn(trades, trades.deleteReason);
          await m.addColumn(trades, trades.deleteReasonOther);

          await m.addColumn(fundTransfers, fundTransfers.isDeleted);
          await m.addColumn(fundTransfers, fundTransfers.deleteReason);
          await m.addColumn(fundTransfers, fundTransfers.deleteReasonOther);

          await m.addColumn(stockSplits, stockSplits.isDeleted);
          await m.addColumn(stockSplits, stockSplits.deleteReason);
          await m.addColumn(stockSplits, stockSplits.deleteReasonOther);

          await m.addColumn(dividends, dividends.isDeleted);
          await m.addColumn(dividends, dividends.deleteReason);
          await m.addColumn(dividends, dividends.deleteReasonOther);
        }
        if (from < 11) {
          await m.addColumn(channels, channels.useDefaultBuyTemplate);
          await m.addColumn(channels, channels.useDefaultSellTemplate);
        }
        if (from < 12) {
          // If the app crashed midway during a previous migration attempt, these
          // columns may already exist. We catch and ignore the duplication error.
          try {
            await m.addColumn(channels, channels.isDeleted);
          } catch (e) {
            if (!e.toString().contains('duplicate column name')) rethrow;
          }
          try {
            await m.addColumn(channels, channels.deleteReason);
          } catch (e) {
            if (!e.toString().contains('duplicate column name')) rethrow;
          }
          try {
            await m.addColumn(channels, channels.deleteReasonOther);
          } catch (e) {
            if (!e.toString().contains('duplicate column name')) rethrow;
          }

          await m.alterTable(
            TableMigration(trades, newColumns: [trades.updatedAt]),
          );
          await m.alterTable(
            TableMigration(
              fundTransfers,
              newColumns: [fundTransfers.updatedAt],
            ),
          );
          await m.alterTable(
            TableMigration(stockSplits, newColumns: [stockSplits.updatedAt]),
          );
          await m.alterTable(
            TableMigration(dividends, newColumns: [dividends.updatedAt]),
          );
        }
      },
      beforeOpen: (details) async {
        await into(channels).insert(
          ChannelsCompanion.insert(
            id: 'other',
            name: 'Other',
            senderAddress: 'N/A',
            currency: const Value('LKR'),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
