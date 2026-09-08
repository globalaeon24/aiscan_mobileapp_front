import 'package:ai_scan_text/features/main_shell/utils/document_list_filter.dart';
import 'package:ai_scan_text/models/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScanResult result({
    required int id,
    required DateTime createdAt,
    String? title,
    String? author,
    String? status,
  }) {
    return ScanResult(
      id: id,
      title: title,
      authorName: author,
      status: status,
      originalityPercentage: 90,
      scannedText: '',
      highlightedText: null,
      createdAt: createdAt,
      aiFragments: const [],
    );
  }

  final items = [
    result(
      id: 1,
      title: 'Старая работа',
      author: 'Иванов',
      status: 'CH',
      createdAt: DateTime(2026, 8, 27, 23, 59),
    ),
    result(
      id: 2,
      title: 'Дипломная работа',
      author: 'Айжан',
      status: 'ch',
      createdAt: DateTime(2026, 8, 28),
    ),
    result(
      id: 3,
      title: 'Новая статья',
      author: 'Серик',
      status: 'PR',
      createdAt: DateTime(2026, 9, 3, 9),
    ),
  ];

  test('period includes the whole first calendar day', () {
    final filtered = DocumentListFilter.apply(
      items: items,
      query: '',
      status: null,
      period: const Duration(days: 7),
      newestFirst: true,
      now: DateTime(2026, 9, 3, 16),
    );

    expect(filtered.map((item) => item.id), [3, 2]);
  });

  test('status matching is case insensitive', () {
    final filtered = DocumentListFilter.apply(
      items: items,
      query: '',
      status: 'CH',
      period: null,
      newestFirst: true,
    );

    expect(filtered.map((item) => item.id), [2, 1]);
  });

  test('search uses title and author and sorting can be reversed', () {
    final byTitle = DocumentListFilter.apply(
      items: items,
      query: 'дипломная',
      status: null,
      period: null,
      newestFirst: true,
    );
    final byAuthor = DocumentListFilter.apply(
      items: items,
      query: 'иванов',
      status: null,
      period: null,
      newestFirst: false,
    );

    expect(byTitle.single.id, 2);
    expect(byAuthor.single.id, 1);
  });

  test('pagination returns a different slice for every page', () {
    final many = List.generate(
      45,
      (index) => result(id: index + 1, createdAt: DateTime(2026, 9, 3)),
    );

    expect(
      DocumentListFilter.page(items: many, page: 1, pageSize: 20)
          .map((item) => item.id),
      List.generate(20, (index) => index + 1),
    );
    expect(
      DocumentListFilter.page(items: many, page: 2, pageSize: 20)
          .map((item) => item.id),
      List.generate(20, (index) => index + 21),
    );
    expect(
      DocumentListFilter.page(items: many, page: 3, pageSize: 20)
          .map((item) => item.id),
      [41, 42, 43, 44, 45],
    );
  });
}
