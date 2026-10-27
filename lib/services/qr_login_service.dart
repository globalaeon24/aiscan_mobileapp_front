import 'dart:convert';

import 'api_service.dart';

class QrLoginService {
  const QrLoginService._();

  static Future<String> approve(String qrToken) async {
    final response = await ApiService.post(
      '/qr-login/sessions/$qrToken/approve',
      body: const {},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status']?.toString() ?? 'approved';
    }

    throw Exception(_messageFromResponse(response.body));
  }

  static Future<String> reject(String qrToken) async {
    final response = await ApiService.post(
      '/qr-login/sessions/$qrToken/reject',
      body: const {},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status']?.toString() ?? 'rejected';
    }

    throw Exception(_messageFromResponse(response.body));
  }

  static String? tokenFromQr(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    try {
      final data = jsonDecode(value);
      if (data is Map<String, dynamic>) {
        final token = data['token'] ?? data['qr_token'] ?? data['qrToken'];
        if (token != null && token.toString().trim().isNotEmpty) {
          return token.toString().trim();
        }
      }
    } catch (_) {
      // QR can be a plain UUID or URL, so non-JSON values continue below.
    }

    final uri = Uri.tryParse(value);
    final tokenFromQuery = uri?.queryParameters['qr_token'] ??
        uri?.queryParameters['qrToken'] ??
        uri?.queryParameters['token'];
    if (tokenFromQuery != null && tokenFromQuery.trim().isNotEmpty) {
      return tokenFromQuery.trim();
    }

    final segments = uri?.pathSegments ?? const <String>[];
    final qrIndex = segments.indexWhere((segment) => segment == 'qr-login');
    if (qrIndex >= 0 && qrIndex + 1 < segments.length) {
      final nextSegment = segments[qrIndex + 1];
      final tokenIndex = nextSegment == 'sessions' ? qrIndex + 2 : qrIndex + 1;
      if (tokenIndex >= segments.length) return value;

      final token = segments[tokenIndex].trim();
      if (token.isNotEmpty) return token;
    }

    return value;
  }

  static String _messageFromResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {
      // Keep the user-facing fallback below when the backend returns non-JSON.
    }
    return 'Не удалось выполнить QR-авторизацию';
  }
}
