import 'package:equatable/equatable.dart';
import '../../data/models/sms_record.dart';

class CounterStats extends Equatable {
  final int smsRead;
  final double totalAmount;
  final int approved;
  final int unmatched;
  final int failed;

  const CounterStats({
    this.smsRead = 0,
    this.totalAmount = 0.0,
    this.approved = 0,
    this.unmatched = 0,
    this.failed = 0,
  });

  @override
  List<Object?> get props => [smsRead, totalAmount, approved, unmatched, failed];
}

class HomeState extends Equatable {
  final DateTime? lastSmsReadAt;
  final DateTime? lastSyncAt;
  final String? lastSyncStatus;
  final String? lastSyncMessage;
  final bool isBackgroundServiceRunning;
  final bool isSyncing;
  final CounterStats todayStats;
  final CounterStats totalStats;
  final List<SmsRecord> latestRecords;

  const HomeState({
    this.lastSmsReadAt,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.lastSyncMessage,
    this.isBackgroundServiceRunning = false,
    this.isSyncing = false,
    this.todayStats = const CounterStats(),
    this.totalStats = const CounterStats(),
    this.latestRecords = const [],
  });

  HomeState copyWith({
    DateTime? lastSmsReadAt,
    DateTime? lastSyncAt,
    String? lastSyncStatus,
    String? lastSyncMessage,
    bool? isBackgroundServiceRunning,
    bool? isSyncing,
    CounterStats? todayStats,
    CounterStats? totalStats,
    List<SmsRecord>? latestRecords,
  }) {
    return HomeState(
      lastSmsReadAt: lastSmsReadAt ?? this.lastSmsReadAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      isBackgroundServiceRunning:
          isBackgroundServiceRunning ?? this.isBackgroundServiceRunning,
      isSyncing: isSyncing ?? this.isSyncing,
      todayStats: todayStats ?? this.todayStats,
      totalStats: totalStats ?? this.totalStats,
      latestRecords: latestRecords ?? this.latestRecords,
    );
  }

  @override
  List<Object?> get props => [
        lastSmsReadAt,
        lastSyncAt,
        lastSyncStatus,
        lastSyncMessage,
        isBackgroundServiceRunning,
        isSyncing,
        todayStats,
        totalStats,
        latestRecords,
      ];
}
