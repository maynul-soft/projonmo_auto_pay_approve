import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../hive/hive_service.dart';
import 'sms_ingest_service.dart';

class SmsReader {
  final SmsQuery smsQuery;
  final SmsIngestService ingestService;
  final HiveService hiveService;

  SmsReader({
    SmsQuery? smsQuery,
    SmsIngestService? ingestService,
    HiveService? hiveService,
  })  : smsQuery = smsQuery ?? SmsQuery(),
        ingestService = ingestService ?? SmsIngestService(),
        hiveService = hiveService ?? HiveService.instance;

  Future<int> scanInbox({int? customDays}) async {
    final appState = hiveService.getAppState();
    int lastProcessedMillis = appState.lastSmsTimestampProcessed;

    // If never scanned before (or customDays specified), compute cutoff
    if (lastProcessedMillis == 0 || customDays != null) {
      final days = customDays ?? appState.initialScanDays;
      final cutoff = DateTime.now().subtract(Duration(days: days));
      lastProcessedMillis = cutoff.millisecondsSinceEpoch;
    }

    try {
      final messages = await smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        sort: true,
      );

      int newSavedCount = 0;
      int maxTimestampSeen = appState.lastSmsTimestampProcessed;

      for (final msg in messages) {
        final address = msg.address ?? '';
        final body = msg.body ?? '';
        final date = msg.date ?? DateTime.now();
        final msgMillis = date.millisecondsSinceEpoch;

        // Skip messages older than lastProcessedMillis
        if (msgMillis <= lastProcessedMillis) {
          continue;
        }

        if (msgMillis > maxTimestampSeen) {
          maxTimestampSeen = msgMillis;
        }

        final record = await ingestService.processSms(
          sender: address,
          body: body,
          timestamp: date,
        );

        if (record != null) {
          newSavedCount++;
        }
      }

      await hiveService.updateAppState(
        appState.copyWith(
          lastSmsReadAt: DateTime.now(),
          lastSmsTimestampProcessed: maxTimestampSeen,
        ),
      );

      return newSavedCount;
    } catch (e) {
      debugPrint('SmsReader scanInbox error: $e');
      return 0;
    }
  }
}
