import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = AppColors.statusApproved.withValues(alpha: 0.15);
        text = AppColors.statusApproved;
        label = 'Approved';
        break;
      case 'matched':
        bg = AppColors.statusMatched.withValues(alpha: 0.15);
        text = AppColors.statusMatched;
        label = 'Matched';
        break;
      case 'failed':
        bg = AppColors.statusFailed.withValues(alpha: 0.15);
        text = AppColors.statusFailed;
        label = 'Failed';
        break;
      case 'amount_mismatch':
        bg = AppColors.statusMismatch.withValues(alpha: 0.15);
        text = AppColors.statusMismatch;
        label = 'Amount Mismatch';
        break;
      case 'unmatched':
      default:
        bg = AppColors.statusUnmatched.withValues(alpha: 0.15);
        text = AppColors.statusUnmatched;
        label = 'Unmatched';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
