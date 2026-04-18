import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:equity_echo/core/services/cloud_sync_service.dart';
import 'package:equity_echo/data/database/database.dart';

class FirestoreCloudSyncService implements CloudSyncService {
  final FirebaseFirestore _firestore;

  FirestoreCloudSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> syncUp(String userId, AppDatabase db, {DateTime? since}) async {
    final userDoc = _firestore.collection('users').doc(userId);

    // Fetch records
    final channels = since != null
        ? await db.channelDao.getModifiedChannelsSince(since)
        : [
            ...await db.channelDao.getAllChannels(),
            ...await db.channelDao.getDeletedChannels(),
          ];

    final trades = since != null
        ? await db.tradeDao.getModifiedTradesSince(since)
        : [
            ...await db.tradeDao.getAllTrades(),
            ...await db.tradeDao.getDeletedTrades(),
          ];

    final funds = since != null
        ? await db.fundTransferDao.getModifiedFundTransfersSince(since)
        : [
            ...await db.fundTransferDao.getAllFundTransfers(),
            ...await db.fundTransferDao.getDeletedFundTransfers(),
          ];

    final splits = since != null
        ? await db.stockSplitDao.getModifiedSplitsSince(since)
        : [
            ...await db.stockSplitDao.getAllStockSplits(),
            ...await db.stockSplitDao.getDeletedSplits(),
          ];

    final dividends = since != null
        ? await db.dividendDao.getModifiedDividendsSince(since)
        : [
            ...await db.dividendDao.getAllDividends(),
            ...await db.dividendDao.getDeletedDividends(),
          ];

    // Prepare batch operations
    WriteBatch batch = _firestore.batch();
    int operationCount = 0;

    Future<void> commitBatchIfFull() async {
      if (operationCount >= 500) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }

    void addToBatch(
      String collectionName,
      String id,
      Map<String, dynamic> data,
    ) {
      final docRef = userDoc.collection(collectionName).doc(id);
      batch.set(docRef, data, SetOptions(merge: true));
      operationCount++;
    }

    // Process Channels
    for (var item in channels) {
      addToBatch('channels', item.id, item.toJson());
      await commitBatchIfFull();
    }

    // Process Trades
    for (var item in trades) {
      addToBatch('trades', item.id, item.toJson());
      await commitBatchIfFull();
    }

    // Process Fund Transfers
    for (var item in funds) {
      addToBatch('fund_transfers', item.id, item.toJson());
      await commitBatchIfFull();
    }

    // Process Stock Splits
    for (var item in splits) {
      addToBatch('stock_splits', item.id, item.toJson());
      await commitBatchIfFull();
    }

    // Process Dividends
    for (var item in dividends) {
      addToBatch('dividends', item.id, item.toJson());
      await commitBatchIfFull();
    }

    // Update user doc with sync timestamp
    batch.set(userDoc, {
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Commit any remaining operations (even if just the userDoc timestamp)
    await batch.commit();
  }

  @override
  Future<void> syncDown(String userId, AppDatabase db) async {
    final userDoc = _firestore.collection('users').doc(userId);

    // For syncDown, we fetch from Firestore and insert/update in local Drift DB.

    // 1. Fetch & sync Channels
    final channelsSnap = await userDoc.collection('channels').get();
    for (var doc in channelsSnap.docs) {
      final channel = Channel.fromJson(doc.data());
      await db
          .into(db.channels)
          .insert(channel, mode: InsertMode.insertOrReplace);
    }

    // 2. Fetch & sync Trades
    final tradesSnap = await userDoc.collection('trades').get();
    for (var doc in tradesSnap.docs) {
      final trade = Trade.fromJson(doc.data());
      await db.into(db.trades).insert(trade, mode: InsertMode.insertOrReplace);
    }

    // 3. Fetch & sync Fund Transfers
    final fundsSnap = await userDoc.collection('fund_transfers').get();
    for (var doc in fundsSnap.docs) {
      final fund = FundTransfer.fromJson(doc.data());
      await db
          .into(db.fundTransfers)
          .insert(fund, mode: InsertMode.insertOrReplace);
    }

    // 4. Fetch & sync Stock Splits
    final splitsSnap = await userDoc.collection('stock_splits').get();
    for (var doc in splitsSnap.docs) {
      final split = StockSplit.fromJson(doc.data());
      await db
          .into(db.stockSplits)
          .insert(split, mode: InsertMode.insertOrReplace);
    }

    // 5. Fetch & sync Dividends
    final divSnap = await userDoc.collection('dividends').get();
    for (var doc in divSnap.docs) {
      final dividend = Dividend.fromJson(doc.data());
      await db
          .into(db.dividends)
          .insert(dividend, mode: InsertMode.insertOrReplace);
    }
  }

  @override
  Future<void> deleteAllCloudData(String userId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    const collections = [
      'channels',
      'trades',
      'fund_transfers',
      'stock_splits',
      'dividends',
    ];

    for (final name in collections) {
      await _deleteCollectionInBatches(userDoc.collection(name));
    }

    // Finally remove the root user document (sync metadata, etc.)
    await userDoc.delete();
  }

  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> ref, {
    int pageSize = 400,
  }) async {
    while (true) {
      final snapshot = await ref.limit(pageSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) return;
    }
  }
}
