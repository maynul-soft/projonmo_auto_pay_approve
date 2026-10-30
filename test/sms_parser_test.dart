import 'package:flutter_test/flutter_test.dart';
import 'package:payment_auto_approver/data/sms/parsers/bkash_parser.dart';
import 'package:payment_auto_approver/data/sms/parsers/nagad_parser.dart';

void main() {
  group('NagadCashOutParser Tests', () {
    final parser = NagadCashOutParser();

    test('Parses Section 3.1 real Nagad Cash Out SMS accurately', () {
      const smsBody = '''Cash Out Received.
Amount: Tk 8900.00
Customer: 0182***5031
TxnID: 766T57YC
Comm: Tk 36.49
Balance: Tk 56331.66
22/10/2026 16:50''';

      final receivedAt = DateTime(2026, 10, 22, 16, 51);
      expect(parser.canParse('NAGAD', smsBody), isTrue);

      final result = parser.parse('NAGAD', smsBody, receivedAt);
      expect(result, isNotNull);
      expect(result!.provider, 'nagad');
      expect(result.amount, 8900.00);
      expect(result.customer, '0182***5031');
      expect(result.txnId, '766T57YC');
      expect(result.commission, 36.49);
      expect(result.balance, 56331.66);
      expect(result.smsDateTime, DateTime(2026, 10, 22, 16, 50));
    });
  });

  group('BkashCashOutParser Tests', () {
    final parser = BkashCashOutParser();

    test('Parses Section 3.2 real bKash Cash Out SMS accurately', () {
      const smsBody =
          'Cash Out Tk 1,000.00 from 0133XXXX032 successful. Fee Tk 0.00. Balance Tk 223,849.23. TrxID DJP4HZUWF0 at 25/10/2026 07:46';

      final receivedAt = DateTime(2026, 10, 25, 7, 47);
      expect(parser.canParse('bKash', smsBody), isTrue);

      final result = parser.parse('bKash', smsBody, receivedAt);
      expect(result, isNotNull);
      expect(result!.provider, 'bkash');
      expect(result.amount, 1000.00);
      expect(result.customer, '0133XXXX032');
      expect(result.fee, 0.00);
      expect(result.balance, 223849.23);
      expect(result.txnId, 'DJP4HZUWF0');
      expect(result.smsDateTime, DateTime(2026, 10, 25, 7, 46));
    });

    test('Parses bKash 2 taka received SMS accurately', () {
      const smsBody =
          'You have received Tk 2.00 from 01712345678. Fee Tk 0.00. Balance Tk 502.00. TrxID BKA2TK99 at 30/10/2026 15:30';

      final receivedAt = DateTime(2026, 10, 30, 15, 31);
      expect(parser.canParse('16247', smsBody), isTrue);

      final result = parser.parse('16247', smsBody, receivedAt);
      expect(result, isNotNull);
      expect(result!.provider, 'bkash');
      expect(result.amount, 2.00);
      expect(result.customer, '01712345678');
      expect(result.txnId, 'BKA2TK99');
    });
  });
}
