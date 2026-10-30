import 'package:intl/intl.dart';
import 'sms_parser.dart';

class BkashCashOutParser implements SmsParser {
  // Matches "Cash Out Tk 500", "You have received Tk 500", "Received Tk 500", "Cash In Tk 500", or generic "Tk 500"
  static final RegExp _amountRegex = RegExp(
    r'(?:Cash Out|received|Cash In|Payment|Amount:?)?\s*Tk\.?\s*([\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _customerRegex = RegExp(
    r'(?:from|Customer:?)\s*([0-9A-Za-z\*\+Xx\-_]+)',
    caseSensitive: false,
  );

  static final RegExp _txnIdRegex = RegExp(
    r'(?:TrxID|TxnID|Trx\s*ID|Txn\s*ID)[:\s]*([A-Za-z0-9]+)',
    caseSensitive: false,
  );

  static final RegExp _feeRegex = RegExp(
    r'Fee\s*Tk\.?\s*([\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _balanceRegex = RegExp(
    r'Balance\s*Tk\.?\s*([\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _dateRegex = RegExp(
    r'(\d{2}[/-]\d{2}[/-]\d{4}\s+\d{2}:\d{2})',
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  bool canParse(String sender, String body) {
    final lowerSender = sender.toLowerCase();
    final lowerBody = body.toLowerCase();

    final isBkashSender =
        lowerSender.contains('bkash') || lowerSender.contains('16247');
    final hasBkashKeywords = lowerBody.contains('bkash') ||
        lowerBody.contains('cash out') ||
        lowerBody.contains('you have received') ||
        lowerBody.contains('received tk') ||
        lowerBody.contains('cash in');
    final hasTrx = lowerBody.contains('trxid') ||
        lowerBody.contains('trx id') ||
        lowerBody.contains('txnid');
    final hasTk = lowerBody.contains('tk');

    return (isBkashSender || hasBkashKeywords) && hasTrx && hasTk;
  }

  @override
  ParsedSms? parse(String sender, String body, DateTime receivedAt) {
    if (!canParse(sender, body)) return null;

    final txnIdMatch = _txnIdRegex.firstMatch(body);
    if (txnIdMatch == null) return null;
    final txnId = txnIdMatch.group(1)!.trim().toUpperCase();

    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;
    final rawAmount = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmount) ?? 0.0;
    if (amount <= 0) return null;

    final customerMatch = _customerRegex.firstMatch(body);
    final customer = customerMatch != null
        ? customerMatch.group(1)!.trim().replaceAll(RegExp(r'[\.,;:]$'), '')
        : 'Customer';

    final feeMatch = _feeRegex.firstMatch(body);
    double? fee;
    if (feeMatch != null) {
      fee = double.tryParse(feeMatch.group(1)!.replaceAll(',', ''));
    }

    final balanceMatch = _balanceRegex.firstMatch(body);
    double? balance;
    if (balanceMatch != null) {
      balance = double.tryParse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    DateTime smsDateTime = receivedAt;
    final dateMatch = _dateRegex.firstMatch(body);
    if (dateMatch != null) {
      try {
        final dateStr = dateMatch.group(1)!.replaceAll('-', '/');
        smsDateTime = _dateFormat.parse(dateStr);
      } catch (_) {}
    }

    return ParsedSms(
      provider: 'bkash',
      sender: sender,
      rawBody: body,
      txnId: txnId,
      amount: amount,
      customer: customer,
      fee: fee,
      balance: balance,
      smsDateTime: smsDateTime,
      receivedAt: receivedAt,
    );
  }
}
