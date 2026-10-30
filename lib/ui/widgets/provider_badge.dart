import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ProviderBadge extends StatelessWidget {
  final String provider;

  const ProviderBadge({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isBkash = provider.toLowerCase().contains('bkash');
    final isNagad = provider.toLowerCase().contains('nagad');

    final color = isBkash
        ? AppColors.bkashPink
        : isNagad
            ? AppColors.nagadOrange
            : Colors.grey.shade700;

    final label = isBkash
        ? 'bKash'
        : isNagad
            ? 'Nagad'
            : provider.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
