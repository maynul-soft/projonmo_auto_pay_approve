import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api/payment_api.dart';
import '../../data/hive/hive_service.dart';
import '../../data/models/pending_payment.dart';
import 'pending_state.dart';

class PendingCubit extends Cubit<PendingState> {
  final HiveService hiveService;
  final PaymentApi paymentApi;

  PendingCubit({
    HiveService? hiveService,
    PaymentApi? paymentApi,
  })  : hiveService = hiveService ?? HiveService.instance,
        paymentApi = paymentApi ?? PaymentApi(),
        super(const PendingState());

  void loadFromCache() {
    final box = hiveService.getPendingBox();
    final payments = box.values.toList();
    _processAndEmit(payments);
  }

  Future<void> refreshFromApi() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final appState = hiveService.getAppState();

    try {
      final payments = await paymentApi.fetchPendingPayments(
        baseUrl: appState.baseUrl,
        pendingApiUrl: appState.pendingApiUrl,
      );
      await hiveService.replacePendingPayments(payments);
      _processAndEmit(payments);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void setSearchQuery(String query) {
    final q = query.trim().toUpperCase();
    final filtered = state.allItems.where((item) {
      if (q.isEmpty) return true;
      return item.payment.txnId.contains(q) ||
          (item.payment.customer ?? '').contains(q) ||
          item.payment.amount.toString().contains(q);
    }).toList();

    emit(state.copyWith(
      searchQuery: query,
      filteredItems: filtered,
    ));
  }

  void _processAndEmit(List<PendingPayment> payments) {
    final appState = hiveService.getAppState();
    final itemsWithMatch = <PendingItemWithMatch>[];
    double totalAmount = 0.0;
    DateTime? lastFetched;

    for (final p in payments) {
      totalAmount += p.amount;
      lastFetched = p.lastFetchedAt;
      final sms = hiveService.findSmsByTxnId(p.txnId);

      PendingMatchStatus status = PendingMatchStatus.noSms;
      double? smsAmt;

      if (sms != null) {
        smsAmt = sms.amount;
        final isMismatch = (sms.amount - p.amount).abs() > 0.01;
        if (appState.strictAmountCheck && isMismatch) {
          status = PendingMatchStatus.amountMismatch;
        } else {
          status = PendingMatchStatus.matched;
        }
      }

      itemsWithMatch.add(PendingItemWithMatch(
        payment: p,
        matchStatus: status,
        smsAmount: smsAmt,
      ));
    }

    final q = state.searchQuery.trim().toUpperCase();
    final filtered = itemsWithMatch.where((item) {
      if (q.isEmpty) return true;
      return item.payment.txnId.contains(q) ||
          (item.payment.customer ?? '').contains(q) ||
          item.payment.amount.toString().contains(q);
    }).toList();

    emit(state.copyWith(
      allItems: itemsWithMatch,
      filteredItems: filtered,
      isLoading: false,
      lastFetchedAt: lastFetched,
      totalCount: itemsWithMatch.length,
      totalAmount: totalAmount,
    ));
  }
}
