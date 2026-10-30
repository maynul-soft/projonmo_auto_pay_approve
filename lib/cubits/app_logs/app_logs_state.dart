import 'package:equatable/equatable.dart';
import '../../core/utils/app_logger.dart';

class AppLogsState extends Equatable {
  final List<LogEntry> allLogs;
  final List<LogEntry> filteredLogs;
  final String selectedFilter; // 'ALL', 'ERROR', 'WARNING', 'API', 'SMS', 'SYNC'
  final String searchQuery;

  const AppLogsState({
    this.allLogs = const [],
    this.filteredLogs = const [],
    this.selectedFilter = 'ALL',
    this.searchQuery = '',
  });

  AppLogsState copyWith({
    List<LogEntry>? allLogs,
    List<LogEntry>? filteredLogs,
    String? selectedFilter,
    String? searchQuery,
  }) {
    return AppLogsState(
      allLogs: allLogs ?? this.allLogs,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allLogs,
        filteredLogs,
        selectedFilter,
        searchQuery,
      ];
}
