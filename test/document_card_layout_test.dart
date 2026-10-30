import 'package:ai_scan_text/features/dashboard/models/dashboard_document.dart';
import 'package:ai_scan_text/features/dashboard/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required DashboardDocument document,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              DocumentCard(
                document: document,
                detailed: true,
                action: Row(
                  key: const ValueKey('actions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.drive_file_move_outlined),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('pending report text does not push date or actions',
      (tester) async {
    await pumpCard(
      tester,
      document: DashboardDocument(
        title: 'Очень длинное название загруженной научной работы',
        subtitle: 'Article · 138.7 КБ · Автор с длинным именем',
        statusText: 'Проверка',
        statusType: DocumentStatusType.processing,
        createdAt: DateTime(2026, 10, 28),
      ),
    );

    final unavailable = find.text('Отчёт будет доступен после проверки');
    final date = find.text('28.10.2026');
    final actions = find.byKey(const ValueKey('actions'));

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(date).dy,
        greaterThan(tester.getTopLeft(unavailable).dy));
    expect(
        tester.getTopRight(date).dx, lessThan(tester.getTopLeft(actions).dx));
    expect(tester.getSize(find.byType(DocumentCard)).height, lessThan(115));
  });

  testWidgets('completed report keeps compact footer on mobile',
      (tester) async {
    await pumpCard(
      tester,
      document: DashboardDocument(
        title: 'Дипломная работа',
        subtitle: 'Course work · 579.3 КБ · Автор',
        originalityPercent: 41.2,
        aiPercent: 33,
        statusType: DocumentStatusType.success,
        createdAt: DateTime(2026, 10, 27),
      ),
    );

    final recommendation = find.text('Низкая оригинальность');
    final date = find.text('27.10.2026');
    final actions = find.byKey(const ValueKey('actions'));

    expect(tester.takeException(), isNull);
    expect(tester.getTopRight(recommendation).dx,
        lessThan(tester.getTopLeft(date).dx));
    expect(
        tester.getTopRight(date).dx, lessThan(tester.getTopLeft(actions).dx));
    expect(tester.getSize(find.byType(DocumentCard)).height, lessThan(110));
  });
}
