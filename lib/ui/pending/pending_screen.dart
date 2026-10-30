import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/pending/pending_cubit.dart';
import '../../cubits/pending/pending_state.dart';
import '../widgets/amount_text.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PendingCubit>().loadFromCache();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return BlocBuilder<PendingCubit, PendingState>(
      builder: (context, state) {
        final cubit = context.read<PendingCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pending Payments'),
            actions: [
              IconButton(
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: state.isLoading ? null : cubit.refreshFromApi,
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
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

              // Top Bar Summary
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Count: ${state.totalCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Total: ৳ ${state.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      state.lastFetchedAt != null
                          ? 'Fetched: ${DateFormat('HH:mm').format(state.lastFetchedAt!)}'
                          : 'Not fetched',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),

              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Pending Payments List
              Expanded(
                child: state.filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          state.allItems.isEmpty
                              ? 'No pending payments found.\nTap refresh button to fetch from server.'
                              : 'No payments matching search.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: state.filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = state.filteredItems[index];
                          final p = item.payment;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p.txnId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      _buildMatchBadge(item.matchStatus),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AmountText(amount: p.amount),
                                      if (p.createdAt != null)
                                        Text(
                                          dateFormat.format(p.createdAt!),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (p.customer != null &&
                                      p.customer!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Customer: ${p.customer}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (item.matchStatus ==
                                          PendingMatchStatus.amountMismatch &&
                                      item.smsAmount != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'SMS Amount: ৳ ${item.smsAmount!.toStringAsFixed(2)} (Mismatch)',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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

  Widget _buildMatchBadge(PendingMatchStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case PendingMatchStatus.matched:
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        label = 'Matched with SMS';
        break;
      case PendingMatchStatus.amountMismatch:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade900;
        label = 'Amount Mismatch';
        break;
      case PendingMatchStatus.noSms:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        label = 'No SMS yet';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
