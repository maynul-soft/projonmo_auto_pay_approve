import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/manual_approve/manual_approve_cubit.dart';
import '../../cubits/manual_approve/manual_approve_state.dart';
import '../widgets/amount_text.dart';
import '../widgets/provider_badge.dart';

class ManualApproveScreen extends StatefulWidget {
  const ManualApproveScreen({super.key});

  @override
  State<ManualApproveScreen> createState() => _ManualApproveScreenState();
}

class _ManualApproveScreenState extends State<ManualApproveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ManualApproveCubit>().loadPendingApprovals();
      }
    });
  }

  void _showApproveConfirmDialog(
      BuildContext context, ManualApproveItem item) {
    final cubit = context.read<ManualApproveCubit>();
    final isNoSms = item.smsRecord == null;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isNoSms ? '⚠️ Force Approve Warning' : 'Confirm Approval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNoSms)
                const Text(
                  'No matching SMS found for this transaction!\nAre you sure you want to force approve this payment?',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )
              else
                const Text('Approve the following transaction?'),
              const SizedBox(height: 12),
              Text('TxnID: ${item.pending.txnId}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Server Amount: ৳ ${item.pending.amount.toStringAsFixed(2)}'),
              if (item.smsRecord != null) ...[
                Text('SMS Amount: ৳ ${item.smsRecord!.amount.toStringAsFixed(2)}'),
                Text('Provider: ${item.smsRecord!.provider.toUpperCase()}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isNoSms ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                cubit.approveItem(item.pending.paymentId);
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkConfirmDialog(BuildContext context, int count) {
    final cubit = context.read<ManualApproveCubit>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Bulk Approval'),
          content: Text(
            'Are you sure you want to approve all $count selected transactions sequentially?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                cubit.approveSelected();
              },
              child: const Text('Approve All Selected'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');

    return BlocBuilder<ManualApproveCubit, ManualApproveState>(
      builder: (context, state) {
        final cubit = context.read<ManualApproveCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manual Approve'),
            actions: [
              if (state.selectedCount > 0)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  label: Text('Approve (${state.selectedCount})',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  onPressed: state.isBulkApproving
                      ? null
                      : () => _showBulkConfirmDialog(context, state.selectedCount),
                ),
            ],
          ),
          body: Column(
            children: [
              // Show All Pending Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Show all pending (including without SMS)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: state.showAllPending,
                      onChanged: cubit.toggleShowAllPending,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Items List
              Expanded(
                child: state.items.isEmpty
                    ? const Center(
                        child: Text(
                          'No pending payments needing manual approval.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final p = item.pending;
                          final sms = item.smsRecord;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: item.isSelected,
                                        onChanged: (_) =>
                                            cubit.toggleItemSelection(p.paymentId),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.txnId,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (sms != null)
                                              Text(
                                                'SMS Time: ${dateFormat.format(sms.smsDateTime)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (sms != null)
                                        ProviderBadge(provider: sms.provider),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Side by side amounts
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Text(
                                              'Server Amount',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                            AmountText(amount: p.amount),
                                          ],
                                        ),
                                        const Text('vs',
                                            style: TextStyle(color: Colors.grey)),
                                        Column(
                                          children: [
                                            const Text(
                                              'SMS Amount',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                            if (sms != null)
                                              AmountText(
                                                amount: sms.amount,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: (sms.amount - p.amount).abs() > 0.01
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              )
                                            else
                                              const Text('None',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (item.errorMessage != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Error: ${item.errorMessage}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ],

                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: item.isApproving
                                          ? null
                                          : () => _showApproveConfirmDialog(
                                              context, item),
                                      icon: item.isApproving
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.check, size: 16),
                                      label: Text(
                                        item.errorMessage != null
                                            ? 'Retry Approve'
                                            : 'Approve',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
