import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import '../core/utils/app_logger.dart';
import '../data/hive/hive_service.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager instance =
      BackgroundServiceManager._internal();
  BackgroundServiceManager._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initializeService() async {
    await NotificationService.instance.init();

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: NotificationService.channelId,
        initialNotificationTitle: 'Projonmo Admin',
        initialNotificationContent: 'Payment Sync running in background',
        foregroundServiceNotificationId: 999,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Forward logs from background service isolate to main UI logger
    _service.on('onAppLog').listen((event) {
      if (event != null) {
        final levelName = event['level']?.toString() ?? 'info';
        final tag = event['tag']?.toString() ?? 'BG';
        final message = event['message']?.toString() ?? '';
        final details = event['details']?.toString();
        final level = LogLevel.values.firstWhere(
          (l) => l.name == levelName,
          orElse: () => LogLevel.info,
        );
        AppLogger.instance
            .log(level: level, tag: tag, message: message, details: details);
      }
    });
  }

  Future<bool> isRunning() => _service.isRunning();

  void startService() => _service.startService();

  void triggerSyncNow() {
    _service.invoke('syncNow');
  }

  void stopService() {
    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Forward background isolate logs to main UI isolate
  AppLogger.instance.onLogEmitted = (entry) {
    service.invoke('onAppLog', {
      'level': entry.level.name,
      'tag': entry.tag,
      'message': entry.message,
      'details': entry.details,
    });
  };

  // Initialize Hive in the background isolate
  await HiveService.instance.init();

  final timeFormat = DateFormat('HH:mm');

  // Handle manual sync invocation from UI
  service.on('syncNow').listen((event) async {
    await SyncService.instance.runSync(trigger: 'manual');
    service.invoke('update', {'lastSync': DateTime.now().toIso8601String()});
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final appState = HiveService.instance.getAppState();
  final interval = Duration(minutes: appState.syncIntervalMinutes);

  // Periodic 5-minute background sync
  Timer.periodic(interval, (timer) async {
    final log = await SyncService.instance.runSync(trigger: 'timer');
    final nowFormatted = timeFormat.format(DateTime.now());

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Payment Sync running',
          content: 'Last sync: $nowFormatted',
        );
      }
    }

    service.invoke('update', {
      'lastSync': DateTime.now().toIso8601String(),
      'status': log?.error == null ? 'success' : 'failed',
    });
  });
}
