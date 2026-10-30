import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/app_logs/app_logs_cubit.dart';
import 'cubits/home/home_cubit.dart';
import 'cubits/manual_approve/manual_approve_cubit.dart';
import 'cubits/pending/pending_cubit.dart';
import 'cubits/permission/permission_cubit.dart';
import 'cubits/settings/settings_cubit.dart';
import 'cubits/sms_records/sms_records_cubit.dart';
import 'cubits/sync_logs/sync_logs_cubit.dart';
import 'data/hive/hive_service.dart';
import 'services/live_sms_listener.dart';
import 'ui/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register adapters
  await HiveService.instance.init();

  // Initialize instant live SMS listener
  LiveSmsListener.instance.initialize();

  runApp(const PaymentAutoApproverApp());
}

class PaymentAutoApproverApp extends StatelessWidget {
  const PaymentAutoApproverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
        ),
        BlocProvider<PermissionCubit>(
          create: (_) => PermissionCubit(),
        ),
        BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(),
        ),
        BlocProvider<SmsRecordsCubit>(
          create: (_) => SmsRecordsCubit(),
        ),
        BlocProvider<PendingCubit>(
          create: (_) => PendingCubit(),
        ),
        BlocProvider<ManualApproveCubit>(
          create: (_) => ManualApproveCubit(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(),
        ),
        BlocProvider<SyncLogsCubit>(
          create: (_) => SyncLogsCubit(),
        ),
        BlocProvider<AppLogsCubit>(
          create: (_) => AppLogsCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Auto Payment',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
