import 'package:equatable/equatable.dart';
import '../../data/models/pending_payment.dart';
import '../../data/models/sms_record.dart';

class ManualApproveItem extends Equatable {
  final PendingPayment pending;
  final SmsRecord? smsRecord;
  final bool isSelected;
  final bool isApproving;
  final String? errorMessage;

  const ManualApproveItem({
    required this.pending,
    this.smsRecord,
    this.isSelected = false,
    this.isApproving = false,
    this.errorMessage,
  });

  ManualApproveItem copyWith({
    PendingPayment? pending,
    SmsRecord? smsRecord,
    bool? isSelected,
    bool? isApproving,
    String? errorMessage,
  }) {
    return ManualApproveItem(
      pending: pending ?? this.pending,
      smsRecord: smsRecord ?? this.smsRecord,
      isSelected: isSelected ?? this.isSelected,
      isApproving: isApproving ?? this.isApproving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        pending,
        smsRecord,
        isSelected,
        isApproving,
        errorMessage,
      ];
}

class ManualApproveState extends Equatable {
  final List<ManualApproveItem> items;
  final bool showAllPending;
  final bool allowForceApprove;
  final bool isBulkApproving;

  const ManualApproveState({
    this.items = const [],
    this.showAllPending = false,
    this.allowForceApprove = false,
    this.isBulkApproving = false,
  });

  int get selectedCount => items.where((i) => i.isSelected).length;

  ManualApproveState copyWith({
    List<ManualApproveItem>? items,
    bool? showAllPending,
    bool? allowForceApprove,
    bool? isBulkApproving,
  }) {
    return ManualApproveState(
      items: items ?? this.items,
      showAllPending: showAllPending ?? this.showAllPending,
      allowForceApprove: allowForceApprove ?? this.allowForceApprove,
      isBulkApproving: isBulkApproving ?? this.isBulkApproving,
    );
  }

  @override
  List<Object?> get props => [
        items,
        showAllPending,
        allowForceApprove,
        isBulkApproving,
      ];
}
