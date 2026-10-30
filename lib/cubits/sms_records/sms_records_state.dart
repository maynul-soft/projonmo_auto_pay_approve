import 'package:equatable/equatable.dart';
import '../../data/models/sms_record.dart';

class SmsRecordsState extends Equatable {
  final List<SmsRecord> allRecords;
  final List<SmsRecord> filteredRecords;
  final String providerFilter; // 'all', 'bkash', 'nagad'
  final String statusFilter; // 'all', 'unmatched', 'matched', 'approved', 'failed', 'amount_mismatch'
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isScanning;
  final int filteredCount;
  final double filteredTotalAmount;

  const SmsRecordsState({
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.providerFilter = 'all',
    this.statusFilter = 'all',
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isScanning = false,
    this.filteredCount = 0,
    this.filteredTotalAmount = 0.0,
  });

  SmsRecordsState copyWith({
    List<SmsRecord>? allRecords,
    List<SmsRecord>? filteredRecords,
    String? providerFilter,
    String? statusFilter,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool? isScanning,
    int? filteredCount,
    double? filteredTotalAmount,
  }) {
    return SmsRecordsState(
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      providerFilter: providerFilter ?? this.providerFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isScanning: isScanning ?? this.isScanning,
      filteredCount: filteredCount ?? this.filteredCount,
      filteredTotalAmount: filteredTotalAmount ?? this.filteredTotalAmount,
    );
  }

  @override
  List<Object?> get props => [
        allRecords,
        filteredRecords,
        providerFilter,
        statusFilter,
        searchQuery,
        startDate,
        endDate,
        isScanning,
        filteredCount,
        filteredTotalAmount,
      ];
}
