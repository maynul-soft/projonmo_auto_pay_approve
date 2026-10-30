class PendingPayment {
  final String paymentId;
  final String txnId; // normalized (uppercase & trimmed)
  final double amount;
  final String? customer;
  final String? method;
  final DateTime? createdAt;
  final String? rawJson;
  final DateTime lastFetchedAt;

  PendingPayment({
    required this.paymentId,
    required this.txnId,
    required this.amount,
    this.customer,
    this.method,
    this.createdAt,
    this.rawJson,
    required this.lastFetchedAt,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final dateStr =
        json['submittedAt'] ?? json['created_at'] ?? json['createdAt'];
    if (dateStr != null) {
      try {
        parsedDate =
            DateTime.tryParse(dateStr.toString().replaceAll(' ', 'T'));
      } catch (_) {}
    }

    final rawAmount = json['amount'];
    double parsedAmount = 0.0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount =
          double.tryParse(rawAmount.replaceAll(',', '').trim()) ?? 0.0;
    }

    final rawTxnId =
        json['txnId'] ?? json['transaction_id'] ?? json['txId'] ?? '';
    final rawCustomer = json['mobile'] ?? json['customer'] ?? json['phone'];

    return PendingPayment(
      paymentId: json['id']?.toString() ?? '',
      txnId: rawTxnId.toString().trim().toUpperCase(),
      amount: parsedAmount,
      customer: rawCustomer?.toString(),
      method: json['method']?.toString().toLowerCase(),
      createdAt: parsedDate,
      rawJson: json.toString(),
      lastFetchedAt: DateTime.now(),
    );
  }

  PendingPayment copyWith({
    String? paymentId,
    String? txnId,
    double? amount,
    String? customer,
    String? method,
    DateTime? createdAt,
    String? rawJson,
    DateTime? lastFetchedAt,
  }) {
    return PendingPayment(
      paymentId: paymentId ?? this.paymentId,
      txnId: txnId ?? this.txnId,
      amount: amount ?? this.amount,
      customer: customer ?? this.customer,
      method: method ?? this.method,
      createdAt: createdAt ?? this.createdAt,
      rawJson: rawJson ?? this.rawJson,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}
