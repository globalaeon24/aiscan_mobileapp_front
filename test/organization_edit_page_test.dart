import 'package:ai_scan_text/features/main_shell/pages/organization_edit_page.dart';
import 'package:ai_scan_text/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('organization details open in read-only mode and wrap text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const title =
        'Казахский национальный исследовательский технический университет';
    const description =
        'Образовательная и научно-исследовательская организация с несколькими подразделениями и длинным официальным описанием.';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const OrganizationEditPage(
          organizationId: 1,
          organization: {
            'title': title,
            'city': 'ALA',
            'address':
                'Республика Казахстан, город Алматы, проспект Аль-Фараби, дом 71',
            'description': description,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(title), findsNWidgets(2));
    expect(find.text(description), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
