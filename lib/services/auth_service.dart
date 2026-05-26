import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AuthService {
  static const baseUrl = ApiConfig.baseUrl;
  static const _demoUsername = 'oysyn';
  static const _demoPassword = 'qwerty';
  static const _demoToken = 'demo_oysyn_token';

  /// ---------- ЛОГИН ----------
  static Future<bool> login(String email, String password) async {
    final normalizedLogin = email.trim().toLowerCase();
    if (normalizedLogin == _demoUsername && password == _demoPassword) {
      await TokenStorage.saveToken(_demoToken);
      return true;
    }

    // backend ждёт x-www-form-urlencoded c полями username/password
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": email,
        "password": password,
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final token = data["access_token"];

      if (token == null) {
        return false;
      }

      // КЛЮЧЕВОЙ МОМЕНТ: сохраняем токен
      await TokenStorage.saveToken(token);
      return true;
    }

    return false;
  }

  /// ---------- РЕГИСТРАЦИЯ ----------
  static Future<bool> register(
    String email,
    String password,
    String name,
    String org,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "name": name,
        "organization_name": org,
        "agree_privacy": true,
      }),
    );

    if (res.statusCode == 200) {
      // после регистрации сразу логиним
      return await login(email, password);
    }

    return false;
  }
}
