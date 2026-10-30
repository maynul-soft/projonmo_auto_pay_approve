import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/permission/permission_cubit.dart';
import '../../cubits/permission/permission_state.dart';
import '../navigation/main_navigation_screen.dart';

class PermissionSetupScreen extends StatefulWidget {
  final bool isFirstRun;

  const PermissionSetupScreen({super.key, this.isFirstRun = false});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PermissionCubit>().checkPermissions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionCubit, PermissionState>(
      builder: (context, state) {
        final cubit = context.read<PermissionCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Setup & Permissions'),
            automaticallyImplyLeading: !widget.isFirstRun,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Required Permissions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'The app needs these permissions to read transaction SMS in background and automatically approve payments.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Step 1: SMS Permission
              _buildPermissionTile(
                title: '1. SMS Permission',
                subtitle: 'Allows reading incoming bKash & Nagad SMS',
                isGranted: state.hasSms,
                onTap: cubit.requestSms,
              ),

              // Step 2: Notification Permission
              _buildPermissionTile(
                title: '2. Notifications (Android 13+)',
                subtitle: 'Keeps foreground service visible and notifies on alerts',
                isGranted: state.hasNotification,
                onTap: cubit.requestNotification,
              ),

              // Step 3: Battery Optimization
              _buildPermissionTile(
                title: '3. Disable Battery Optimization',
                subtitle: 'Prevents Android from killing background sync',
                isGranted: state.isBatteryIgnored,
                onTap: cubit.requestBatteryOptimization,
              ),

              // Step 4: OEM Autostart Guidance Card
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'OEM Autostart Guidance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'For Xiaomi (MIUI/HyperOS), Oppo, Vivo, Realme, Huawei, & Samsung phones:\n'
                        '• Enable "Autostart" for this app in Settings.\n'
                        '• Lock the app in Recent Apps (padlock icon).\n'
                        '• Set Battery Saver to "No restrictions".',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Open App Settings'),
                          onPressed: cubit.openAppSettings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Step 5: Start Background Service
              _buildPermissionTile(
                title: '5. Background Sync Service',
                subtitle: state.isBackgroundServiceRunning
                    ? 'Background service is running'
                    : 'Tap to start foreground background service',
                isGranted: state.isBackgroundServiceRunning,
                onTap: cubit.startBackgroundService,
              ),

              const SizedBox(height: 24),

              // Continue Button
              ElevatedButton(
                onPressed: state.canProceedToHome
                    ? () {
                        if (widget.isFirstRun) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.isFirstRun ? 'Continue to Dashboard' : 'Done',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!state.canProceedToHome) ...[
                const SizedBox(height: 8),
                const Text(
                  '* SMS permission and Background service must be active before continuing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Grant'),
              ),
      ),
    );
  }
}
