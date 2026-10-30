class SyncLog {
  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String trigger; // 'timer', 'manual', 'app_open', 'sms_event'
  final int smsScanned;
  final int newSmsSaved;
  final int pendingFetched;
  final int matchedCount;
  final int approvedCount;
  final int failedCount;
  final String? error;

  SyncLog({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.trigger,
    this.smsScanned = 0,
    this.newSmsSaved = 0,
    this.pendingFetched = 0,
    this.matchedCount = 0,
    this.approvedCount = 0,
    this.failedCount = 0,
    this.error,
  });

  SyncLog copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? trigger,
    int? smsScanned,
    int? newSmsSaved,
    int? pendingFetched,
    int? matchedCount,
    int? approvedCount,
    int? failedCount,
    String? error,
  }) {
    return SyncLog(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      trigger: trigger ?? this.trigger,
      smsScanned: smsScanned ?? this.smsScanned,
      newSmsSaved: newSmsSaved ?? this.newSmsSaved,
      pendingFetched: pendingFetched ?? this.pendingFetched,
      matchedCount: matchedCount ?? this.matchedCount,
      approvedCount: approvedCount ?? this.approvedCount,
      failedCount: failedCount ?? this.failedCount,
      error: error ?? this.error,
    );
  }
}
