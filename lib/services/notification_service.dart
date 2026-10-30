import 'dart:convert';

import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  const NotificationService._();

  static Future<NotificationFeed> fetch({int limit = 30}) async {
    final response = await ApiService.get('/notifications?limit=$limit');
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить уведомления.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Сервер вернул некорректные уведомления.');
    }
    final candidateItems =
        decoded['items'] ?? decoded['results'] ?? decoded['data'];
    final rawItems =
        candidateItems is List ? candidateItems : const <dynamic>[];
    return NotificationFeed(
      items: rawItems
          .whereType<Map>()
          .map((item) => AppNotification.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      unreadCount: _asInt(decoded['unread_count']),
    );
  }

  static Future<void> markAllRead() async {
    final response = await ApiService.post('/notifications/read');
    if (response.statusCode != 200) {
      throw Exception('Не удалось отметить уведомления прочитанными.');
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
