import '../core/utils/app_logger.dart';
import '../data/api/payment_api.dart';
import '../data/hive/hive_service.dart';
import '../data/models/sms_record.dart';

class ApproveResult {
  final bool success;
  final String? errorMessage;
  final SmsRecord record;

  ApproveResult({
    required this.success,
    this.errorMessage,
    required this.record,
  });
}

class ApproveService {
  final PaymentApi paymentApi;
  final HiveService hiveService;

  ApproveService({
    PaymentApi? paymentApi,
    HiveService? hiveService,
  })  : paymentApi = paymentApi ?? PaymentApi(),
        hiveService = hiveService ?? HiveService.instance;

  Future<ApproveResult> approve({
    required String smsRecordId,
    required String paymentId,
    required bool isManual,
  }) async {
    final box = hiveService.getSmsBox();
    final record = box.get(smsRecordId);

    if (record == null) {
      return ApproveResult(
        success: false,
        errorMessage: 'Record not found in local database',
        record: SmsRecord(
          id: smsRecordId,
          provider: 'unknown',
          sender: '',
          rawBody: '',
          txnId: '',
          amount: 0,
          customer: '',
          smsDateTime: DateTime.now(),
          receivedAt: DateTime.now(),
        ),
      );
    }

    // Safety: re-read from Hive. If already approved, return success immediately
    if (record.status == 'approved') {
      return ApproveResult(success: true, record: record);
    }

    final appState = hiveService.getAppState();

    try {
      final success = await paymentApi.approvePayment(
        baseUrl: appState.baseUrl,
        approveApiUrl: appState.approveApiUrl,
        paymentId: paymentId,
        txnId: record.txnId,
      );

      record.attempts += 1;
      if (success) {
        record.status = 'approved';
        record.approvedAt = DateTime.now();
        record.approvedBy = isManual ? 'manual' : 'auto';
        record.failReason = null;
        await hiveService.updateSmsRecord(record);
        AppLogger.instance.success(
          'APPROVE',
          'Approved Trx: ${record.txnId} (৳${record.amount.toStringAsFixed(0)}) [${isManual ? "MANUAL" : "AUTO"}]',
        );
        return ApproveResult(success: true, record: record);
      } else {
        record.status = 'failed';
        record.failReason = 'Server rejected approval';
        await hiveService.updateSmsRecord(record);
        AppLogger.instance.error(
          'APPROVE',
          'Server rejected approval for Trx: ${record.txnId}',
        );
        return ApproveResult(
          success: false,
          errorMessage: 'Server rejected approval',
          record: record,
        );
      }
    } catch (e) {
      record.attempts += 1;
      record.status = 'failed';
      record.failReason = e.toString();
      await hiveService.updateSmsRecord(record);
      AppLogger.instance.error(
        'APPROVE',
        'Approve failed for Trx: ${record.txnId}',
        e,
      );
      return ApproveResult(
        success: false,
        errorMessage: e.toString(),
        record: record,
      );
    }
  }

  /// Retries failed records with attempts < 5 sequentially
  Future<int> retryFailedRecords() async {
    final box = hiveService.getSmsBox();
    final failedRecords = box.values
        .where((r) =>
            r.status == 'failed' &&
            r.attempts < 5 &&
            r.matchedPaymentId != null &&
            r.matchedPaymentId!.isNotEmpty)
        .toList();

    int retriedSuccess = 0;
    for (final record in failedRecords) {
      final res = await approve(
        smsRecordId: record.id,
        paymentId: record.matchedPaymentId!,
        isManual: false,
      );
      if (res.success) {
        retriedSuccess++;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return retriedSuccess;
  }
}
