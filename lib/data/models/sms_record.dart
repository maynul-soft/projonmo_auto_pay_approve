class SmsRecord {
  final String id; // provider_txnId
  final String provider; // 'bkash' or 'nagad'
  final String sender;
  final String rawBody;
  final String txnId; // normalized (uppercase & trimmed)
  final double amount;
  final String customer;
  final double? fee;
  final double? commission;
  final double? balance;
  final DateTime smsDateTime;
  final DateTime receivedAt;
  String status; // 'unmatched', 'matched', 'approved', 'failed', 'amount_mismatch'
  String? matchedPaymentId;
  DateTime? approvedAt;
  String? failReason;
  int attempts;
  String? approvedBy; // 'auto' or 'manual'

  SmsRecord({
    required this.id,
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
    this.status = 'unmatched',
    this.matchedPaymentId,
    this.approvedAt,
    this.failReason,
    this.attempts = 0,
    this.approvedBy,
  });

  SmsRecord copyWith({
    String? id,
    String? provider,
    String? sender,
    String? rawBody,
    String? txnId,
    double? amount,
    String? customer,
    double? fee,
    double? commission,
    double? balance,
    DateTime? smsDateTime,
    DateTime? receivedAt,
    String? status,
    String? matchedPaymentId,
    DateTime? approvedAt,
    String? failReason,
    int? attempts,
    String? approvedBy,
  }) {
    return SmsRecord(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      sender: sender ?? this.sender,
      rawBody: rawBody ?? this.rawBody,
      txnId: txnId ?? this.txnId,
      amount: amount ?? this.amount,
      customer: customer ?? this.customer,
      fee: fee ?? this.fee,
      commission: commission ?? this.commission,
      balance: balance ?? this.balance,
      smsDateTime: smsDateTime ?? this.smsDateTime,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
      matchedPaymentId: matchedPaymentId ?? this.matchedPaymentId,
      approvedAt: approvedAt ?? this.approvedAt,
      failReason: failReason ?? this.failReason,
      attempts: attempts ?? this.attempts,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}
