import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/http/dio_client.dart';
import '../../data/auth/auth_repository.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  Timer? _lockoutTimer;

  AuthCubit({AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    DioClient.instance.onSessionExpired = _handleSessionExpired;
  }

  void _handleSessionExpired() {
    NotificationService.instance.showSessionExpiredNotification();
    emit(AuthExpired());
  }

  Future<void> checkInitialSession() async {
    emit(AuthLoading());
    final status = await authRepository.checkSession();
    if (status == SessionStatus.active) {
      final name = await authRepository.tokenStorage.getAdminName();
      final role = await authRepository.tokenStorage.getAdminRole();
      emit(Authenticated(adminName: name, adminRole: role));
    } else if (status == SessionStatus.expired) {
      emit(AuthExpired());
    } else {
      final savedUser = await authRepository.tokenStorage.getSavedUsername();
      emit(Unauthenticated(savedUsername: savedUser));
    }
  }

  Future<void> login({
    required String usernameOrEmail,
    required String password,
    required bool rememberUsername,
    String? customBaseUrl,
  }) async {
    if (authRepository.isLockedOut) {
      _startLockoutCountdown();
      return;
    }

    emit(AuthLoading());

    try {
      final result = await authRepository.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
        customBaseUrl: customBaseUrl,
      );

      if (rememberUsername) {
        await authRepository.tokenStorage.saveUsername(usernameOrEmail);
      } else {
        await authRepository.tokenStorage.clearSavedUsername();
      }

      emit(Authenticated(
        adminName: result.user?.name,
        adminRole: result.user?.role,
      ));
    } catch (e) {
      final savedUser = await authRepository.tokenStorage.getSavedUsername();
      if (authRepository.isLockedOut) {
        _startLockoutCountdown(errorMessage: e.toString());
      } else {
        emit(Unauthenticated(
          savedUsername: savedUser,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  void _startLockoutCountdown({String? errorMessage}) {
    _lockoutTimer?.cancel();
    int seconds = authRepository.remainingLockoutSeconds;
    emit(Unauthenticated(
      errorMessage: errorMessage ?? 'Too many failed attempts.',
      lockoutSeconds: seconds,
    ));

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds <= 0) {
        timer.cancel();
        emit(const Unauthenticated(lockoutSeconds: 0));
      } else {
        emit(Unauthenticated(lockoutSeconds: seconds));
      }
    });
  }

  Future<void> logout({bool keepLocalSms = true}) async {
    SyncService.instance.stopPeriodicSync();
    await authRepository.logout(keepLocalSms: keepLocalSms);
    final savedUser = await authRepository.tokenStorage.getSavedUsername();
    emit(Unauthenticated(savedUsername: savedUser));
  }

  @override
  Future<void> close() {
    _lockoutTimer?.cancel();
    return super.close();
  }
}
