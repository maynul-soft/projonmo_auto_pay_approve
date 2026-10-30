import 'dart:async';
import '../../core/api_config.dart';
import 'auth_api.dart';
import 'token_storage.dart';
import '../api/api_exception.dart';
import '../hive/hive_service.dart';

enum SessionStatus { loggedOut, active, expired }

class AuthRepository {
  final AuthApi authApi;
  final TokenStorage tokenStorage;
  final HiveService hiveService;

  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  AuthRepository({
    AuthApi? authApi,
    TokenStorage? tokenStorage,
    HiveService? hiveService,
  })  : authApi = authApi ?? AuthApi(),
        tokenStorage = tokenStorage ?? TokenStorage(),
        hiveService = hiveService ?? HiveService.instance;

  int get failedAttempts => _failedLoginAttempts;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get remainingLockoutSeconds => isLockedOut
      ? _lockoutUntil!.difference(DateTime.now()).inSeconds
      : 0;

  Future<SessionStatus> checkSession() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return SessionStatus.loggedOut;
    }

    final expiresAt = await tokenStorage.getTokenExpiresAt();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      return SessionStatus.expired;
    }

    return SessionStatus.active;
  }

  Future<LoginResult> login({
    required String usernameOrEmail,
    required String password,
    String? customBaseUrl,
  }) async {
    if (isLockedOut) {
      throw ApiException(
        'Too many failed attempts. Try again in $remainingLockoutSeconds seconds.',
      );
    }

    final appState = hiveService.getAppState();
    final baseUrl = customBaseUrl ??
        (appState.baseUrl.contains('api.projonmo.tech')
            ? appState.baseUrl
            : ApiConfig.defaultBaseUrl);
    final loginPath = appState.loginPath;

    try {
      final result = await authApi.login(
        baseUrl: baseUrl,
        loginPath: loginPath,
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      _failedLoginAttempts = 0;
      _lockoutUntil = null;

      DateTime? expiresAt;
      if (result.expiresIn != null) {
        expiresAt = DateTime.now().add(Duration(seconds: result.expiresIn!));
      }

      await tokenStorage.saveSession(
        accessToken: result.token,
        refreshToken: result.refreshToken,
        expiresAt: expiresAt,
        adminId: result.user?.id,
        adminName: result.user?.name,
        adminRole: result.user?.role,
        baseUrl: baseUrl,
      );

      return result;
    } catch (e) {
      _failedLoginAttempts++;
      if (_failedLoginAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      rethrow;
    }
  }

  Future<void> logout({bool keepLocalSms = true}) async {
    await tokenStorage.clearSession();
    if (!keepLocalSms) {
      await hiveService.clearAllData();
    }
  }
}
