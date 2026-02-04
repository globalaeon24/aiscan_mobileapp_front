import 'dart:convert';
import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import '../main.dart';

class ApiService {
  static const baseUrl = "http://194.146.43.172:8082/api";

  /// 🔓 Публичные эндпоинты (НЕ ТРОГАЕМ logout)
  static const List<String> _publicPaths = [
    '/auth/login',
    '/auth/register',
  ];

  // ===================== GET =====================
  static Future<http.Response> get(String path) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        );
      },
    );
  }

  // ===================== POST =====================
  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send(
      path,
      () async {
        final token = await TokenStorage.getToken();
        return http.post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: body == null ? null : jsonEncode(body),
        );
      },
    );
  }

  // ===================== CORE =====================
  static Future<http.Response> _send(
    String path,
    Future<http.Response> Function() request,
  ) async {
    final response = await request();

    if (response.statusCode == 401 && !_isPublic(path)) {
      await _forceLogout();
    }

    return response;
  }

  static bool _isPublic(String path) {
    return _publicPaths.any((p) => path.startsWith(p));
  }

  // ===================== LOGOUT =====================
  static Future<void> _forceLogout() async {
    print("🔥 FORCE LOGOUT");

    await TokenStorage.clear();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}