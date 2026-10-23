import 'package:ai_scan_text/services/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses deleted document ownership and deletion metadata', () {
    final item = DeletedCheck.fromJson({
      'id': 17,
      'title': 'Дипломная работа',
      'status': 'CH',
      'created_at': '2026-09-01T10:00:00Z',
      'deleted_at': '2026-09-11T08:15:00Z',
      'originality_percentage': 84.5,
      'created_by': {
        'id': 22,
        'full_name': 'Алия Садыкова',
        'email': 'aliya@example.com',
      },
      'deleted_by': {
        'id': 22,
        'full_name': 'Алия Садыкова',
        'email': 'aliya@example.com',
      },
    });

    expect(item.document.id, 17);
    expect(item.document.title, 'Дипломная работа');
    expect(item.document.originalityPercentage, 84.5);
    expect(item.createdByName, 'Алия Садыкова');
    expect(item.createdByEmail, 'aliya@example.com');
    expect(item.deletedByName, 'Алия Садыкова');
    expect(item.deletedAt, DateTime.parse('2026-09-11T08:15:00Z'));
  });
}
