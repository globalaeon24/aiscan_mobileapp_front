import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'device_identity_service.dart';

class AuthService {
  static const baseUrl = ApiConfig.baseUrl;
  static const _demoEnabled = bool.fromEnvironment('ENABLE_DEMO_LOGIN');
  static const _demoUsername = String.fromEnvironment('DEMO_USERNAME');
  static const _demoPassword = String.fromEnvironment('DEMO_PASSWORD');
  static String? lastLoginError;

  /// ---------- ЛОГИН ----------
  static Future<bool> login(String email, String password) async {
    lastLoginError = null;
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final normalizedLogin = trimmedEmail.toLowerCase();
    if (_demoEnabled &&
        _demoUsername.isNotEmpty &&
        normalizedLogin == _demoUsername.toLowerCase() &&
        trimmedPassword == _demoPassword) {
      await TokenStorage.saveToken('demo_oysyn_token');
      await TokenStorage.saveUser({
        "full_name": "Demo User",
        "email": "oysyn",
      });
      return true;
    }

    late final http.Response res;
    try {
      final deviceMetadata = await DeviceIdentityService.loginMetadata();
      res = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": trimmedEmail,
              "password": trimmedPassword,
              ...deviceMetadata,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      lastLoginError = "Сервер отвечает слишком долго. Попробуйте ещё раз.";
      return false;
    } catch (_) {
      lastLoginError = "Нет связи с сервером. Проверьте интернет-соединение.";
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
    final serverMessage = decoded is Map<String, dynamic>
        ? (decoded["detail"] ?? decoded["error"] ?? decoded["message"])
            ?.toString()
            .toLowerCase()
        : null;

    return switch (response.statusCode) {
      400 || 401 => "Неверный логин или пароль.",
      403 when serverMessage?.contains("заблок") == true =>
        "Учётная запись заблокирована. Обратитесь к администратору.",
      403 => "Вход для этой учётной записи ограничен.",
      404 => "Сервис авторизации временно недоступен.",
      408 => "Сервер отвечает слишком долго. Попробуйте ещё раз.",
      422 => "Проверьте, что логин и пароль заполнены правильно.",
      429 => "Слишком много попыток входа. Повторите немного позже.",
      >= 500 => "Сервис временно недоступен. Попробуйте позже.",
      _ => "Не удалось войти. Попробуйте ещё раз.",
    };
  }

  static Future<bool> register(
    String email,
    String password,
    String name,
    String organization,
  ) async {
    // Accounts are provisioned by an organization administrator in Oysyn Core.
    return false;
  }
}
