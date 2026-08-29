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

  static Future<List<Map<String, dynamic>>> getOrganizations() async {
    final data = await _get('/organizations');
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<List<Map<String, dynamic>>> getOrganizationUsers(
      int organizationId) async {
    final data = await _get('/organizations/$organizationId/users');
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>> getOrganizationApiSettings(
      int organizationId) async {
    final data = await _get('/organizations/$organizationId/api-settings');
    return data is Map<String, dynamic> ? data : const {};
  }

  static Future<List<Map<String, dynamic>>> getOrganizationBilling(
      int organizationId) async {
    final data = await _get('/organizations/$organizationId/billing');
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<dynamic> _get(String path) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Нет токена авторизации.');
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить данные (${response.statusCode}).');
    }
    return jsonDecode(response.body);
  }
}
