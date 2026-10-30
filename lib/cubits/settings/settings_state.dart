import 'package:equatable/equatable.dart';
import '../../data/models/app_state.dart';

class SettingsState extends Equatable {
  final AppState appState;
  final String? adminName;
  final String? adminRole;
  final bool isTestingConnection;
  final String? testConnectionResult;
  final bool isExportingCsv;
  final String? exportedCsvString;

  const SettingsState({
    required this.appState,
    this.adminName,
    this.adminRole,
    this.isTestingConnection = false,
    this.testConnectionResult,
    this.isExportingCsv = false,
    this.exportedCsvString,
  });

  SettingsState copyWith({
    AppState? appState,
    String? adminName,
    String? adminRole,
    bool? isTestingConnection,
    String? testConnectionResult,
    bool? isExportingCsv,
    String? exportedCsvString,
  }) {
    return SettingsState(
      appState: appState ?? this.appState,
      adminName: adminName ?? this.adminName,
      adminRole: adminRole ?? this.adminRole,
      isTestingConnection: isTestingConnection ?? this.isTestingConnection,
      testConnectionResult: testConnectionResult,
      isExportingCsv: isExportingCsv ?? this.isExportingCsv,
      exportedCsvString: exportedCsvString,
    );
  }

  @override
  List<Object?> get props => [
        appState,
        adminName,
        adminRole,
        isTestingConnection,
        testConnectionResult,
        isExportingCsv,
        exportedCsvString,
      ];
}
