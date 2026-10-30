import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##,##0.00');
    final formatted = formatter.format(amount);

    return Text(
      '৳ $formatted',
      style: style ??
          const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
    );
  }
}
