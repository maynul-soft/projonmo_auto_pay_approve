import '../../core/api_config.dart';

class AppState {
  final DateTime? lastSmsReadAt;
  final int lastSmsTimestampProcessed;
  final DateTime? lastSyncAt;
  final String? lastSyncStatus;
  final String? lastSyncMessage;
  final String pendingApiUrl;
  final String approveApiUrl;
  final String baseUrl;
  final String loginPath;
  final int syncIntervalMinutes;
  final bool strictAmountCheck;
  final bool autoApprove;
  final List<String> senderIds;
  final int initialScanDays;
  final bool allowForceApprove;

  AppState({
    this.lastSmsReadAt,
    this.lastSmsTimestampProcessed = 0,
    this.lastSyncAt,
    this.lastSyncStatus,
    this.lastSyncMessage,
    String? pendingApiUrl,
    String? approveApiUrl,
    String? baseUrl,
    String? loginPath,
    this.syncIntervalMinutes = 5,
    this.strictAmountCheck = true,
    this.autoApprove = true,
    List<String>? senderIds,
    this.initialScanDays = 2,
    this.allowForceApprove = false,
  })  : pendingApiUrl = pendingApiUrl ?? ApiConfig.defaultPendingPath,
        approveApiUrl = approveApiUrl ?? ApiConfig.defaultApprovePath,
        baseUrl = baseUrl ?? ApiConfig.initialBaseUrl,
        loginPath = loginPath ?? ApiConfig.defaultLoginPath,
        senderIds = senderIds ?? const ['bKash', 'NAGAD', '16167', '16216'];

  AppState copyWith({
    DateTime? lastSmsReadAt,
    int? lastSmsTimestampProcessed,
    DateTime? lastSyncAt,
    String? lastSyncStatus,
    String? lastSyncMessage,
    String? pendingApiUrl,
    String? approveApiUrl,
    String? baseUrl,
    String? loginPath,
    int? syncIntervalMinutes,
    bool? strictAmountCheck,
    bool? autoApprove,
    List<String>? senderIds,
    int? initialScanDays,
    bool? allowForceApprove,
  }) {
    return AppState(
      lastSmsReadAt: lastSmsReadAt ?? this.lastSmsReadAt,
      lastSmsTimestampProcessed:
          lastSmsTimestampProcessed ?? this.lastSmsTimestampProcessed,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      pendingApiUrl: pendingApiUrl ?? this.pendingApiUrl,
      approveApiUrl: approveApiUrl ?? this.approveApiUrl,
      baseUrl: baseUrl ?? this.baseUrl,
      loginPath: loginPath ?? this.loginPath,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      strictAmountCheck: strictAmountCheck ?? this.strictAmountCheck,
      autoApprove: autoApprove ?? this.autoApprove,
      senderIds: senderIds ?? this.senderIds,
      initialScanDays: initialScanDays ?? this.initialScanDays,
      allowForceApprove: allowForceApprove ?? this.allowForceApprove,
    );
  }
}
