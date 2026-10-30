import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../services/background_service.dart';
import '../../services/sync_service.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../manual_approve/manual_approve_screen.dart';
import '../pending/pending_screen.dart';
import '../settings/settings_screen.dart';
import '../sms_records/sms_records_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SmsRecordsScreen(),
    PendingScreen(),
    ManualApproveScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Start foreground periodic auto-sync timer (runs every 5 mins + immediate initial run)
      SyncService.instance.startPeriodicSync(triggerImmediate: true);

      // 2. Ensure Android background service is running
      try {
        final isRunning = await BackgroundServiceManager.instance.isRunning();
        if (!isRunning) {
          await BackgroundServiceManager.instance.initializeService();
          BackgroundServiceManager.instance.startService();
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.sms_outlined),
              selectedIcon: Icon(Icons.sms),
              label: 'SMS',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions),
              label: 'Pending',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Approve',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
