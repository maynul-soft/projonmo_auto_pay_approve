import '../../core/http/dio_client.dart';
import '../api/api_exception.dart';

class AuthUser {
  final String id;
  final String name;
  final String role;

  AuthUser({required this.id, required this.name, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String roleStr = 'admin';
    final rawRole = json['role'];
    if (rawRole is Map) {
      roleStr = rawRole['slug']?.toString() ??
          rawRole['name']?.toString() ??
          'admin';
    } else if (rawRole is String) {
      roleStr = rawRole;
    }

    String name = json['fullName']?.toString() ??
        json['name']?.toString() ??
        json['email']?.toString() ??
        'Admin';
    if (name.toLowerCase().contains('tecq')) {
      name = 'Projonmo Admin';
    }

    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: name,
      role: roleStr,
    );
  }
}

class LoginResult {
  final String token;
  final String? refreshToken;
  final int? expiresIn;
  final AuthUser? user;

  LoginResult({
    required this.token,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });
}

class AuthApi {
  final DioClient dioClient;

  AuthApi({DioClient? dioClient}) : dioClient = dioClient ?? DioClient.instance;

  String _resolveUrl(String baseUrl, String pathOrUrl) {
    String cleanPath = pathOrUrl.trim();
    final uri = Uri.tryParse(cleanPath);
    if (uri != null && uri.hasScheme) {
      cleanPath = uri.path;
      if (uri.hasQuery) {
        cleanPath = '$cleanPath?${uri.query}';
      }
      final baseUri = Uri.tryParse(baseUrl);
      final basePath = baseUri?.path ?? '';
      if (basePath.isNotEmpty && cleanPath.startsWith(basePath)) {
        cleanPath = cleanPath.substring(basePath.length);
      }
    }

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final formatted = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    return '$cleanBase$formatted';
  }

  Future<LoginResult> login({
    required String baseUrl,
    required String loginPath,
    required String usernameOrEmail,
    required String password,
  }) async {
    final url = _resolveUrl(baseUrl, loginPath);

    try {
      final response = await dioClient.dio.post(
        url,
        data: {
          'email': usernameOrEmail.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw ApiException('Invalid server response');
      }

      final success = data['success'] == true;
      if (!success && data['message'] != null) {
        throw ApiException(data['message'].toString());
      }

      final payload = data['data'] ?? data;
      final token = payload['token']?.toString() ??
          payload['access_token']?.toString() ??
          payload['accessToken']?.toString();

      if (token == null || token.isEmpty) {
        throw ApiException('Authentication token missing from response');
      }

      final refreshToken = payload['refresh_token']?.toString();
      final expiresIn = payload['expires_in'] is int
          ? payload['expires_in'] as int
          : int.tryParse(payload['expires_in']?.toString() ?? '');

      AuthUser? user;
      if (payload['user'] is Map) {
        user = AuthUser.fromJson(Map<String, dynamic>.from(payload['user']));
      }

      // Check role - allows 'super_admin', 'admin', 'superadmin', etc.
      if (user != null && user.role.isNotEmpty) {
        final roleLower = user.role.toLowerCase();
        final isAdmin = roleLower.contains('admin') ||
            roleLower.contains('manager') ||
            roleLower.contains('staff');
        if (!isAdmin) {
          throw ApiException('This account is not an admin (${user.role})');
        }
      }

      return LoginResult(
        token: token,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        user: user,
      );
    } catch (e) {
      throw dioClient.handleDioError(e);
    }
  }
}
