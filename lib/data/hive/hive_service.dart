import 'package:hive_flutter/hive_flutter.dart';
import '../../core/api_config.dart';
import '../models/sms_record.dart';
import '../models/pending_payment.dart';
import '../models/app_state.dart';
import '../models/sync_log.dart';
import 'adapters/sms_record_adapter.dart';
import 'adapters/pending_payment_adapter.dart';
import 'adapters/app_state_adapter.dart';
import 'adapters/sync_log_adapter.dart';

class HiveService {
  static const String smsBoxName = 'sms_records';
  static const String pendingBoxName = 'pending_payments';
  static const String appStateBoxName = 'app_state';
  static const String syncLogsBoxName = 'sync_logs';

  static final HiveService instance = HiveService._internal();
  HiveService._internal();

  static bool _adaptersRegistered = false;

  static void registerAdapters() {
    if (!_adaptersRegistered) {
      Hive.registerAdapter(SmsRecordAdapter());
      Hive.registerAdapter(PendingPaymentAdapter());
      Hive.registerAdapter(AppStateAdapter());
      Hive.registerAdapter(SyncLogAdapter());
      _adaptersRegistered = true;
    }
  }

  Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters();

    await Hive.openBox<SmsRecord>(smsBoxName);
    await Hive.openBox<PendingPayment>(pendingBoxName);
    await Hive.openBox<AppState>(appStateBoxName);
    await Hive.openBox<SyncLog>(syncLogsBoxName);

    // Initialize default app state if not present
    final stateBox = getAppStateBox();
    if (stateBox.isEmpty) {
      await stateBox.put('current', AppState());
    } else {
      final current = stateBox.get('current');
      if (current != null) {
        AppState updated = current;
        if (current.baseUrl.contains('localhost') ||
            current.baseUrl.contains('10.0.2.2') ||
            current.baseUrl.contains('admin.projonmo.tech') ||
            !current.baseUrl.contains('api.projonmo.tech')) {
          updated = updated.copyWith(
            baseUrl: ApiConfig.defaultBaseUrl,
            pendingApiUrl: ApiConfig.defaultPendingPath,
          );
        }
        if (updated.initialScanDays == 7) {
          updated = updated.copyWith(initialScanDays: 2);
        }
        if (updated.approveApiUrl.isEmpty ||
            updated.approveApiUrl == '/admin/deposits/approve' ||
            updated.approveApiUrl.endsWith('/deposits/approve')) {
          updated = updated.copyWith(
            approveApiUrl: ApiConfig.defaultApprovePath,
          );
        }
        if (updated != current) {
          await stateBox.put('current', updated);
        }
      }
    }
  }

  Box<SmsRecord> getSmsBox() => Hive.box<SmsRecord>(smsBoxName);
  Box<PendingPayment> getPendingBox() => Hive.box<PendingPayment>(pendingBoxName);
  Box<AppState> getAppStateBox() => Hive.box<AppState>(appStateBoxName);
  Box<SyncLog> getSyncLogsBox() => Hive.box<SyncLog>(syncLogsBoxName);

  AppState getAppState() {
    final box = getAppStateBox();
    return box.get('current') ?? AppState();
  }

  Future<void> updateAppState(AppState state) async {
    final box = getAppStateBox();
    await box.put('current', state);
  }

  Future<bool> saveSmsRecord(SmsRecord record) async {
    final box = getSmsBox();
    if (box.containsKey(record.id)) {
      // Record already exists with same provider and txnId
      return false;
    }
    await box.put(record.id, record);
    return true;
  }

  Future<void> updateSmsRecord(SmsRecord record) async {
    final box = getSmsBox();
    await box.put(record.id, record);
  }

  SmsRecord? findSmsByTxnId(String txnId) {
    final normalized = txnId.trim().toUpperCase();
    final box = getSmsBox();
    for (final record in box.values) {
      if (record.txnId.toUpperCase() == normalized) {
        return record;
      }
    }
    return null;
  }

  Future<void> replacePendingPayments(List<PendingPayment> list) async {
    final box = getPendingBox();
    await box.clear();
    for (final item in list) {
      await box.put(item.paymentId, item);
    }
  }

  Future<void> addSyncLog(SyncLog log) async {
    final box = getSyncLogsBox();
    await box.put(log.id, log);

    // Keep the last 200 rows and delete older ones
    if (box.length > 200) {
      final sortedKeys = box.keys.toList()
        ..sort((a, b) {
          final logA = box.get(a);
          final logB = box.get(b);
          if (logA == null || logB == null) return 0;
          return logA.startedAt.compareTo(logB.startedAt);
        });
      final toRemoveCount = box.length - 200;
      for (int i = 0; i < toRemoveCount; i++) {
        await box.delete(sortedKeys[i]);
      }
    }
  }

  Future<int> clearOldSyncedRecords(int olderThanDays) async {
    final box = getSmsBox();
    final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
    final keysToDelete = <dynamic>[];

    for (final entry in box.toMap().entries) {
      final record = entry.value;
      if (record.status == 'approved' && record.smsDateTime.isBefore(cutoff)) {
        keysToDelete.add(entry.key);
      }
    }

    await box.deleteAll(keysToDelete);
    return keysToDelete.length;
  }

  Future<void> clearAllData() async {
    await getSmsBox().clear();
    await getPendingBox().clear();
    await getSyncLogsBox().clear();
    final current = getAppState();
    await getAppStateBox().put('current', current.copyWith(
      lastSmsReadAt: null,
      lastSmsTimestampProcessed: 0,
      lastSyncAt: null,
      lastSyncStatus: null,
      lastSyncMessage: null,
    ));
  }
}
