import 'package:flutter_test/flutter_test.dart';
import 'package:payment_auto_approver/data/auth/auth_api.dart';

void main() {
  test('Parses real backend login response with super_admin role object', () {
    final response = {
      "success": true,
      "message": "Login successful",
      "data": {
        "user": {
          "id": "cmuofrt1t0000i4sg9t234w1f",
          "email": "admin",
          "fullName": "Tecqora Admin",
          "role": {"slug": "super_admin"}
        },
        "accessToken": "test_token_123"
      },
      "path": "/api/v1//auth/login"
    };

    final payload = response['data'] as Map<String, dynamic>;
    final userMap = payload['user'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(userMap);

    expect(user.id, 'cmuofrt1t0000i4sg9t234w1f');
    expect(user.name, 'Projonmo Admin');
    expect(user.role, 'super_admin');
    expect(user.role.contains('admin'), isTrue);
  });
}
