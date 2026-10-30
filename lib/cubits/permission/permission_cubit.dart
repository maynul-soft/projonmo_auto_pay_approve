import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/background_service.dart';
import '../../services/permission_service.dart';
import 'permission_state.dart';

class PermissionCubit extends Cubit<PermissionState> {
  final PermissionService permissionService;
  final BackgroundServiceManager backgroundServiceManager;

  PermissionCubit({
    PermissionService? permissionService,
    BackgroundServiceManager? backgroundServiceManager,
  })  : permissionService = permissionService ?? PermissionService(),
        backgroundServiceManager =
            backgroundServiceManager ?? BackgroundServiceManager.instance,
        super(const PermissionState());

  Future<void> checkPermissions() async {
    emit(state.copyWith(isLoading: true));
    final status = await permissionService.checkAllStatuses();
    final isRunning = await backgroundServiceManager.isRunning();

    emit(state.copyWith(
      hasSms: status.hasSmsPermission,
      hasNotification: status.hasNotificationPermission,
      isBatteryIgnored: status.isBatteryOptimizationIgnored,
      isBackgroundServiceRunning: isRunning,
      isLoading: false,
    ));
  }

  Future<void> requestSms() async {
    await permissionService.requestSmsPermission();
    await checkPermissions();
  }

  Future<void> requestNotification() async {
    await permissionService.requestNotificationPermission();
    await checkPermissions();
  }

  Future<void> requestBatteryOptimization() async {
    await permissionService.requestIgnoreBatteryOptimization();
    await checkPermissions();
  }

  Future<void> startBackgroundService() async {
    await backgroundServiceManager.initializeService();
    backgroundServiceManager.startService();
    await Future.delayed(const Duration(milliseconds: 500));
    await checkPermissions();
  }

  Future<void> openAppSettings() async {
    await permissionService.openAppSettingsPage();
  }
}
