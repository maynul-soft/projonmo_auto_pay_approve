import 'dart:async';
import 'package:flutter/services.dart';
import '../core/utils/app_logger.dart';
import '../data/sms/sms_ingest_service.dart';
import 'sync_service.dart';

class LiveSmsListener {
  static final LiveSmsListener instance = LiveSmsListener._internal();
  LiveSmsListener._internal();

  static const MethodChannel _channel =
      MethodChannel('com.projonmo.payment_auto_approver/sms');

  final SmsIngestService _ingestService = SmsIngestService();
  Timer? _debounceSyncTimer;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSmsReceived':
          final args = call.arguments as Map?;
          if (args != null) {
            final sender = args['sender']?.toString() ?? '';
            final body = args['body']?.toString() ?? '';
            final timestampMillis = args['timestamp'] as int? ??
                DateTime.now().millisecondsSinceEpoch;
            final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

            AppLogger.instance.info(
              'SMS',
              'Instant SMS arrived from $sender',
            );

            final record = await _ingestService.processSms(
              sender: sender,
              body: body,
              timestamp: date,
            );

            if (record != null) {
              _triggerDebouncedSync();
            }
          }
          break;

        case 'onInboxChanged':
          // Watchdog notification that an SMS was added to inbox
          _triggerDebouncedSync();
          break;
      }
    });

    // Drain queued SMS that arrived while app was closed
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    try {
      final List? queued =
          await _channel.invokeMethod<List>('getQueuedSms');
      if (queued != null && queued.isNotEmpty) {
        AppLogger.instance.info(
          'SMS',
          'Processing ${queued.length} queued background SMS',
        );
        bool hasNew = false;
        for (final item in queued) {
          if (item is Map) {
            final sender = item['sender']?.toString() ?? '';
            final body = item['body']?.toString() ?? '';
            final ts = item['timestamp'] as int? ??
                DateTime.now().millisecondsSinceEpoch;
            final rec = await _ingestService.processSms(
              sender: sender,
              body: body,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
            );
            if (rec != null) hasNew = true;
          }
        }
        await _channel.invokeMethod('clearQueuedSms');
        if (hasNew) {
          _triggerDebouncedSync();
        }
      }
    } catch (_) {}
  }

  void _triggerDebouncedSync() {
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = Timer(const Duration(seconds: 3), () {
      AppLogger.instance.info('SYNC', 'Triggering instant match for new SMS');
      SyncService.instance.runSync(trigger: 'sms_event');
    });
  }
}
