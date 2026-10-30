import 'package:dio/dio.dart';
import '../../core/http/dio_client.dart';
import '../models/pending_payment.dart';
import 'api_exception.dart';

class PaymentApi {
  final DioClient dioClient;

  PaymentApi({DioClient? dioClient})
      : dioClient = dioClient ?? DioClient.instance;

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

  Future<List<PendingPayment>> fetchPendingPayments({
    required String baseUrl,
    required String pendingApiUrl,
  }) async {
    final fullUrl = _resolveUrl(baseUrl, pendingApiUrl);
    try {
      final response = await dioClient.dio.get(fullUrl);
      final data = response.data;

      if (data is Map && data['success'] == false) {
        throw ApiException(
            data['message']?.toString() ?? 'Failed to fetch pending deposits');
      }

      List listData;
      if (data is Map && data['data'] is List) {
        listData = data['data'] as List;
      } else if (data is List) {
        listData = data;
      } else {
        listData = [];
      }

      return listData
          .map((item) =>
              PendingPayment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      throw dioClient.handleDioError(e);
    }
  }

  Future<bool> approvePayment({
    required String baseUrl,
    required String approveApiUrl,
    required String paymentId,
    required String txnId,
    String? adminNote,
  }) async {
    String targetPath = approveApiUrl.trim();
    if (targetPath.isEmpty ||
        targetPath == '/admin/deposits/approve' ||
        targetPath.endsWith('/deposits/approve')) {
      targetPath = '/admin/deposits/:id/review';
    }

    if (targetPath.contains(':id')) {
      targetPath = targetPath.replaceAll(':id', paymentId);
    } else if (targetPath.contains('{id}')) {
      targetPath = targetPath.replaceAll('{id}', paymentId);
    } else if (!targetPath.contains(paymentId)) {
      targetPath = '/admin/deposits/$paymentId/review';
    }

    final fullUrl = _resolveUrl(baseUrl, targetPath);
    final normTxnId = txnId.trim().toUpperCase();

    final payload = {
      'action': 'approve',
      'adminNote': adminNote ?? 'Auto-approved via SMS Trx: $normTxnId',
      'id': paymentId,
      'depositId': paymentId,
      'transaction_id': normTxnId,
      'txnId': normTxnId,
      'status': 'Approved',
    };

    try {
      final response = await dioClient.dio.post(
        fullUrl,
        data: payload,
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        final msg = data['message']?.toString().toLowerCase() ?? '';
        if (success ||
            msg.contains('already approved') ||
            msg.contains('approved') ||
            msg.contains('success')) {
          return true;
        }
        throw ApiException(data['message']?.toString() ?? 'Approval failed');
      }
      return true;
    } on DioException catch (dioErr) {
      final res = dioErr.response;
      if (res != null && res.data is Map) {
        final msg = (res.data['message'] ?? '').toString().toLowerCase();
        // Server response saying already approved is treated as SUCCESS (idempotent)
        if (msg.contains('already approved') ||
            msg.contains('already reviewed')) {
          return true;
        }
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e) {
      throw dioClient.handleDioError(e);
    }
  }

  Future<bool> rejectPayment({
    required String baseUrl,
    required String approveApiUrl,
    required String paymentId,
    String? reason,
  }) async {
    String targetPath = approveApiUrl.trim();
    if (targetPath.isEmpty ||
        targetPath == '/admin/deposits/approve' ||
        targetPath.endsWith('/deposits/approve')) {
      targetPath = '/admin/deposits/:id/review';
    }

    if (targetPath.contains(':id')) {
      targetPath = targetPath.replaceAll(':id', paymentId);
    } else if (targetPath.contains('{id}')) {
      targetPath = targetPath.replaceAll('{id}', paymentId);
    } else if (!targetPath.contains(paymentId)) {
      targetPath = '/admin/deposits/$paymentId/review';
    }

    final fullUrl = _resolveUrl(baseUrl, targetPath);

    final payload = {
      'action': 'reject',
      'adminNote': reason ?? 'Rejected by admin',
      'id': paymentId,
      'depositId': paymentId,
    };

    try {
      final response = await dioClient.dio.post(
        fullUrl,
        data: payload,
      );

      final data = response.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) return true;
        throw ApiException(data['message']?.toString() ?? 'Reject failed');
      }
      return true;
    } catch (e) {
      throw dioClient.handleDioError(e);
    }
  }
}
