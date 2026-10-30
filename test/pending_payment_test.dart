import 'package:flutter_test/flutter_test.dart';
import 'package:payment_auto_approver/data/models/pending_payment.dart';

void main() {
  test('Parses real backend pending deposit JSON correctly', () {
    final json = {
      "id": "deposit_id_123",
      "userId": "user_id_456",
      "mobile": "017XXXXXXXX",
      "amount": 500,
      "method": "bKash",
      "txnId": "TXN123456",
      "proofUrl": "https://example.com/proof.jpg",
      "submittedAt": "2026-10-30 10:15:00",
      "status": "Pending"
    };

    final payment = PendingPayment.fromJson(json);

    expect(payment.paymentId, 'deposit_id_123');
    expect(payment.txnId, 'TXN123456');
    expect(payment.amount, 500.0);
    expect(payment.customer, '017XXXXXXXX');
    expect(payment.method, 'bkash');
    expect(payment.createdAt, DateTime(2026, 10, 30, 10, 15, 0));
  });
}
