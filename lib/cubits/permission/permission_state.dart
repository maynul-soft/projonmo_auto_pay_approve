import 'package:equatable/equatable.dart';

class PermissionState extends Equatable {
  final bool hasSms;
  final bool hasNotification;
  final bool isBatteryIgnored;
  final bool isBackgroundServiceRunning;
  final bool isLoading;

  const PermissionState({
    this.hasSms = false,
    this.hasNotification = false,
    this.isBatteryIgnored = false,
    this.isBackgroundServiceRunning = false,
    this.isLoading = false,
  });

  bool get canProceedToHome => hasSms && isBackgroundServiceRunning;
  bool get allPermissionsOk => hasSms && hasNotification && isBatteryIgnored;

  PermissionState copyWith({
    bool? hasSms,
    bool? hasNotification,
    bool? isBatteryIgnored,
    bool? isBackgroundServiceRunning,
    bool? isLoading,
  }) {
    return PermissionState(
      hasSms: hasSms ?? this.hasSms,
      hasNotification: hasNotification ?? this.hasNotification,
      isBatteryIgnored: isBatteryIgnored ?? this.isBatteryIgnored,
      isBackgroundServiceRunning:
          isBackgroundServiceRunning ?? this.isBackgroundServiceRunning,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        hasSms,
        hasNotification,
        isBatteryIgnored,
        isBackgroundServiceRunning,
        isLoading,
      ];
}
