import 'package:ai_scan_text/widgets/pin_code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PIN input requests a numeric keyboard and completes at 4 digits',
      (tester) async {
    String? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinCodeInput(onCompleted: (value) => completed = value),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.number);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();

    expect(completed, '1234');
  });
}
