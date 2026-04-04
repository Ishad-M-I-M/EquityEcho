import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:equity_echo/core/services/sms_service.dart';
import 'package:equity_echo/core/services/template_parser.dart';
import 'package:equity_echo/data/database/database.dart';
import 'package:equity_echo/data/database/daos/channel_dao.dart';
import 'package:equity_echo/data/database/daos/trade_dao.dart';
import 'package:equity_echo/data/database/daos/fund_transfer_dao.dart';
import 'package:equity_echo/core/constants/app_constants.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class SmsSyncEvent extends Equatable {
  const SmsSyncEvent();
  @override
  List<Object?> get props => [];
}

class StartInitialSync extends SmsSyncEvent {}

class CancelInitialSync extends SmsSyncEvent {}

class StartRealtimeListener extends SmsSyncEvent {}

class StopRealtimeListener extends SmsSyncEvent {}

class ProcessIncomingSms extends SmsSyncEvent {
  final SmsMessage sms;
  const ProcessIncomingSms(this.sms);
  @override
  List<Object?> get props => [sms];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class SmsSyncState extends Equatable {
  const SmsSyncState();
  @override
  List<Object?> get props => [];
}

class SmsSyncIdle extends SmsSyncState {}

class SmsSyncInProgress extends SmsSyncState {
  final int processed;
  final int total;
  const SmsSyncInProgress({required this.processed, required this.total});
  @override
  List<Object?> get props => [processed, total];
}

class SmsSyncComplete extends SmsSyncState {
  final int tradesAdded;
  final int fundsAdded;
  final int skipped;
  final bool isCancelled;
  const SmsSyncComplete({
    required this.tradesAdded,
    required this.fundsAdded,
    required this.skipped,
    this.isCancelled = false,
  });
  @override
  List<Object?> get props => [tradesAdded, fundsAdded, skipped, isCancelled];
}

class SmsSyncListening extends SmsSyncState {}

class SmsSyncError extends SmsSyncState {
  final String message;
  const SmsSyncError(this.message);
  @override
  List<Object?> get props => [message];
}

class SmsSyncNewEntry extends SmsSyncState {
  final String description;
  const SmsSyncNewEntry(this.description);
  @override
  List<Object?> get props => [description];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class SmsSyncBloc extends Bloc<SmsSyncEvent, SmsSyncState> {
  final SmsService _smsService;
  final ChannelDao _channelDao;
  final TradeDao _tradeDao;
  final FundTransferDao _fundTransferDao;
  static const _uuid = Uuid();
  StreamSubscription<SmsMessage>? _smsSubscription;
  bool _isSyncCancelled = false;

  SmsSyncBloc({
    required SmsService smsService,
    required ChannelDao channelDao,
    required TradeDao tradeDao,
    required FundTransferDao fundTransferDao,
  })  : _smsService = smsService,
        _channelDao = channelDao,
        _tradeDao = tradeDao,
        _fundTransferDao = fundTransferDao,
        super(SmsSyncIdle()) {
    on<StartInitialSync>(_onInitialSync);
    on<CancelInitialSync>((event, emit) => _isSyncCancelled = true);
    on<StartRealtimeListener>(_onStartRealtime);
    on<StopRealtimeListener>(_onStopRealtime);
    on<ProcessIncomingSms>(_onProcessSms);
  }

  Future<void> _onInitialSync(
    StartInitialSync event,
    Emitter<SmsSyncState> emit,
  ) async {
    _isSyncCancelled = false;
    try {
      debugPrint('[SmsSyncBloc] Starting initial sync...');

      // Step 1: Request permission
      final permitted = await _smsService.requestPermission();
      if (!permitted) {
        debugPrint('[SmsSyncBloc] SMS permission denied');
        emit(const SmsSyncError(
            'SMS permission was denied. Please grant SMS permission in Settings.'));
        return;
      }

      // Step 2: Load channels
      final channels = await _channelDao.getAllChannels();
      debugPrint('[SmsSyncBloc] Found ${channels.length} channels');

      if (channels.isEmpty) {
        emit(const SmsSyncError(
            'No channels configured. Please set up a broker channel first.'));
        return;
      }

      // Step 3: Collect sender addresses
      final senderAddresses = channels.map((c) => c.senderAddress).toList();
      debugPrint('[SmsSyncBloc] Sender addresses: $senderAddresses');

      // Step 4: Read inbox
      final messages =
          await _smsService.readInbox(senderAddresses: senderAddresses);
      debugPrint('[SmsSyncBloc] Read ${messages.length} messages from inbox');

      if (messages.isEmpty) {
        emit(const SmsSyncComplete(tradesAdded: 0, fundsAdded: 0, skipped: 0));
        return;
      }

      int tradesAdded = 0;
      int fundsAdded = 0;
      int skipped = 0;

      for (int i = 0; i < messages.length; i++) {
        if (_isSyncCancelled) {
          debugPrint('[SmsSyncBloc] Sync cancelled by user');
          break;
        }

        if (i % 5 == 0) {
          emit(SmsSyncInProgress(processed: i + 1, total: messages.length));
        }

        final sms = messages[i];
        final result = await _processSmsMessage(sms, channels);
        if (result == _ProcessResult.trade) {
          tradesAdded++;
        } else if (result == _ProcessResult.fund) {
          fundsAdded++;
        } else {
          skipped++;
        }
      }

      debugPrint(
          '[SmsSyncBloc] Sync complete: $tradesAdded trades, $fundsAdded funds, $skipped skipped');

      emit(SmsSyncComplete(
        tradesAdded: tradesAdded,
        fundsAdded: fundsAdded,
        skipped: skipped,
        isCancelled: _isSyncCancelled,
      ));
    } catch (e, stackTrace) {
      debugPrint('[SmsSyncBloc] Sync failed: $e');
      debugPrint('[SmsSyncBloc] Stack: $stackTrace');
      emit(SmsSyncError('Sync failed: $e'));
    }
  }

  Future<void> _onStartRealtime(
    StartRealtimeListener event,
    Emitter<SmsSyncState> emit,
  ) async {
    final permitted = await _smsService.requestPermission();
    if (!permitted) {
      emit(const SmsSyncError('SMS permission denied'));
      return;
    }

    _smsService.startListening();
    _smsSubscription = _smsService.incomingSms.listen((sms) {
      add(ProcessIncomingSms(sms));
    });
    emit(SmsSyncListening());
  }

  Future<void> _onStopRealtime(
    StopRealtimeListener event,
    Emitter<SmsSyncState> emit,
  ) async {
    await _smsSubscription?.cancel();
    _smsSubscription = null;
    emit(SmsSyncIdle());
  }

  Future<void> _onProcessSms(
    ProcessIncomingSms event,
    Emitter<SmsSyncState> emit,
  ) async {
    try {
      final channels = await _channelDao.getAllChannels();
      final result = await _processSmsMessage(event.sms, channels);

      if (result == _ProcessResult.trade) {
        emit(SmsSyncNewEntry('New trade added from SMS'));
      } else if (result == _ProcessResult.fund) {
        emit(SmsSyncNewEntry('New fund transfer added from SMS'));
      }

      // Go back to listening state
      emit(SmsSyncListening());
    } catch (e) {
      emit(SmsSyncError('Failed to process SMS: $e'));
      emit(SmsSyncListening());
    }
  }

  /// Check if sender matches channel address (case-insensitive, contains match)
  bool _senderMatches(String smsSender, String channelAddress) {
    final smsLower = smsSender.toLowerCase().trim();
    final channelLower = channelAddress.toLowerCase().trim();

    // Exact match (case-insensitive)
    if (smsLower == channelLower) return true;

    // Contains match — the SMS sender contains the channel address or vice versa
    if (smsLower.contains(channelLower)) return true;
    if (channelLower.contains(smsLower)) return true;

    return false;
  }

  /// Process a single SMS message against all channels
  Future<_ProcessResult> _processSmsMessage(
    SmsMessage sms,
    List<Channel> channels,
  ) async {
    for (final channel in channels) {
      // Check if sender matches (flexible matching)
      if (!_senderMatches(sms.sender, channel.senderAddress)) {
        debugPrint(
            '[SmsSyncBloc] ✗ Sender "${sms.sender}" does NOT match channel "${channel.name}" (${channel.senderAddress})');
        continue;
      }

      debugPrint('');
      debugPrint('══════════════════════════════════════════════════════');
      debugPrint('[SmsSyncBloc] ✓ Sender "${sms.sender}" matches channel "${channel.name}"');
      debugPrint('[SmsSyncBloc] SMS BODY:');
      debugPrint('--- START SMS ---');
      debugPrint(sms.body);
      debugPrint('--- END SMS ---');
      debugPrint('[SmsSyncBloc] SMS Date: ${sms.date}');
      debugPrint('');

      // Resolve effective buy template
      final effectiveBuyTemplate = channel.useDefaultBuyTemplate
          ? AppConstants.defaultBuyTemplate
          : channel.buyTemplate;

      // Try buy template
      if (effectiveBuyTemplate != null && effectiveBuyTemplate.isNotEmpty) {
        try {
          debugPrint('[SmsSyncBloc] [BUY] Template (${channel.useDefaultBuyTemplate ? "default" : "custom"}): "$effectiveBuyTemplate"');
          final parser = TemplateParser(effectiveBuyTemplate);
          debugPrint('[SmsSyncBloc] [BUY] Generated regex: ${parser.regexPattern}');
          final result = parser.parse(sms.body, smsReceivedDate: sms.date);
          debugPrint('[SmsSyncBloc] [BUY] Matched: ${result.matched}');
          if (result.matched) {
            debugPrint('[SmsSyncBloc] [BUY] Extracted → symbol: ${result.symbol}, qty: ${result.quantity}, price: ${result.price}, date: ${result.dateTime}');
            if (result.symbol != null &&
                result.quantity != null &&
                result.price != null) {
              final exists = await _tradeDao.existsByRawSms(sms.body, sms.date);
              if (!exists) {
                await _tradeDao.insertTrade(TradesCompanion.insert(
                  id: _uuid.v4(),
                  channelId: channel.id,
                  action: 'buy',
                  symbol: result.symbol!,
                  quantity: result.quantity!,
                  price: result.price!,
                  totalValue: result.quantity! * result.price!,
                  smsDate: result.dateTime ?? sms.date,
                  smsReceivedDate: Value(sms.date),
                  rawSmsBody: Value(sms.body),
                  isManual: const Value(false),
                ));
                debugPrint('[SmsSyncBloc] [BUY] ✓ INSERTED trade');
                return _ProcessResult.trade;
              }
              debugPrint('[SmsSyncBloc] [BUY] ⚠ Duplicate — skipping');
              return _ProcessResult.skipped;
            } else {
              debugPrint('[SmsSyncBloc] [BUY] ✗ Regex matched but missing required fields (symbol/qty/price)');
            }
          } else {
            debugPrint('[SmsSyncBloc] [BUY] ✗ Regex did NOT match this SMS body');
          }
        } catch (e) {
          debugPrint('[SmsSyncBloc] [BUY] ✗ Parse error: $e');
        }
      } else {
        debugPrint('[SmsSyncBloc] [BUY] No template configured');
      }

      // Resolve effective sell template
      final effectiveSellTemplate = channel.useDefaultSellTemplate
          ? AppConstants.defaultSellTemplate
          : channel.sellTemplate;

      // Try sell template
      if (effectiveSellTemplate != null && effectiveSellTemplate.isNotEmpty) {
        try {
          debugPrint('[SmsSyncBloc] [SELL] Template (${channel.useDefaultSellTemplate ? "default" : "custom"}): "$effectiveSellTemplate"');
          final parser = TemplateParser(effectiveSellTemplate);
          debugPrint('[SmsSyncBloc] [SELL] Generated regex: ${parser.regexPattern}');
          final result = parser.parse(sms.body, smsReceivedDate: sms.date);
          debugPrint('[SmsSyncBloc] [SELL] Matched: ${result.matched}');
          if (result.matched) {
            debugPrint('[SmsSyncBloc] [SELL] Extracted → symbol: ${result.symbol}, qty: ${result.quantity}, price: ${result.price}, date: ${result.dateTime}');
            if (result.symbol != null &&
                result.quantity != null &&
                result.price != null) {
              final exists = await _tradeDao.existsByRawSms(sms.body, sms.date);
              if (!exists) {
                await _tradeDao.insertTrade(TradesCompanion.insert(
                  id: _uuid.v4(),
                  channelId: channel.id,
                  action: 'sell',
                  symbol: result.symbol!,
                  quantity: result.quantity!,
                  price: result.price!,
                  totalValue: result.quantity! * result.price!,
                  smsDate: result.dateTime ?? sms.date,
                  smsReceivedDate: Value(sms.date),
                  rawSmsBody: Value(sms.body),
                  isManual: const Value(false),
                ));
                debugPrint('[SmsSyncBloc] [SELL] ✓ INSERTED trade');
                return _ProcessResult.trade;
              }
              debugPrint('[SmsSyncBloc] [SELL] ⚠ Duplicate — skipping');
              return _ProcessResult.skipped;
            } else {
              debugPrint('[SmsSyncBloc] [SELL] ✗ Regex matched but missing required fields');
            }
          } else {
            debugPrint('[SmsSyncBloc] [SELL] ✗ Regex did NOT match this SMS body');
          }
        } catch (e) {
          debugPrint('[SmsSyncBloc] [SELL] ✗ Parse error: $e');
        }
      } else {
        debugPrint('[SmsSyncBloc] [SELL] No template configured');
      }

      // Try fund template
      if (channel.fundTemplate != null && channel.fundTemplate!.isNotEmpty) {
        try {
          debugPrint('[SmsSyncBloc] [FUND] Template: "${channel.fundTemplate}"');
          final parser = TemplateParser(channel.fundTemplate!);
          debugPrint('[SmsSyncBloc] [FUND] Generated regex: ${parser.regexPattern}');
          final result = parser.parse(sms.body, smsReceivedDate: sms.date);
          debugPrint('[SmsSyncBloc] [FUND] Matched: ${result.matched}');
          if (result.matched) {
            debugPrint('[SmsSyncBloc] [FUND] Extracted → amount: ${result.amount}, date: ${result.dateTime}');
            if (result.amount != null) {
              final exists =
                  await _fundTransferDao.existsByRawSms(sms.body, sms.date);
              if (!exists) {
                await _fundTransferDao
                    .insertFundTransfer(FundTransfersCompanion.insert(
                  id: _uuid.v4(),
                  channelId: channel.id,
                  action: 'deposit',
                  amount: result.amount!,
                  smsDate: result.dateTime ?? sms.date,
                  smsReceivedDate: Value(sms.date),
                  rawSmsBody: Value(sms.body),
                  isManual: const Value(false),
                ));
                debugPrint('[SmsSyncBloc] [FUND] ✓ INSERTED fund transfer');
                return _ProcessResult.fund;
              }
              debugPrint('[SmsSyncBloc] [FUND] ⚠ Duplicate — skipping');
              return _ProcessResult.skipped;
            } else {
              debugPrint('[SmsSyncBloc] [FUND] ✗ Regex matched but amount is null');
            }
          } else {
            debugPrint('[SmsSyncBloc] [FUND] ✗ Regex did NOT match this SMS body');
          }
        } catch (e) {
          debugPrint('[SmsSyncBloc] [FUND] ✗ Parse error: $e');
        }
      } else {
        debugPrint('[SmsSyncBloc] [FUND] No template configured');
      }

      debugPrint('[SmsSyncBloc] ✗ No template matched for this SMS');
      debugPrint('══════════════════════════════════════════════════════');
    }

    return _ProcessResult.skipped;
  }

  @override
  Future<void> close() {
    _smsSubscription?.cancel();
    return super.close();
  }
}

enum _ProcessResult { trade, fund, skipped }
