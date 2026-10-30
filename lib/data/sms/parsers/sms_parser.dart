import '../../models/sms_record.dart';

class ParsedSms {
  final String provider; // 'bkash' or 'nagad'
  final String sender;
  final String rawBody;
  final String txnId;
  final double amount;
  final String customer;
  final double? fee;
  final double? commission;
  final double? balance;
  final DateTime smsDateTime;
  final DateTime receivedAt;

  ParsedSms({
    required this.provider,
    required this.sender,
    required this.rawBody,
    required this.txnId,
    required this.amount,
    required this.customer,
    this.fee,
    this.commission,
    this.balance,
    required this.smsDateTime,
    required this.receivedAt,
  });

  SmsRecord toSmsRecord() {
    final normalizedTxnId = txnId.trim().toUpperCase();
    final normalizedProvider = provider.trim().toLowerCase();
    final id = '${normalizedProvider}_$normalizedTxnId';

    return SmsRecord(
      id: id,
      provider: normalizedProvider,
      sender: sender,
      rawBody: rawBody,
      txnId: normalizedTxnId,
      amount: amount,
      customer: customer,
      fee: fee,
      commission: commission,
      balance: balance,
      smsDateTime: smsDateTime,
      receivedAt: receivedAt,
      status: 'unmatched',
    );
  }
}

abstract class SmsParser {
  bool canParse(String sender, String body);
  ParsedSms? parse(String sender, String body, DateTime receivedAt);
}
