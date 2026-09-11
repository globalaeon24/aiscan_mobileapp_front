import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ProfileService {
  static const baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiService.get('/me');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Не удалось загрузить профиль (${res.statusCode}).');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    final data = await _send('PATCH', '/me', payload);
    final updated = data is Map<String, dynamic> ? data : <String, dynamic>{};
    try {
      final fresh = await getProfile();
      return {...fresh, ...updated, ...payload};
    } catch (_) {
      return {...updated, ...payload};
    }
  }

  static Future<Map<String, dynamic>> getOrganization(
      int organizationId) async {
    final res = await ApiService.get('/organizations/$organizationId');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Не удалось загрузить организацию (${res.statusCode}).');
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
    final response = await ApiService.get(path);
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
    final response = switch (method) {
      'PATCH' => await ApiService.patch(path, body: payload),
      'POST' => await ApiService.post(path, body: payload),
      _ => throw UnsupportedError('Неподдерживаемый HTTP-метод: $method'),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Не удалось сохранить данные (${response.statusCode}).');
    }
    return response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body);
  }
}
