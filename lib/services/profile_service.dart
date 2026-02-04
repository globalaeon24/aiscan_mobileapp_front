import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ProfileService {
  static const baseUrl = "http://194.146.43.172:8082/api";

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return {};
    }
  }
}