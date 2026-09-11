import 'package:ai_scan_text/features/dashboard/models/dashboard_document.dart';
import 'package:ai_scan_text/models/scan_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScanResult result({
    String? title,
    String? fileName,
    String status = 'CH',
    double originality = 90,
  }) {
    return ScanResult(
      id: 42,
      title: title,
      fileName: fileName,
      status: status,
      originalityPercentage: originality,
      scannedText: '',
      highlightedText: null,
      createdAt: DateTime(2026, 9, 3),
      aiFragments: const [],
    );
  }

  test('uses the human title returned by Core', () {
    final document = DashboardDocument.fromScanResult(result(
      title: 'Диссертация Айдарбекова Т.Ж',
      fileName: 'Диссертация_Айдарбекова_Т.Ж_aMeRBlQ.docx',
    ));

    expect(document.title, 'Диссертация Айдарбекова Т.Ж');
  });

  test('cleans the storage suffix when Core title is missing', () {
    final document = DashboardDocument.fromScanResult(result(
      fileName: 'Диссертация_Айдарбекова_Т.Ж_aMeRBlQ.docx',
    ));

    expect(document.title, 'Диссертация_Айдарбекова_Т.Ж');
  });

  test('shows low originality as red', () {
    final document = DashboardDocument.fromScanResult(
      result(title: 'Низкая оригинальность', originality: 44.9),
    );

    expect(document.statusColor, const Color(0xFFD93D45));
    expect(document.statusBackground, const Color(0xFFFCE8EA));
  });

  test('keeps high originality green', () {
    final document = DashboardDocument.fromScanResult(
      result(title: 'Высокая оригинальность', originality: 97),
    );

    expect(document.statusColor, const Color(0xFF16A34A));
  });

  test('processing checks hide results and cannot be opened', () {
    final document = DashboardDocument.fromScanResult(
      result(originality: 0, status: 'PR'),
    );

    expect(document.statusText, 'Проверка');
    expect(document.originalityPercent, isNull);
    expect(document.aiPercent, isNull);
    expect(document.canOpen, isFalse);
    expect(document.isTerminal, isFalse);
  });

  test('completed checks expose results and can be opened', () {
    final document = DashboardDocument.fromScanResult(
      result(originality: 86, status: 'CH'),
    );

    expect(document.statusText, isNull);
    expect(document.originalityPercent, 86);
    expect(document.canOpen, isTrue);
    expect(document.isTerminal, isTrue);
  });
}
