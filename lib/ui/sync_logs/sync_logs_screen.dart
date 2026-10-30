import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/sync_logs/sync_logs_cubit.dart';
import '../../cubits/sync_logs/sync_logs_state.dart';

class SyncLogsScreen extends StatefulWidget {
  const SyncLogsScreen({super.key});

  @override
  State<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends State<SyncLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SyncLogsCubit>().loadLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SyncLogsCubit>().loadLogs(),
          ),
        ],
      ),
      body: BlocBuilder<SyncLogsCubit, SyncLogsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.logs.isEmpty) {
            return const Center(
              child: Text(
                'No sync logs available yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.logs.length,
            itemBuilder: (context, index) {
              final log = state.logs[index];
              final hasError = log.error != null;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(
                    hasError ? Icons.error_outline : Icons.check_circle_outline,
                    color: hasError ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    dateFormat.format(log.startedAt),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Trigger: ${log.trigger} • Approved: ${log.approvedCount} • Matched: ${log.matchedCount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogRow('Trigger', log.trigger),
                          _buildLogRow('Started At', dateFormat.format(log.startedAt)),
                          if (log.finishedAt != null)
                            _buildLogRow('Finished At', dateFormat.format(log.finishedAt!)),
                          _buildLogRow('New SMS Saved', '${log.newSmsSaved}'),
                          _buildLogRow('Pending Fetched', '${log.pendingFetched}'),
                          _buildLogRow('Matched Count', '${log.matchedCount}'),
                          _buildLogRow('Approved Count', '${log.approvedCount}'),
                          _buildLogRow('Failed Count', '${log.failedCount}'),
                          if (hasError)
                            _buildLogRow('Error Details', log.error!, isError: true),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
