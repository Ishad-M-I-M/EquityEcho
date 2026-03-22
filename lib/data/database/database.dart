import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:equity_echo/core/constants/app_constants.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

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

  @override
  Set<Column> get primaryKey => {id};
}

// ──────────────────────────────────────────────────────────────────────────────
// DATABASE
// ──────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Channels, Trades, FundTransfers],
  daos: [ChannelDao, TradeDao, FundTransferDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with an in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

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
