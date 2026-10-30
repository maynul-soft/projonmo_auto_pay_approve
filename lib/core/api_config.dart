class ApiConfig {
  static const String defaultBaseUrl = 'https://api.projonmo.tech/api/v1';

  static String get initialBaseUrl => defaultBaseUrl;

  static const String defaultLoginPath = '/auth/login';
  static const String defaultPendingPath =
      '/admin/deposits?status=pending&limit=100';
  static const String defaultApprovePath = '/admin/deposits/:id/review';

  static const String authHeaderKey = 'Authorization';
  static const String authScheme = 'Bearer';

  static const Duration timeout = Duration(seconds: 20);
}
