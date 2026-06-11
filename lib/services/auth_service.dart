import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AuthService {
  static const baseUrl = ApiConfig.baseUrl;
  static const _demoUsername = 'oysyn';
  static const _demoPassword = 'qwerty';
  static const _demoToken = 'demo_oysyn_token';
  static String? lastLoginError;

  /// ---------- ЛОГИН ----------
  static Future<bool> login(String email, String password) async {
    lastLoginError = null;
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final normalizedLogin = trimmedEmail.toLowerCase();
    if (normalizedLogin == _demoUsername && trimmedPassword == _demoPassword) {
      await TokenStorage.saveToken(_demoToken);
      await TokenStorage.saveUser({
        "full_name": "Demo User",
        "email": "oysyn",
      });
      return true;
    }

    late final http.Response res;
    try {
      res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": trimmedEmail,
          "password": trimmedPassword,
        }),
      );
    } catch (_) {
      lastLoginError = "Не удалось подключиться к серверу.";
      return false;
    }

    if (res.statusCode == 200) {
      final data = _decodeBody(res.body);
      if (data is! Map<String, dynamic>) {
        lastLoginError = "Сервер вернул некорректный ответ.";
        return false;
      }
      final token = data["access_token"];
      final refreshToken = data["refresh_token"];
      final user = data["user"];

      if (token == null) {
        lastLoginError = "Сервер не вернул токен авторизации.";
        return false;
      }

      // КЛЮЧЕВОЙ МОМЕНТ: сохраняем токен
      await TokenStorage.saveToken(token);
      if (refreshToken != null) {
        await TokenStorage.saveRefreshToken(refreshToken);
      }
      if (user is Map<String, dynamic>) {
        await TokenStorage.saveUser(user);
      }
      return true;
    }

    lastLoginError = _extractErrorMessage(res);
    return false;
  }

  static dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(http.Response response) {
    final decoded = _decodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      final detail =
          decoded["detail"] ?? decoded["error"] ?? decoded["message"];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is Map || detail is List) {
        return jsonEncode(detail);
      }
    }

    if (response.statusCode == 401) {
      return "Неверный email или пароль.";
    }
    return "Ошибка входа. Код: ${response.statusCode}.";
  }

  /// ---------- РЕГИСТРАЦИЯ ----------
  static Future<bool> register(
    String email,
    String password,
    String name,
    String org,
  ) async {
    // Production mobile backend does not own user registration.
    // Users are created in Oysyn Core, then authenticated through /api/v1/auth/login.
    return false;
  }
}
