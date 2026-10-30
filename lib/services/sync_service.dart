import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';
import '../data/api/payment_api.dart';
import '../data/auth/auth_repository.dart';
import '../data/hive/hive_service.dart';
import '../data/models/sync_log.dart';
import '../data/sms/sms_reader.dart';
import 'approve_service.dart';
import 'matching_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();

  final HiveService hiveService;
  final SmsReader smsReader;
  final PaymentApi paymentApi;
  final MatchingService matchingService;
  final ApproveService approveService;
  final AuthRepository authRepository;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Timer? _periodicTimer;

  final _syncStreamController = StreamController<SyncLog>.broadcast();
  Stream<SyncLog> get syncStream => _syncStreamController.stream;

  SyncService._internal({
    HiveService? hiveService,
    SmsReader? smsReader,
    PaymentApi? paymentApi,
    MatchingService? matchingService,
    ApproveService? approveService,
    AuthRepository? authRepository,
  })  : hiveService = hiveService ?? HiveService.instance,
        smsReader = smsReader ?? SmsReader(),
        paymentApi = paymentApi ?? PaymentApi(),
        matchingService = matchingService ?? MatchingService(),
        approveService = approveService ?? ApproveService(),
        authRepository = authRepository ?? AuthRepository();

  void startPeriodicSync({bool triggerImmediate = false}) {
    _periodicTimer?.cancel();
    final appState = hiveService.getAppState();
    final intervalMinutes =
        appState.syncIntervalMinutes < 1 ? 5 : appState.syncIntervalMinutes;

    AppLogger.instance.info(
      'SYNC',
      'Auto-sync timer activated: runs every $intervalMinutes min',
    );

    if (triggerImmediate) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        runSync(trigger: 'app_launch');
      });
    }

    _periodicTimer =
        Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      AppLogger.instance.info('SYNC', 'Periodic timer triggered auto-sync');
      await runSync(trigger: 'timer');
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    AppLogger.instance.info('SYNC', 'Auto-sync timer stopped');
  }

  Future<SyncLog?> runSync({required String trigger}) async {
    if (_isSyncing) {
      debugPrint('SyncService: sync already in progress, skipping trigger: $trigger');
      return null;
    }

    _isSyncing = true;
    AppLogger.instance.info('SYNC', 'Sync started (trigger: $trigger)');
    final logId = DateTime.now().millisecondsSinceEpoch.toString();
    SyncLog currentLog = SyncLog(id: logId, startedAt: DateTime.now(), trigger: trigger);

    try {
      // 1. Inbox Scan
      final newSmsCount = await smsReader.scanInbox();
      currentLog = currentLog.copyWith(newSmsSaved: newSmsCount);

      // Check session status before API calls
      final sessionStatus = await authRepository.checkSession();
      if (sessionStatus != SessionStatus.active) {
        AppLogger.instance
            .warning('SYNC', 'Sync aborted: Session is $sessionStatus');
        currentLog = currentLog.copyWith(
          finishedAt: DateTime.now(),
          error: 'Session not active ($sessionStatus)',
        );
        await hiveService.addSyncLog(currentLog);
        _syncStreamController.add(currentLog);
        _isSyncing = false;
        return currentLog;
      }

      // 2. Connectivity check
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);
      if (isOffline) {
        AppLogger.instance.warning('SYNC', 'Device offline, API calls skipped');
        currentLog = currentLog.copyWith(
          finishedAt: DateTime.now(),
          error: 'Offline',
        );
        final appState = hiveService.getAppState();
        await hiveService.updateAppState(appState.copyWith(
          lastSyncAt: DateTime.now(),
          lastSyncStatus: 'failed',
          lastSyncMessage: 'Offline',
        ));
        await hiveService.addSyncLog(currentLog);
        _syncStreamController.add(currentLog);
        _isSyncing = false;
        return currentLog;
      }

      // 3. Fetch Pending Payments
      final appState = hiveService.getAppState();
      final pendingList = await paymentApi.fetchPendingPayments(
        baseUrl: appState.baseUrl,
        pendingApiUrl: appState.pendingApiUrl,
      );

      await hiveService.replacePendingPayments(pendingList);
      currentLog = currentLog.copyWith(pendingFetched: pendingList.length);

      // 4. Run Matching
      final matchResults = await matchingService.matchPendingList(pendingList);
      currentLog = currentLog.copyWith(matchedCount: matchResults.length);

      // 5. Auto-Approve matches if autoApprove is enabled
      int approvedCount = 0;
      int failedCount = 0;

      if (appState.autoApprove) {
        for (final match in matchResults) {
          if (!match.isAmountMismatch) {
            final res = await approveService.approve(
              smsRecordId: match.record.id,
              paymentId: match.pending.paymentId,
              isManual: false,
            );
            if (res.success) {
              approvedCount++;
            } else {
              failedCount++;
            }
            // Sequential Queue delay (250ms) between calls to prevent server flooding
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
      }

      // Retry previously failed records
      final retriedSuccess = await approveService.retryFailedRecords();
      approvedCount += retriedSuccess;

      currentLog = currentLog.copyWith(
        finishedAt: DateTime.now(),
        approvedCount: approvedCount,
        failedCount: failedCount,
      );

      await hiveService.updateAppState(appState.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncStatus: 'success',
        lastSyncMessage: 'Synced ${pendingList.length} pending, approved $approvedCount',
      ));

      await hiveService.addSyncLog(currentLog);
      _syncStreamController.add(currentLog);
      AppLogger.instance.success(
        'SYNC',
        'Sync done: +$newSmsCount SMS, ${pendingList.length} pending, $approvedCount approved',
      );
      return currentLog;
    } catch (e) {
      AppLogger.instance.error('SYNC', 'Sync failed', e);
      currentLog = currentLog.copyWith(
        finishedAt: DateTime.now(),
        error: e.toString(),
      );

      final appState = hiveService.getAppState();
      await hiveService.updateAppState(appState.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncStatus: 'failed',
        lastSyncMessage: e.toString(),
      ));

      await hiveService.addSyncLog(currentLog);
      _syncStreamController.add(currentLog);
      return currentLog;
    } finally {
      _isSyncing = false;
    }
  }
}
