import 'scan_result.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final ScanResult? check;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.check,
  });

  bool get failed => type == 'check_failed';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const <String, dynamic>{};
    final checkJson = payload['check'] is Map
        ? Map<String, dynamic>.from(payload['check'] as Map)
        : null;
    return AppNotification(
      id: _asInt(json['id']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Уведомление',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true,
      check: checkJson == null ? null : ScanResult.fromJson(checkJson),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class NotificationFeed {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationFeed({
    required this.items,
    required this.unreadCount,
  });
}
