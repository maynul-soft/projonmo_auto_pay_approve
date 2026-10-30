import 'package:equatable/equatable.dart';
import '../../data/models/sync_log.dart';

class SyncLogsState extends Equatable {
  final List<SyncLog> logs;
  final bool isLoading;

  const SyncLogsState({
    this.logs = const [],
    this.isLoading = false,
  });

  SyncLogsState copyWith({
    List<SyncLog>? logs,
    bool? isLoading,
  }) {
    return SyncLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [logs, isLoading];
}
