import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ProfileService {
  static const baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/me"),
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

  static Future<Map<String, dynamic>> getOrganization(
      int organizationId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception("Нет токена авторизации.");
    }

    final res = await http.get(
      Uri.parse("$baseUrl/organizations/$organizationId"),
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
