import 'dart:async';
import '../../core/utils/app_logger.dart';
import '../hive/hive_service.dart';
import '../models/sms_record.dart';
import 'parsers/bkash_parser.dart';
import 'parsers/nagad_parser.dart';
import 'parsers/sms_parser.dart';

class SmsIngestService {
  static final StreamController<SmsRecord> _smsIngestedController =
      StreamController<SmsRecord>.broadcast();
  static Stream<SmsRecord> get onSmsIngested => _smsIngestedController.stream;

  final List<SmsParser> parsers;
  final HiveService hiveService;

  SmsIngestService({
    List<SmsParser>? parsers,
    HiveService? hiveService,
  })  : parsers = parsers ?? [BkashCashOutParser(), NagadCashOutParser()],
        hiveService = hiveService ?? HiveService.instance;

  Future<SmsRecord?> processSms({
    required String sender,
    required String body,
    required DateTime timestamp,
  }) async {
    final appState = hiveService.getAppState();

    // Check sender match (case-insensitive substring or match)
    final allowedSenders = [
      ...appState.senderIds,
      '16247', // bKash official shortcode
      '16167', // Nagad official shortcode
      'bkash',
      'nagad',
    ];
    final senderNormalized = sender.trim().toLowerCase();
    bool isAllowed = allowedSenders.any((allowed) =>
        senderNormalized.contains(allowed.toLowerCase()) ||
        allowed.toLowerCase().contains(senderNormalized));

    // Also allow if the body explicitly contains provider keywords and a TrxID with Tk
    if (!isAllowed) {
      final bodyLower = body.toLowerCase();
      if ((bodyLower.contains('bkash') ||
              bodyLower.contains('nagad') ||
              bodyLower.contains('cash out') ||
              bodyLower.contains('you have received')) &&
          (bodyLower.contains('trxid') ||
              bodyLower.contains('txnid') ||
              bodyLower.contains('trx id')) &&
          bodyLower.contains('tk')) {
        isAllowed = true;
      }
    }

    if (!isAllowed) {
      AppLogger.instance
          .warning('SMS', 'Ignored sender "$sender" (not in allowed list)');
      return null;
    }

    ParsedSms? parsed;
    for (final parser in parsers) {
      if (parser.canParse(sender, body)) {
        parsed = parser.parse(sender, body, timestamp);
        if (parsed != null) break;
      }
    }

    if (parsed == null) {
      AppLogger.instance
          .warning('SMS', 'Unrecognized format from $sender', body);
      return null;
    }

    final record = parsed.toSmsRecord();
    final saved = await hiveService.saveSmsRecord(record);
    if (!saved) {
      AppLogger.instance
          .info('SMS', 'Duplicate ${record.provider.toUpperCase()} Trx: ${record.txnId} skipped');
      return null;
    }

    _smsIngestedController.add(record);

    AppLogger.instance.success(
      'SMS',
      'Saved ${record.provider.toUpperCase()} ৳${record.amount.toStringAsFixed(0)} (Trx: ${record.txnId})',
    );
    return record;
  }
}
