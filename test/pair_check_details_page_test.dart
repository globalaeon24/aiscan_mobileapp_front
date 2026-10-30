import 'package:ai_scan_text/features/main_shell/pages/pair_checks_panel.dart';
import 'package:ai_scan_text/services/scan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PairCheckItem itemWithStatus(String status) => PairCheckItem(
        id: 12,
        firstTitle: 'Первый документ',
        secondTitle: 'Второй документ',
        firstAuthor: 'Первый Автор',
        secondAuthor: 'Второй Автор',
        status: status,
        firstToSecondSimilarity: 3.4,
        secondToFirstSimilarity: 2.8,
        createdAt: DateTime(2026, 9, 10, 10, 45),
      );

  testWidgets('processing pair check card does not open results',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PairCheckCard(item: itemWithStatus('PR'))),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pair-check-12')));
    await tester.pumpAndSettle();

    expect(find.text('Парная проверка'), findsNothing);
    expect(find.text('Проверка'), findsOneWidget);
  });

  testWidgets('completed pair check card opens results', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PairCheckCard(item: itemWithStatus('CH'))),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pair-check-12')));
    await tester.pumpAndSettle();

    expect(find.text('Парная проверка'), findsOneWidget);
    expect(find.text('3.4%'), findsWidgets);
    expect(find.text('2.8%'), findsWidgets);
    expect(find.text('Полный отчёт PDF'), findsOneWidget);
    expect(find.text('Краткий отчёт PDF'), findsOneWidget);
  });

  testWidgets('pair check details stay readable on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = PairCheckItem(
      id: 13,
      firstTitle: 'Длинное название первого документа',
      secondTitle: 'Длинное название второго документа',
      firstAuthor: 'Первый Автор',
      secondAuthor: 'Второй Автор',
      status: 'CH',
      firstToSecondSimilarity: 3.4,
      secondToFirstSimilarity: 2.8,
      createdAt: DateTime(2026, 9, 10, 10, 45),
    );

    await tester.pumpWidget(
      MaterialApp(home: PairCheckDetailsPage(item: item)),
    );
    await tester.pumpAndSettle();

    expect(find.text('A → B'), findsOneWidget);
    expect(find.text('B → A'), findsOneWidget);
    expect(find.text('3.4%'), findsOneWidget);
    expect(find.text('2.8%'), findsOneWidget);
    expect(find.text('Проверен'), findsOneWidget);
    expect(find.textContaining('Задержка'), findsNothing);
    expect(find.textContaining('дольше обычного'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
