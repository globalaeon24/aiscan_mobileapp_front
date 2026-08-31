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

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('PATCH', '/me', payload);
    return data is Map<String, dynamic> ? data : const {};
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

  static Future<Map<String, dynamic>> createOrganizationUser(
    int organizationId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _send(
      'POST',
      '/organizations/$organizationId/users',
      payload,
    );
    return data is Map<String, dynamic> ? data : const {};
  }

  static Future<Map<String, dynamic>> updateOrganizationUser(
    int organizationId,
    int userId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _send(
      'PATCH',
      '/organizations/$organizationId/users/$userId',
      payload,
    );
    return data is Map<String, dynamic> ? data : const {};
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

  static Future<Map<String, dynamic>> updateOrganizationBilling(
    int organizationId,
    int userId,
    int checksAvailable,
  ) async {
    final data = await _send(
      'PATCH',
      '/organizations/$organizationId/billing/$userId',
      {'checks_available': checksAvailable},
    );
    return data is Map<String, dynamic> ? data : const {};
  }

  static Future<List<Map<String, dynamic>>> getOrganizationBillingJournal(
      int organizationId) async {
    final data = await _get('/organizations/$organizationId/billing-journal');
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>> getOrganizationReports(
      int organizationId) async {
    final data = await _get('/organizations/$organizationId/reports');
    return data is Map<String, dynamic> ? data : const {};
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

  static Future<dynamic> _send(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Нет токена авторизации.');
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(payload);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Не удалось сохранить данные (${response.statusCode}).');
    }
    return jsonDecode(response.body);
  }
}
