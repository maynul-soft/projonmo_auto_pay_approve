import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/sms_records/sms_records_cubit.dart';
import '../../cubits/sms_records/sms_records_state.dart';
import '../../data/models/sms_record.dart';
import '../widgets/amount_text.dart';
import '../widgets/provider_badge.dart';
import '../widgets/status_chip.dart';

class SmsRecordsScreen extends StatefulWidget {
  const SmsRecordsScreen({super.key});

  @override
  State<SmsRecordsScreen> createState() => _SmsRecordsScreenState();
}

class _SmsRecordsScreenState extends State<SmsRecordsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SmsRecordsCubit>().loadRecords();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showScanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Read SMS from Phone'),
          content: const Text(
            'Select how far back to scan the phone inbox for bKash and Nagad SMS:',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runScan(0); // Today
              },
              child: const Text('Today'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runScan(3);
              },
              child: const Text('3 Days'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runScan(7);
              },
              child: const Text('7 Days'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runScan(30);
              },
              child: const Text('30 Days'),
            ),
          ],
        );
      },
    );
  }

  void _runScan(int days) async {
    final cubit = context.read<SmsRecordsCubit>();
    final count = await cubit.scanInboxFromPhone(customDays: days == 0 ? 1 : days);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inbox scan complete: $count new SMS saved')),
    );
  }

  void _showDetailBottomSheet(BuildContext context, SmsRecord record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProviderBadge(provider: record.provider),
                  StatusChip(status: record.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AmountText(
                    amount: record.amount,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'TxnID: ${record.txnId}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: record.txnId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Customer', record.customer),
              _buildDetailRow('Sender ID', record.sender),
              if (record.fee != null)
                _buildDetailRow('Fee', '৳ ${record.fee!.toStringAsFixed(2)}'),
              if (record.commission != null)
                _buildDetailRow(
                    'Commission', '৳ ${record.commission!.toStringAsFixed(2)}'),
              if (record.balance != null)
                _buildDetailRow(
                    'Remaining Balance', '৳ ${record.balance!.toStringAsFixed(2)}'),
              _buildDetailRow('SMS Timestamp', dateFormat.format(record.smsDateTime)),
              _buildDetailRow('Device Received', dateFormat.format(record.receivedAt)),
              if (record.matchedPaymentId != null)
                _buildDetailRow('Matched Server ID', record.matchedPaymentId!),
              if (record.approvedAt != null)
                _buildDetailRow('Approved At', dateFormat.format(record.approvedAt!)),
              if (record.approvedBy != null)
                _buildDetailRow('Approved By', record.approvedBy!),
              _buildDetailRow('Approve Attempts', '${record.attempts}'),
              if (record.failReason != null)
                _buildDetailRow('Failure Reason', record.failReason!,
                    isError: true),
              const SizedBox(height: 12),
              const Text(
                'Raw SMS Text:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.rawBody,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return BlocBuilder<SmsRecordsCubit, SmsRecordsState>(
      builder: (context, state) {
        final cubit = context.read<SmsRecordsCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('SMS Records'),
            actions: [
              IconButton(
                icon: state.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                tooltip: 'Read SMS from phone',
                onPressed: state.isScanning ? null : () => _showScanDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by TxnID or Amount...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              cubit.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: cubit.setSearchQuery,
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Provider Filters
                    ChoiceChip(
                      label: const Text('All Providers'),
                      selected: state.providerFilter == 'all',
                      onSelected: (_) => cubit.setProviderFilter('all'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('bKash'),
                      selected: state.providerFilter == 'bkash',
                      onSelected: (_) => cubit.setProviderFilter('bkash'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Nagad'),
                      selected: state.providerFilter == 'nagad',
                      onSelected: (_) => cubit.setProviderFilter('nagad'),
                    ),
                    const SizedBox(width: 12),
                    // Status Filters
                    ChoiceChip(
                      label: const Text('All Status'),
                      selected: state.statusFilter == 'all',
                      onSelected: (_) => cubit.setStatusFilter('all'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Unmatched'),
                      selected: state.statusFilter == 'unmatched',
                      onSelected: (_) => cubit.setStatusFilter('unmatched'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Matched'),
                      selected: state.statusFilter == 'matched',
                      onSelected: (_) => cubit.setStatusFilter('matched'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Approved'),
                      selected: state.statusFilter == 'approved',
                      onSelected: (_) => cubit.setStatusFilter('approved'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Failed'),
                      selected: state.statusFilter == 'failed',
                      onSelected: (_) => cubit.setStatusFilter('failed'),
                    ),
                  ],
                ),
              ),

              // Summary Info Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Count: ${state.filteredCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Total: ৳ ${state.filteredTotalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: state.filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                          state.allRecords.isEmpty
                              ? 'No SMS records found in database.'
                              : 'No SMS matching current filters.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: state.filteredRecords.length,
                        itemBuilder: (context, index) {
                          final r = state.filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _showDetailBottomSheet(context, r),
                              leading: ProviderBadge(provider: r.provider),
                              title: Row(
                                children: [
                                  AmountText(amount: r.amount),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.txnId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${r.customer} • ${dateFormat.format(r.smsDateTime)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: StatusChip(status: r.status),
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
