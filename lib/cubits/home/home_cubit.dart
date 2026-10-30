import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/hive/hive_service.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../services/background_service.dart';
import '../../services/sync_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HiveService hiveService;
  final SyncService syncService;
  final BackgroundServiceManager backgroundManager;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _smsIngestSubscription;

  HomeCubit({
    HiveService? hiveService,
    SyncService? syncService,
    BackgroundServiceManager? backgroundManager,
  })  : hiveService = hiveService ?? HiveService.instance,
        syncService = syncService ?? SyncService.instance,
        backgroundManager =
            backgroundManager ?? BackgroundServiceManager.instance,
        super(const HomeState()) {
    _syncSubscription = this.syncService.syncStream.listen((_) {
      loadDashboardData();
    });
    _smsIngestSubscription = SmsIngestService.onSmsIngested.listen((_) {
      loadDashboardData();
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> loadDashboardData() async {
    final appState = hiveService.getAppState();
    final smsBox = hiveService.getSmsBox();
    final allRecords = smsBox.values.toList();

    // Sort newest first
    allRecords.sort((a, b) => b.smsDateTime.compareTo(a.smsDateTime));

    final now = DateTime.now();

    int todayRead = 0;
    double todayAmount = 0.0;
    int todayApproved = 0;
    int todayUnmatched = 0;
    int todayFailed = 0;

    int totalRead = allRecords.length;
    double totalAmount = 0.0;
    int totalApproved = 0;
    int totalUnmatched = 0;
    int totalFailed = 0;

    for (final r in allRecords) {
      totalAmount += r.amount;
      if (r.status == 'approved') {
        totalApproved++;
      } else if (r.status == 'failed') {
        totalFailed++;
      } else {
        totalUnmatched++;
      }

      final isToday =
          _isSameDay(r.smsDateTime, now) || _isSameDay(r.receivedAt, now);
      if (isToday) {
        todayRead++;
        todayAmount += r.amount;
        if (r.status == 'approved') {
          todayApproved++;
        } else if (r.status == 'failed') {
          todayFailed++;
        } else {
          todayUnmatched++;
        }
      }
    }

    final isRunning = await backgroundManager.isRunning();

    emit(state.copyWith(
      lastSmsReadAt: appState.lastSmsReadAt,
      lastSyncAt: appState.lastSyncAt,
      lastSyncStatus: appState.lastSyncStatus,
      lastSyncMessage: appState.lastSyncMessage,
      isBackgroundServiceRunning: isRunning,
      todayStats: CounterStats(
        smsRead: todayRead,
        totalAmount: todayAmount,
        approved: todayApproved,
        unmatched: todayUnmatched,
        failed: todayFailed,
      ),
      totalStats: CounterStats(
        smsRead: totalRead,
        totalAmount: totalAmount,
        approved: totalApproved,
        unmatched: totalUnmatched,
        failed: totalFailed,
      ),
      latestRecords: allRecords.take(5).toList(),
      isSyncing: syncService.isSyncing,
    ));
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    await syncService.runSync(trigger: 'manual');
    await loadDashboardData();
  }

  Future<void> toggleBackgroundService() async {
    final isRunning = await backgroundManager.isRunning();
    if (isRunning) {
      backgroundManager.stopService();
    } else {
      backgroundManager.startService();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    final newStatus = await backgroundManager.isRunning();
    emit(state.copyWith(isBackgroundServiceRunning: newStatus));
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _smsIngestSubscription?.cancel();
    return super.close();
  }
}
