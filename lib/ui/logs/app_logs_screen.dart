import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_logger.dart';
import '../../cubits/app_logs/app_logs_cubit.dart';
import '../../cubits/app_logs/app_logs_state.dart';

class AppLogsScreen extends StatefulWidget {
  const AppLogsScreen({super.key});

  @override
  State<AppLogsScreen> createState() => _AppLogsScreenState();
}

class _AppLogsScreenState extends State<AppLogsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogDetail(BuildContext context, LogEntry entry) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

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
                  _buildTagBadge(entry.tag, entry.level),
                  Text(
                    dateFormat.format(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Summary:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              SelectableText(
                entry.message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (entry.details != null && entry.details!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Full Details / Payload:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      entry.details!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Log'),
                  onPressed: () {
                    final text =
                        '[${entry.timestamp}] [${entry.tag}] ${entry.message}\n${entry.details ?? ""}';
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log copied to clipboard')),
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

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red.shade700;
      case LogLevel.warning:
        return Colors.orange.shade800;
      case LogLevel.success:
        return Colors.green.shade700;
      case LogLevel.api:
        return Colors.blue.shade700;
      case LogLevel.info:
        return Colors.blueGrey.shade700;
    }
  }

  Color _getLevelBgColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red.shade50;
      case LogLevel.warning:
        return Colors.orange.shade50;
      case LogLevel.success:
        return Colors.green.shade50;
      case LogLevel.api:
        return Colors.blue.shade50;
      case LogLevel.info:
        return Colors.grey.shade50;
    }
  }

  Widget _buildTagBadge(String tag, LogLevel level) {
    final color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return BlocBuilder<AppLogsCubit, AppLogsState>(
      builder: (context, state) {
        final cubit = context.read<AppLogsCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text('Live Activity Logs (${state.filteredLogs.length})'),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all),
                tooltip: 'Copy All Logs',
                onPressed: () {
                  final text = cubit.exportLogsText();
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All logs copied to clipboard!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear Logs',
                onPressed: cubit.clearLogs,
              ),
            ],
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
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

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All', cubit, state.selectedFilter),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                        'ERROR', 'Errors Only', cubit, state.selectedFilter,
                        badgeColor: Colors.red),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                        'WARNING', 'Warnings', cubit, state.selectedFilter,
                        badgeColor: Colors.orange),
                    const SizedBox(width: 6),
                    _buildFilterChip('API', 'API', cubit, state.selectedFilter,
                        badgeColor: Colors.blue),
                    const SizedBox(width: 6),
                    _buildFilterChip('SMS', 'SMS', cubit, state.selectedFilter,
                        badgeColor: Colors.pink),
                    const SizedBox(width: 6),
                    _buildFilterChip('SYNC', 'Sync', cubit, state.selectedFilter,
                        badgeColor: Colors.teal),
                  ],
                ),
              ),

              const Divider(height: 8),

              // Logs List
              Expanded(
                child: state.filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs found for current filter.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: state.filteredLogs.length,
                        itemBuilder: (context, index) {
                          final item = state.filteredLogs[index];
                          final color = _getLevelColor(item.level);
                          final bg = _getLevelBgColor(item.level);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _showLogDetail(context, item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timestamp
                                    Text(
                                      timeFormat.format(item.timestamp),
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Tag
                                    _buildTagBadge(item.tag, item.level),
                                    const SizedBox(width: 8),

                                    // Message
                                    Expanded(
                                      child: Text(
                                        item.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),

                                    if (item.details != null &&
                                        item.details!.isNotEmpty)
                                      Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: color.withValues(alpha: 0.6),
                                      ),
                                  ],
                                ),
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

  Widget _buildFilterChip(
      String key, String label, AppLogsCubit cubit, String current,
      {Color? badgeColor}) {
    final isSelected = current == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => cubit.setFilter(key),
      selectedColor: badgeColor?.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected && badgeColor != null ? badgeColor : null,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
