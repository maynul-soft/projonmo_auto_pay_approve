import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/hive/hive_service.dart';
import '../../data/models/sms_record.dart';
import '../../data/sms/sms_reader.dart';
import 'sms_records_state.dart';

class SmsRecordsCubit extends Cubit<SmsRecordsState> {
  final HiveService hiveService;
  final SmsReader smsReader;

  SmsRecordsCubit({
    HiveService? hiveService,
    SmsReader? smsReader,
  })  : hiveService = hiveService ?? HiveService.instance,
        smsReader = smsReader ?? SmsReader(),
        super(const SmsRecordsState());

  void loadRecords() {
    final box = hiveService.getSmsBox();
    final list = box.values.toList();
    list.sort((a, b) => b.smsDateTime.compareTo(a.smsDateTime));

    _applyFilter(
      all: list,
      provider: state.providerFilter,
      status: state.statusFilter,
      query: state.searchQuery,
      start: state.startDate,
      end: state.endDate,
    );
  }

  void setProviderFilter(String provider) {
    _applyFilter(
      all: state.allRecords,
      provider: provider,
      status: state.statusFilter,
      query: state.searchQuery,
      start: state.startDate,
      end: state.endDate,
    );
  }

  void setStatusFilter(String status) {
    _applyFilter(
      all: state.allRecords,
      provider: state.providerFilter,
      status: status,
      query: state.searchQuery,
      start: state.startDate,
      end: state.endDate,
    );
  }

  void setSearchQuery(String query) {
    _applyFilter(
      all: state.allRecords,
      provider: state.providerFilter,
      status: state.statusFilter,
      query: query,
      start: state.startDate,
      end: state.endDate,
    );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _applyFilter(
      all: state.allRecords,
      provider: state.providerFilter,
      status: state.statusFilter,
      query: state.searchQuery,
      start: start,
      end: end,
    );
  }

  void _applyFilter({
    required List<SmsRecord> all,
    required String provider,
    required String status,
    required String query,
    DateTime? start,
    DateTime? end,
  }) {
    final q = query.trim().toLowerCase();

    final filtered = all.where((item) {
      if (provider != 'all' && item.provider.toLowerCase() != provider.toLowerCase()) {
        return false;
      }
      if (status != 'all' && item.status.toLowerCase() != status.toLowerCase()) {
        return false;
      }
      if (start != null && item.smsDateTime.isBefore(start)) {
        return false;
      }
      if (end != null && item.smsDateTime.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchesTxn = item.txnId.toLowerCase().contains(q);
        final matchesAmount = item.amount.toString().contains(q);
        final matchesCustomer = item.customer.toLowerCase().contains(q);
        if (!matchesTxn && !matchesAmount && !matchesCustomer) {
          return false;
        }
      }
      return true;
    }).toList();

    double total = 0.0;
    for (final f in filtered) {
      total += f.amount;
    }

    emit(state.copyWith(
      allRecords: all,
      filteredRecords: filtered,
      providerFilter: provider,
      statusFilter: status,
      searchQuery: query,
      startDate: start,
      endDate: end,
      filteredCount: filtered.length,
      filteredTotalAmount: total,
    ));
  }

  Future<int> scanInboxFromPhone({int? customDays}) async {
    emit(state.copyWith(isScanning: true));
    final count = await smsReader.scanInbox(customDays: customDays);
    loadRecords();
    emit(state.copyWith(isScanning: false));
    return count;
  }
}
