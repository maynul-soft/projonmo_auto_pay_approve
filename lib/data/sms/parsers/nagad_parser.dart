import 'package:intl/intl.dart';
import 'sms_parser.dart';

class NagadCashOutParser implements SmsParser {
  static final RegExp _amountRegex = RegExp(
    r'(?:Amount:\s*)?Tk\.?\s*([\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );
  static final RegExp _customerRegex = RegExp(
    r'(?:Customer|from):\s*([0-9A-Za-z\*\+Xx\-_]+)',
    caseSensitive: false,
  );
  static final RegExp _txnIdRegex = RegExp(
    r'(?:TxnID|TrxID|Txn\s*ID|Trx\s*ID):\s*([A-Za-z0-9]+)',
    caseSensitive: false,
  );
  static final RegExp _commRegex = RegExp(
    r'Comm:\s*Tk\.?\s*([\d,]+(?:\.\d+)?)',
    caseSensitive: false,
  );
  static final RegExp _balanceRegex = RegExp(
    r'Balance:\s*Tk\.?\s*([\d,]+(?:\.\d+)?)',
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

    final isNagadSender =
        lowerSender.contains('nagad') || lowerSender.contains('16167');
    final hasNagadKeywords = lowerBody.contains('nagad') ||
        lowerBody.contains('cash out') ||
        lowerBody.contains('money received') ||
        lowerBody.contains('cash in');
    final hasTrx = lowerBody.contains('txnid') ||
        lowerBody.contains('trxid') ||
        lowerBody.contains('txn id');
    final hasTk = lowerBody.contains('tk');

    return (isNagadSender || hasNagadKeywords) && hasTrx && hasTk;
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

    final commMatch = _commRegex.firstMatch(body);
    double? commission;
    if (commMatch != null) {
      commission = double.tryParse(commMatch.group(1)!.replaceAll(',', ''));
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
      provider: 'nagad',
      sender: sender,
      rawBody: body,
      txnId: txnId,
      amount: amount,
      customer: customer,
      commission: commission,
      balance: balance,
      smsDateTime: smsDateTime,
      receivedAt: receivedAt,
    );
  }
}
