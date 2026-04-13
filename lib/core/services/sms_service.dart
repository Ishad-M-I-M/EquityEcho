import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:another_telephony/telephony.dart' as tel;

/// Represents a simplified SMS message
class SmsMessage {
  final String sender;
  final String body;
  final DateTime date;

  const SmsMessage({
    required this.sender,
    required this.body,
    required this.date,
  });

  @override
  String toString() =>
      'SmsMessage(sender: $sender, date: $date, body: ${body.length > 50 ? '${body.substring(0, 50)}...' : body})';
}

/// Callback for incoming SMS
typedef OnSmsReceived = void Function(SmsMessage message);

/// Service for reading and listening to SMS messages.
/// Only functional on Android; no-op on other platforms.
class SmsService {
  final tel.Telephony _telephony = tel.Telephony.instance;

  /// Stream controller for incoming SMS
  final StreamController<SmsMessage> _incomingSmsController =
      StreamController<SmsMessage>.broadcast();

  /// Stream of incoming SMS messages
  Stream<SmsMessage> get incomingSms => _incomingSmsController.stream;

  bool _isListening = false;

  /// Request SMS permissions using the telephony plugin's own API.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[SmsService] Not Android — skipping permission request');
      return false;
    }

    try {
      final granted = await _telephony.requestSmsPermissions ?? false;
      debugPrint('[SmsService] SMS permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[SmsService] Permission request failed: $e');
      return false;
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    // Use the telephony plugin to check; it queries READ_SMS
    try {
      final granted = await _telephony.requestSmsPermissions ?? false;
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// Read ALL SMS from inbox (no sender filter at the query level).
  /// We fetch everything and filter in Dart for more reliable matching.
  /// Returns messages sorted by date (newest first).
  Future<List<SmsMessage>> readInbox({List<String>? senderAddresses}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[SmsService] Not Android — returning empty inbox');
      return [];
    }

    // Request permission if not already granted
    final hasPerms = await requestPermission();
    if (!hasPerms) {
      debugPrint('[SmsService] SMS permission not granted — cannot read inbox');
      return [];
    }

    debugPrint('[SmsService] Reading inbox...');

    try {
      List<tel.SmsMessage> rawMessages;

      if (senderAddresses != null && senderAddresses.isNotEmpty) {
        // Read messages for each sender address
        rawMessages = [];
        for (final sender in senderAddresses) {
          debugPrint('[SmsService] Querying inbox for sender: "$sender"');
          final msgs = await _telephony.getInboxSms(
            columns: [
              tel.SmsColumn.ADDRESS,
              tel.SmsColumn.BODY,
              tel.SmsColumn.DATE,
            ],
            filter: tel.SmsFilter.where(
              tel.SmsColumn.ADDRESS,
            ).like('%$sender%'),
            sortOrder: [tel.OrderBy(tel.SmsColumn.DATE, sort: tel.Sort.DESC)],
          );
          debugPrint(
            '[SmsService] Found ${msgs.length} messages for sender "$sender"',
          );
          rawMessages.addAll(msgs);
        }
      } else {
        debugPrint('[SmsService] Querying entire inbox (no sender filter)');
        rawMessages = await _telephony.getInboxSms(
          columns: [
            tel.SmsColumn.ADDRESS,
            tel.SmsColumn.BODY,
            tel.SmsColumn.DATE,
          ],
          sortOrder: [tel.OrderBy(tel.SmsColumn.DATE, sort: tel.Sort.DESC)],
        );
        debugPrint(
          '[SmsService] Found ${rawMessages.length} total messages in inbox',
        );
      }

      final allMessages = rawMessages.map(_convertMessage).toList();

      // Sort all by date descending
      allMessages.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('[SmsService] Returning ${allMessages.length} messages');
      return allMessages;
    } catch (e) {
      debugPrint('[SmsService] Error reading inbox: $e');
      return [];
    }
  }

  /// Get all distinct SMS sender addresses from the inbox.
  /// Returns a list of unique sender addresses sorted alphabetically.
  Future<List<String>> getDistinctSenders() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[SmsService] Not Android — returning empty senders');
      return [];
    }

    final hasPerms = await requestPermission();
    if (!hasPerms) {
      debugPrint(
        '[SmsService] SMS permission not granted — cannot read senders',
      );
      return [];
    }

    debugPrint('[SmsService] Reading distinct senders...');

    try {
      final rawMessages = await _telephony.getInboxSms(
        columns: [tel.SmsColumn.ADDRESS],
        sortOrder: [tel.OrderBy(tel.SmsColumn.ADDRESS, sort: tel.Sort.ASC)],
      );

      final senders = <String>{};
      for (final msg in rawMessages) {
        final address = msg.address;
        if (address != null && address.isNotEmpty) {
          senders.add(address);
        }
      }

      final sorted = senders.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      debugPrint('[SmsService] Found ${sorted.length} distinct senders');
      return sorted;
    } catch (e) {
      debugPrint('[SmsService] Error reading senders: $e');
      return [];
    }
  }

  /// Start listening for incoming SMS in the foreground.
  void startListening() {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_isListening) return;

    _telephony.listenIncomingSms(
      onNewMessage: (message) {
        final sms = _convertMessage(message);
        debugPrint('[SmsService] New SMS received: ${sms.sender}');
        _incomingSmsController.add(sms);
      },
      listenInBackground: false,
    );

    _isListening = true;
    debugPrint('[SmsService] Real-time SMS listener started');
  }

  /// Stop listening and clean up
  void dispose() {
    _incomingSmsController.close();
    _isListening = false;
  }

  /// Convert telephony SmsMessage to our SmsMessage model
  SmsMessage _convertMessage(tel.SmsMessage message) {
    return SmsMessage(
      sender: message.address ?? '',
      body: message.body ?? '',
      date: message.date != null
          ? DateTime.fromMillisecondsSinceEpoch(message.date!)
          : DateTime.now(),
    );
  }
}
