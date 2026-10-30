import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/hive/hive_service.dart';
import 'sync_logs_state.dart';

class SyncLogsCubit extends Cubit<SyncLogsState> {
  final HiveService hiveService;

  SyncLogsCubit({HiveService? hiveService})
      : hiveService = hiveService ?? HiveService.instance,
        super(const SyncLogsState());

  void loadLogs() {
    emit(state.copyWith(isLoading: true));
    final box = hiveService.getSyncLogsBox();
    final list = box.values.toList();
    // Sort newest first
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    emit(state.copyWith(logs: list, isLoading: false));
  }
}
