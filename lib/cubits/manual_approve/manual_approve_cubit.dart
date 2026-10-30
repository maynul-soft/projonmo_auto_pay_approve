import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/hive/hive_service.dart';
import '../../services/approve_service.dart';
import 'manual_approve_state.dart';

class ManualApproveCubit extends Cubit<ManualApproveState> {
  final HiveService hiveService;
  final ApproveService approveService;

  ManualApproveCubit({
    HiveService? hiveService,
    ApproveService? approveService,
  })  : hiveService = hiveService ?? HiveService.instance,
        approveService = approveService ?? ApproveService(),
        super(const ManualApproveState());

  void loadPendingApprovals() {
    final appState = hiveService.getAppState();
    final pendingBox = hiveService.getPendingBox();
    final allPending = pendingBox.values.toList();

    final items = <ManualApproveItem>[];
    for (final p in allPending) {
      final sms = hiveService.findSmsByTxnId(p.txnId);

      // If SMS is already approved, do not show in manual approve list
      if (sms != null && sms.status == 'approved') {
        continue;
      }

      if (sms != null) {
        // Matched, failed, or amount_mismatch
        items.add(ManualApproveItem(pending: p, smsRecord: sms));
      } else if (state.showAllPending) {
        // No SMS found
        items.add(ManualApproveItem(pending: p, smsRecord: null));
      }
    }

    emit(state.copyWith(
      items: items,
      allowForceApprove: appState.allowForceApprove,
    ));
  }

  void toggleShowAllPending(bool show) {
    emit(state.copyWith(showAllPending: show));
    loadPendingApprovals();
  }

  void toggleItemSelection(String paymentId) {
    final updated = state.items.map((item) {
      if (item.pending.paymentId == paymentId) {
        return item.copyWith(isSelected: !item.isSelected);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void selectAll(bool select) {
    final updated = state.items
        .map((item) => item.copyWith(isSelected: select))
        .toList();
    emit(state.copyWith(items: updated));
  }

  Future<void> approveItem(String paymentId) async {
    final index =
        state.items.indexWhere((i) => i.pending.paymentId == paymentId);
    if (index == -1) return;

    final item = state.items[index];
    final updatedList = List<ManualApproveItem>.from(state.items);
    updatedList[index] = item.copyWith(isApproving: true, errorMessage: null);
    emit(state.copyWith(items: updatedList));

    final recordId = item.smsRecord?.id ?? 'manual_${item.pending.txnId}';

    final result = await approveService.approve(
      smsRecordId: recordId,
      paymentId: item.pending.paymentId,
      isManual: true,
    );

    if (result.success) {
      loadPendingApprovals();
    } else {
      final currentList = List<ManualApproveItem>.from(state.items);
      final currentIdx =
          currentList.indexWhere((i) => i.pending.paymentId == paymentId);
      if (currentIdx != -1) {
        currentList[currentIdx] = currentList[currentIdx].copyWith(
          isApproving: false,
          errorMessage: result.errorMessage ?? 'Approval failed',
        );
        emit(state.copyWith(items: currentList));
      }
    }
  }

  Future<void> approveSelected() async {
    final selectedItems =
        state.items.where((i) => i.isSelected).toList();
    if (selectedItems.isEmpty) return;

    emit(state.copyWith(isBulkApproving: true));

    for (final item in selectedItems) {
      await approveItem(item.pending.paymentId);
    }

    emit(state.copyWith(isBulkApproving: false));
    loadPendingApprovals();
  }
}
