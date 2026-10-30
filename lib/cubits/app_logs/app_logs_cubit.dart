import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_logger.dart';
import 'app_logs_state.dart';

class AppLogsCubit extends Cubit<AppLogsState> {
  final AppLogger logger;
  StreamSubscription? _logSubscription;

  AppLogsCubit({AppLogger? logger})
      : logger = logger ?? AppLogger.instance,
        super(const AppLogsState()) {
    _logSubscription = this.logger.logStream.listen((_) {
      _loadFromLogger();
    });
    _loadFromLogger();
  }

  void _loadFromLogger() {
    final logs = logger.logs;
    _applyFilter(
      all: logs,
      filter: state.selectedFilter,
      query: state.searchQuery,
    );
  }

  void setFilter(String filter) {
    _applyFilter(
      all: state.allLogs,
      filter: filter,
      query: state.searchQuery,
    );
  }

  void setSearchQuery(String query) {
    _applyFilter(
      all: state.allLogs,
      filter: state.selectedFilter,
      query: query,
    );
  }

  void _applyFilter({
    required List<LogEntry> all,
    required String filter,
    required String query,
  }) {
    final q = query.trim().toLowerCase();

    final filtered = all.where((entry) {
      if (filter == 'ERROR' && entry.level != LogLevel.error) {
        return false;
      }
      if (filter == 'WARNING' && entry.level != LogLevel.warning) {
        return false;
      }
      if (filter == 'API' && entry.tag != 'API') {
        return false;
      }
      if (filter == 'SMS' && entry.tag != 'SMS') {
        return false;
      }
      if (filter == 'SYNC' && entry.tag != 'SYNC') {
        return false;
      }

      if (q.isNotEmpty) {
        final matchesMsg = entry.message.toLowerCase().contains(q);
        final matchesTag = entry.tag.toLowerCase().contains(q);
        if (!matchesMsg && !matchesTag) return false;
      }

      return true;
    }).toList();

    emit(state.copyWith(
      allLogs: all,
      filteredLogs: filtered,
      selectedFilter: filter,
      searchQuery: query,
    ));
  }

  void clearLogs() {
    logger.clear();
  }

  String exportLogsText() {
    final buffer = StringBuffer();
    for (final l in state.allLogs.reversed) {
      buffer.writeln(
        '[${l.timestamp.toIso8601String()}] [${l.level.name.toUpperCase()}] [${l.tag}] ${l.message}',
      );
      if (l.details != null && l.details!.isNotEmpty) {
        buffer.writeln('Details: ${l.details}');
      }
    }
    return buffer.toString();
  }

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
