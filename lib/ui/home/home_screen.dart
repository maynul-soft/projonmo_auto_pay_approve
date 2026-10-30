import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/home/home_cubit.dart';
import '../../cubits/home/home_state.dart';
import '../logs/app_logs_screen.dart';
import '../login/login_screen.dart';
import '../widgets/amount_text.dart';
import '../widgets/provider_badge.dart';
import '../widgets/status_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeCubit>().loadDashboardData();
      }
    });
  }

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return '৳ ${amount.toInt()}';
    }
    return '৳ ${amount.toStringAsFixed(2)}';
  }

  String _formatTimeAgo(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isSessionExpired = authState is AuthExpired;

        return BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final cubit = context.read<HomeCubit>();

            return Scaffold(
              appBar: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: const Text('Dashboard'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'Activity Logs',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppLogsScreen()),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.circle,
                        size: 10,
                        color: state.isBackgroundServiceRunning
                            ? Colors.green
                            : Colors.red,
                      ),
                      label: Text(
                        state.isBackgroundServiceRunning ? 'Running' : 'Stopped',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => cubit.toggleBackgroundService(),
                    ),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: cubit.syncNow,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Red Session Expired Banner
                    if (isSessionExpired) ...[
                      Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Session expired. Login again to enable approvals.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Top Card: Last SMS Read
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.sms, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last SMS Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.lastSmsReadAt != null
                                        ? dateFormat.format(state.lastSmsReadAt!)
                                        : 'No SMS read yet',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatTimeAgo(state.lastSmsReadAt),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Last Sync Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: state.lastSyncStatus == 'success'
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                state.lastSyncStatus == 'success'
                                    ? Icons.sync
                                    : Icons.sync_problem,
                                color: state.lastSyncStatus == 'success'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Sync Result',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.lastSyncAt != null
                                        ? '${dateFormat.format(state.lastSyncAt!)} (${state.lastSyncStatus ?? 'unknown'})'
                                        : 'No sync yet',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (state.lastSyncMessage != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      state.lastSyncMessage!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sync Now Button
                    ElevatedButton.icon(
                      onPressed: state.isSyncing ? null : cubit.syncNow,
                      icon: state.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        state.isSyncing ? 'Syncing...' : 'Sync Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Counters Grid
                    const Text(
                      "Today's Overview",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox(
                          'Today SMS',
                          '${state.todayStats.smsRead}',
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Today Amount',
                          _formatAmount(state.todayStats.totalAmount),
                          Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Approved',
                          '${state.todayStats.approved}',
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBox(
                          'Unmatched',
                          '${state.todayStats.unmatched}',
                          Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Failed',
                          '${state.todayStats.failed}',
                          Colors.red,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Total Amount',
                          _formatAmount(state.totalStats.totalAmount),
                          Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Latest 5 SMS Records
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent SMS Records',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Latest 5',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (state.latestRecords.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No SMS captured yet.\nUse "Read SMS from phone" in the SMS tab or wait for incoming messages.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.latestRecords.map((r) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ProviderBadge(provider: r.provider),
                              title: Row(
                                children: [
                                  AmountText(amount: r.amount),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.txnId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${r.customer} • ${dateFormat.format(r.smsDateTime)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: StatusChip(status: r.status),
                            ),
                          )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade100),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.shade900,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
