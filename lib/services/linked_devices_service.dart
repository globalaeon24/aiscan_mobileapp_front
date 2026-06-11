import 'dart:convert';

import '../models/linked_device_session.dart';
import 'api_service.dart';

class LinkedDevicesService {
  const LinkedDevicesService._();

  static Future<List<LinkedDeviceSession>> fetchDevices() async {
    final response = await ApiService.get('/sessions/devices');
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response.body));
    }

    final decoded = jsonDecode(response.body);
    final items = _itemsFrom(decoded);
    return items
        .whereType<Map<String, dynamic>>()
        .map(LinkedDeviceSession.fromJson)
        .where((session) => session.id > 0)
        .toList();
  }

  static Future<void> revokeDevice(int id) async {
    final response = await ApiService.post('/sessions/devices/$id/revoke');
    if (response.statusCode != 200) {
      throw Exception(_messageFromResponse(response.body));
    }
  }

  static List<dynamic> _itemsFrom(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in ['items', 'results', 'data', 'sessions', 'devices']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  static String _messageFromResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail'] ?? data['error'] ?? data['message'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {
      // Keep fallback below for non-JSON responses.
    }
    return 'Не удалось загрузить связанные устройства';
  }
}
