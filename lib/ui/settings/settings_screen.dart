import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';
import '../login/login_screen.dart';
import '../logs/app_logs_screen.dart';
import '../permission_setup/permission_setup_screen.dart';
import '../sync_logs/sync_logs_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _pendingUrlController = TextEditingController();
  final _approveUrlController = TextEditingController();
  final _intervalController = TextEditingController();
  final _sendersController = TextEditingController();
  final _scanDaysController = TextEditingController();

  bool _initialized = false;
  bool _isApiLocked = true;
  Timer? _holdTimer;
  Timer? _tickTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsCubit>().loadSettings();
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _tickTimer?.cancel();
    _baseUrlController.dispose();
    _pendingUrlController.dispose();
    _approveUrlController.dispose();
    _intervalController.dispose();
    _sendersController.dispose();
    _scanDaysController.dispose();
    super.dispose();
  }

  void _startHoldToUnlock() {
    if (!_isApiLocked) return;
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    const totalMs = 3000;
    const intervalMs = 50;
    int elapsed = 0;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (t) {
      elapsed += intervalMs;
      if (mounted) {
        setState(() {
          _holdProgress = (elapsed / totalMs).clamp(0.0, 1.0);
        });
      }
      if (elapsed >= totalMs) {
        t.cancel();
      }
    });

    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: totalMs), () {
      if (mounted) {
        setState(() {
          _isHolding = false;
          _holdProgress = 0.0;
        });
        HapticFeedback.heavyImpact();
        _showUnlockWarningDialog();
      }
    });
  }

  void _cancelHoldToUnlock() {
    if (!_isHolding) return;
    _holdTimer?.cancel();
    _tickTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _showUnlockWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text('Security Warning'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'API Configuration পরিবর্তন করলে নিম্নলিখিত সমস্যাগুলো হতে পারে:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 10),
              Text('• Server Connection বিচ্ছিন্ন হতে পারে।'),
              Text('• Pending Payment ডাটা ফেচ হবে না।'),
              Text('• SMS আসলে Auto-Approve ব্যর্থ হতে পারে।'),
              Text('• Token ও Auth ভ্যালিডেশন ফেইল করতে পারে।'),
              SizedBox(height: 14),
              Text(
                'সতর্কতা: শুধুমাত্র সিস্টেম অ্যাডমিনের নির্দেশনায় এটি পরিবর্তন করুন।',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel / বাতিল'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isApiLocked = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ API Configuration unlocked for editing.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Unlock Anyway / আনলক করুন'),
            ),
          ],
        );
      },
    );
  }

  void _syncControllers(SettingsState state) {
    if (!_initialized) {
      _baseUrlController.text = state.appState.baseUrl;
      _pendingUrlController.text = state.appState.pendingApiUrl;
      _approveUrlController.text = state.appState.approveApiUrl;
      _intervalController.text = state.appState.syncIntervalMinutes.toString();
      _sendersController.text = state.appState.senderIds.join(', ');
      _scanDaysController.text = state.appState.initialScanDays.toString();
      _initialized = true;
    }
  }

  void _saveSettings(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final current = cubit.state.appState;

    final parsedInterval = int.tryParse(_intervalController.text.trim()) ?? 5;
    final parsedDays = int.tryParse(_scanDaysController.text.trim()) ?? 2;
    final parsedSenders = _sendersController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = current.copyWith(
      baseUrl: _baseUrlController.text.trim(),
      pendingApiUrl: _pendingUrlController.text.trim(),
      approveApiUrl: _approveUrlController.text.trim(),
      syncIntervalMinutes: parsedInterval < 1 ? 1 : parsedInterval,
      initialScanDays: parsedDays,
      senderIds: parsedSenders.isEmpty ? current.senderIds : parsedSenders,
    );

    cubit.updateSettings(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    bool keepData = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to log out?'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Keep local SMS data?'),
                    subtitle: const Text('Background SMS capture will continue'),
                    value: keepData,
                    onChanged: (val) {
                      setState(() {
                        keepData = val ?? true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await context
                        .read<AuthCubit>()
                        .logout(keepLocalSms: keepData);
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClearOldRecordsDialog(BuildContext context) {
    final controller = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear Synced Old Records'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delete approved SMS records older than:'),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days',
                  suffixText: 'days',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final days = int.tryParse(controller.text) ?? 30;
                Navigator.of(ctx).pop();
                final count =
                    await context.read<SettingsCubit>().clearOldRecords(days);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cleared $count old records.')),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('⚠️ Clear All Data'),
          content: const Text(
            'This will permanently delete all captured SMS, cached pending payments, and sync logs from the device.\n\nAre you sure?',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<SettingsCubit>().clearAllData();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local data cleared.')),
                );
              },
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }

  void _showCsvExportDialog(BuildContext context, String csv) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Exported CSV Data'),
          content: SingleChildScrollView(
            child: Text(
              csv.length > 500 ? '${csv.substring(0, 500)}...\n[truncated]' : csv,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard!')),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.exportedCsvString != null) {
          _showCsvExportDialog(context, state.exportedCsvString!);
        }
      },
      builder: (context, state) {
        _syncControllers(state);
        final cubit = context.read<SettingsCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Settings',
                onPressed: () => _saveSettings(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Admin Account Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF0284C7),
                        backgroundImage: AssetImage('assets/images/logo.jpeg'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (state.adminName == null ||
                                      state.adminName!
                                          .toLowerCase()
                                          .contains('tecq'))
                                  ? 'Projonmo Admin'
                                  : state.adminName!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Role: ${state.adminRole ?? "admin"} (Active)',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // API Endpoints
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'API Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  _isApiLocked
                      ? GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔒 Press and hold for 3 seconds to unlock API settings.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          onTapDown: (_) => _startHoldToUnlock(),
                          onTapUp: (_) => _cancelHoldToUnlock(),
                          onTapCancel: () => _cancelHoldToUnlock(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isHolding ? Colors.amber.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isHolding ? Colors.amber.shade700 : Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isHolding)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      value: _holdProgress,
                                      strokeWidth: 2.2,
                                      color: Colors.amber.shade900,
                                    ),
                                  )
                                else
                                  const Icon(Icons.lock, size: 14, color: Colors.black87),
                                const SizedBox(width: 6),
                                Text(
                                  _isHolding
                                      ? 'Hold ${(3.0 * (1.0 - _holdProgress)).toStringAsFixed(1)}s...'
                                      : 'Locked (Hold 3s)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isHolding ? Colors.amber.shade900 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _isApiLocked = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API Configuration locked.')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_open, size: 14, color: Colors.red),
                                SizedBox(width: 6),
                                Text(
                                  'Unlocked (Tap to Lock)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
              if (!_isApiLocked) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Editing unlocked. Incorrect API URLs will break auto-approvals and server sync.',
                          style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrlController,
                enabled: !_isApiLocked,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.projonmo.tech/api/v1',
                  prefixIcon: const Icon(Icons.language),
                  filled: _isApiLocked,
                  fillColor: _isApiLocked ? Colors.grey.shade100 : null,
                  suffixIcon: _isApiLocked ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pendingUrlController,
                enabled: !_isApiLocked,
                decoration: InputDecoration(
                  labelText: 'Pending API Path / URL',
                  prefixIcon: const Icon(Icons.list_alt),
                  filled: _isApiLocked,
                  fillColor: _isApiLocked ? Colors.grey.shade100 : null,
                  suffixIcon: _isApiLocked ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _approveUrlController,
                enabled: !_isApiLocked,
                decoration: InputDecoration(
                  labelText: 'Approve API Path / URL',
                  hintText: '/admin/deposits/:id/review',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  filled: _isApiLocked,
                  fillColor: _isApiLocked ? Colors.grey.shade100 : null,
                  suffixIcon: _isApiLocked ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 10),

              // Test Connection Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade900,
                ),
                onPressed:
                    state.isTestingConnection ? null : cubit.testConnection,
                icon: state.isTestingConnection
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check, size: 18),
                label: const Text('Test Connection'),
              ),
              if (state.testConnectionResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.testConnectionResult!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: state.testConnectionResult!.startsWith('Success')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Sync & Automation Settings
              const Text('Sync & Matching Rules',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Auto-Approve'),
                subtitle: const Text('Automatically call Approve API when SMS matches'),
                value: state.appState.autoApprove,
                onChanged: (val) {
                  cubit.updateSettings(state.appState.copyWith(autoApprove: val));
                },
              ),
              SwitchListTile(
                title: const Text('Strict Amount Check'),
                subtitle: const Text('Flag as Amount Mismatch if SMS and server amounts differ'),
                value: state.appState.strictAmountCheck,
                onChanged: (val) {
                  cubit.updateSettings(
                      state.appState.copyWith(strictAmountCheck: val));
                },
              ),
              SwitchListTile(
                title: const Text('Allow Force Approve'),
                subtitle: const Text('Show approve option for payments with no matching SMS'),
                value: state.appState.allowForceApprove,
                onChanged: (val) {
                  cubit.updateSettings(
                      state.appState.copyWith(allowForceApprove: val));
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sync Interval (Min)',
                        suffixText: 'min',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _scanDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Scan Days',
                        suffixText: 'days',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sendersController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Sender IDs (comma-separated)',
                  hintText: 'bKash, NAGAD, 16167, 16216',
                ),
              ),
              const SizedBox(height: 20),

              // Navigation & System Shortcuts
              const Text('Shortcuts & Utilities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Color(0xFF0284C7)),
                title: const Text('Live Activity Logs'),
                subtitle: const Text('Color-coded real-time logs (API, SMS, Matching, Sync)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppLogsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Sync Logs'),
                subtitle: const Text('View history of recent sync executions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SyncLogsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.phonelink_setup),
                title: const Text('Permissions & Battery Setup'),
                subtitle: const Text('Re-check SMS, notification and battery settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionSetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Data Management
              const Text('Data Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export SMS Records as CSV'),
                onTap: () => cubit.exportCsv(),
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: const Text('Clear Synced Old Records'),
                onTap: () => _showClearOldRecordsDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Local Data',
                    style: TextStyle(color: Colors.red)),
                onTap: () => _showClearAllDataDialog(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
