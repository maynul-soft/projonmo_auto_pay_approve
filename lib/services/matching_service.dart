import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';
import '../data/hive/hive_service.dart';
import '../data/models/pending_payment.dart';
import '../data/models/sms_record.dart';

class MatchResult {
  final SmsRecord record;
  final PendingPayment pending;
  final bool isAmountMismatch;

  MatchResult({
    required this.record,
    required this.pending,
    required this.isAmountMismatch,
  });
}

class MatchingService {
  final HiveService hiveService;

  MatchingService({HiveService? hiveService})
      : hiveService = hiveService ?? HiveService.instance;

  Future<List<MatchResult>> matchPendingList(List<PendingPayment> pendingList) async {
    final appState = hiveService.getAppState();
    final results = <MatchResult>[];
    final processedTxnIds = <String>{};

    for (final pending in pendingList) {
      final normTxnId = pending.txnId.trim().toUpperCase();

      if (processedTxnIds.contains(normTxnId)) {
        debugPrint('MatchingService: duplicate txnId in pending list: $normTxnId');
        continue;
      }
      processedTxnIds.add(normTxnId);

      final sms = hiveService.findSmsByTxnId(normTxnId);
      if (sms == null) {
        // No SMS yet
        continue;
      }

      if (sms.status == 'approved') {
        // Never approve twice
        continue;
      }

      // Check method/provider match if server provided method
      if (pending.method != null && pending.method!.isNotEmpty) {
        final prov = sms.provider.toLowerCase();
        final meth = pending.method!.toLowerCase();
        if (!prov.contains(meth) && !meth.contains(prov)) {
          debugPrint('MatchingService: provider mismatch for $normTxnId (SMS: $prov, Pending: $meth)');
        }
      }

      // Compare amounts with 0.01 tolerance
      final isMismatch = (sms.amount - pending.amount).abs() > 0.01;
      if (appState.strictAmountCheck && isMismatch) {
        sms.status = 'amount_mismatch';
        sms.matchedPaymentId = pending.paymentId;
        await hiveService.updateSmsRecord(sms);
        results.add(MatchResult(record: sms, pending: pending, isAmountMismatch: true));
        AppLogger.instance.warning(
          'MATCH',
          'Mismatch ${sms.txnId}: SMS=৳${sms.amount} vs Server=৳${pending.amount}',
        );
        continue;
      }

      sms.status = 'matched';
      sms.matchedPaymentId = pending.paymentId;
      await hiveService.updateSmsRecord(sms);
      results.add(MatchResult(record: sms, pending: pending, isAmountMismatch: false));
      AppLogger.instance.info(
        'MATCH',
        'Matched Trx: ${sms.txnId} (৳${sms.amount.toStringAsFixed(0)})',
      );
    }

    return results;
  }
}
