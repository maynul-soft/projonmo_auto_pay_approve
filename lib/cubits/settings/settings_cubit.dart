import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api/payment_api.dart';
import '../../data/auth/token_storage.dart';
import '../../data/hive/hive_service.dart';
import '../../data/models/app_state.dart';
import '../../services/sync_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final HiveService hiveService;
  final TokenStorage tokenStorage;
  final PaymentApi paymentApi;

  SettingsCubit({
    HiveService? hiveService,
    TokenStorage? tokenStorage,
    PaymentApi? paymentApi,
  })  : hiveService = hiveService ?? HiveService.instance,
        tokenStorage = tokenStorage ?? TokenStorage(),
        paymentApi = paymentApi ?? PaymentApi(),
        super(SettingsState(appState: (hiveService ?? HiveService.instance).getAppState()));

  Future<void> loadSettings() async {
    final appState = hiveService.getAppState();
    final name = await tokenStorage.getAdminName();
    final role = await tokenStorage.getAdminRole();

    emit(state.copyWith(
      appState: appState,
      adminName: name,
      adminRole: role,
    ));
  }

  Future<void> updateSettings(AppState newState) async {
    final oldInterval = state.appState.syncIntervalMinutes;
    await hiveService.updateAppState(newState);
    emit(state.copyWith(appState: newState));
    if (oldInterval != newState.syncIntervalMinutes) {
      SyncService.instance.startPeriodicSync();
    }
  }

  Future<void> testConnection() async {
    emit(state.copyWith(isTestingConnection: true, testConnectionResult: null));
    final appState = hiveService.getAppState();

    try {
      final payments = await paymentApi.fetchPendingPayments(
        baseUrl: appState.baseUrl,
        pendingApiUrl: appState.pendingApiUrl,
      );
      emit(state.copyWith(
        isTestingConnection: false,
        testConnectionResult: 'Success: Connected! (${payments.length} pending items found)',
      ));
    } catch (e) {
      emit(state.copyWith(
        isTestingConnection: false,
        testConnectionResult: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<String> exportCsv() async {
    emit(state.copyWith(isExportingCsv: true));
    final box = hiveService.getSmsBox();
    final records = box.values.toList();
    records.sort((a, b) => b.smsDateTime.compareTo(a.smsDateTime));

    final buffer = StringBuffer();
    buffer.writeln('ID,Provider,Sender,TxnID,Amount,Customer,Status,SMS Time,Approved At,Approved By');

    for (final r in records) {
      buffer.writeln(
        '"${r.id}","${r.provider}","${r.sender}","${r.txnId}",${r.amount},"${r.customer}","${r.status}","${r.smsDateTime}","${r.approvedAt ?? ''}","${r.approvedBy ?? ''}"',
      );
    }

    final csv = buffer.toString();
    emit(state.copyWith(isExportingCsv: false, exportedCsvString: csv));
    return csv;
  }

  Future<int> clearOldRecords(int days) async {
    final count = await hiveService.clearOldSyncedRecords(days);
    return count;
  }

  Future<void> clearAllData() async {
    await hiveService.clearAllData();
    await loadSettings();
  }
}
