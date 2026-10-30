import 'package:permission_handler/permission_handler.dart';

class PermissionStatusModel {
  final bool hasSmsPermission;
  final bool hasNotificationPermission;
  final bool isBatteryOptimizationIgnored;

  PermissionStatusModel({
    required this.hasSmsPermission,
    required this.hasNotificationPermission,
    required this.isBatteryOptimizationIgnored,
  });

  bool get isAllGranted =>
      hasSmsPermission &&
      hasNotificationPermission &&
      isBatteryOptimizationIgnored;
}

class PermissionService {
  Future<PermissionStatusModel> checkAllStatuses() async {
    final sms = await Permission.sms.isGranted;
    final notif = await Permission.notification.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    return PermissionStatusModel(
      hasSmsPermission: sms,
      hasNotificationPermission: notif,
      isBatteryOptimizationIgnored: battery,
    );
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
