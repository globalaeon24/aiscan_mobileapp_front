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
      await TokenStorage.saveUser({
        "full_name": "Demo User",
        "email": "oysyn",
      });
      return true;
    }

    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final token = data["access_token"];
      final refreshToken = data["refresh_token"];
      final user = data["user"];

      if (token == null) {
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

    return false;
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
