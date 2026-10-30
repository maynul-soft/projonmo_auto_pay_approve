import 'package:flutter_test/flutter_test.dart';
import 'package:payment_auto_approver/core/api_config.dart';

void main() {
  test('ApiConfig has expected default paths and constants', () {
    expect(ApiConfig.defaultLoginPath, '/auth/login');
    expect(
        ApiConfig.defaultPendingPath, '/admin/deposits?status=pending&limit=100');
    expect(ApiConfig.defaultApprovePath, '/admin/deposits/approve');
  });
}
