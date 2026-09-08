import 'package:ai_scan_text/features/main_shell/widgets/main_bottom_nav.dart';
import 'package:ai_scan_text/models/scan_result.dart';
import 'package:ai_scan_text/screens/login_register_screen.dart';
import 'package:ai_scan_text/screens/scan_details_screen.dart';
import 'package:ai_scan_text/screens/security_setup_screen.dart';
import 'package:ai_scan_text/theme/app_theme.dart';
import 'package:ai_scan_text/widgets/oysyn_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compactAndroid = Size(360, 640);

  Future<void> pumpCompact(
    WidgetTester tester,
    Widget child, {
    Size size = compactAndroid,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
          ),
          child: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  }

  testWidgets('login fits a compact Android viewport', (tester) async {
    await pumpCompact(tester, const LoginRegisterScreen());
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('PIN setup fits a compact Android viewport', (tester) async {
    await pumpCompact(tester, const SecuritySetupScreen());
    expect(find.text('Создайте код входа'), findsOneWidget);
  });

  testWidgets('five-item navigation stays above Android system UI',
      (tester) async {
    await pumpCompact(
      tester,
      Scaffold(
        bottomNavigationBar: MainBottomNav(
          currentIndex: 2,
          onChanged: (_) {},
          showOrganization: true,
        ),
      ),
    );
    expect(find.text('Организация'), findsOneWidget);
  });

  testWidgets('report and its fixed action bar fit compact Android',
      (tester) async {
    final result = ScanResult(
      id: 101,
      title: 'Дипломная работа с очень длинным названием',
      status: 'CH',
      statusDisplay: 'Проверено',
      originalityPercentage: 86.39,
      aiPercentage: 54.07,
      scannedText: 'Текст документа',
      highlightedText: null,
      createdAt: DateTime(2026, 9, 3),
      aiFragments: const [],
    );

    await pumpCompact(
      tester,
      ScanDetailsScreen(result: result, loadFromBackend: false),
    );
    expect(find.text('Скачать справку о проверке'), findsOneWidget);
    expect(find.text('Скачать полный отчёт'), findsOneWidget);
  });

  testWidgets('choice sheet remains scrollable above Android system UI',
      (tester) async {
    await pumpCompact(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showOySynChoiceSheet<int>(
                context,
                title: 'Длинный список вариантов',
                selected: 0,
                choices: List.generate(
                  20,
                  (index) => OySynChoice(index, 'Вариант ${index + 1}'),
                ),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.text('Длинный список вариантов'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
