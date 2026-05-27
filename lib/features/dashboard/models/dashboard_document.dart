import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';

enum DocumentStatusType {
  success,
  processing,
  error,
  uploaded,
  cancelled,
}

class DashboardDocument {
  final String title;
  final String subtitle;
  final int? originalityPercent;
  final int? aiPercent;
  final String? statusText;
  final DocumentStatusType statusType;
  final DateTime? createdAt;
  final int? id;

  const DashboardDocument({
    required this.title,
    required this.subtitle,
    this.originalityPercent,
    this.aiPercent,
    this.statusText,
    required this.statusType,
    this.createdAt,
    this.id,
  });

  factory DashboardDocument.fromScanResult(ScanResult result) {
    final statusType = _statusType(result.status);
    final originality = result.aiPercentage > 0
        ? result.aiPercentage.round().clamp(0, 100)
        : null;
    final author = result.authorName?.trim();
    final date = result.createdAt;
    final dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    final details = [
      if (author != null && author.isNotEmpty) author,
      if (result.documentType != null && result.documentType!.isNotEmpty)
        result.documentType!,
      dateText,
    ];

    return DashboardDocument(
      id: result.id,
      title: result.title ?? result.fileName ?? 'Документ №${result.id}',
      subtitle: details.join(' · '),
      originalityPercent:
          statusType == DocumentStatusType.success ? originality : null,
      statusText: statusType == DocumentStatusType.success
          ? null
          : (result.statusDisplay ?? _statusLabel(result.status)),
      statusType: statusType,
      createdAt: result.createdAt,
    );
  }

  static DocumentStatusType _statusType(String? status) {
    return switch (status?.toUpperCase()) {
      'CH' || 'COMPLETED' || 'DONE' || 'SUCCESS' => DocumentStatusType.success,
      'PR' || 'PROCESSING' || 'PENDING' => DocumentStatusType.processing,
      'UP' || 'UPLOADED' || 'SUBMITTED' => DocumentStatusType.uploaded,
      'FA' || 'FAILED' || 'ERROR' => DocumentStatusType.error,
      'CANCELLED' || 'CANCELED' => DocumentStatusType.cancelled,
      _ => DocumentStatusType.processing,
    };
  }

  static String _statusLabel(String? status) {
    return switch (status?.toUpperCase()) {
      'CH' || 'COMPLETED' || 'DONE' || 'SUCCESS' => 'Проверен',
      'PR' || 'PROCESSING' || 'PENDING' => 'Проверяется',
      'UP' || 'UPLOADED' || 'SUBMITTED' => 'Загружен',
      'FA' || 'FAILED' || 'ERROR' => 'Ошибка',
      'CANCELLED' || 'CANCELED' => 'Отменен',
      _ => 'В обработке',
    };
  }

  Color get statusColor {
    return switch (statusType) {
      DocumentStatusType.success => const Color(0xFF16A34A),
      DocumentStatusType.processing => const Color(0xFFF59E0B),
      DocumentStatusType.error => const Color(0xFFEF4444),
      DocumentStatusType.uploaded => OySynDocumentColors.blue,
      DocumentStatusType.cancelled => const Color(0xFF6B7280),
    };
  }

  Color get statusBackground {
    return switch (statusType) {
      DocumentStatusType.success => const Color(0xFFE8F8EF),
      DocumentStatusType.processing => const Color(0xFFFFF3DE),
      DocumentStatusType.error => const Color(0xFFFFEAEA),
      DocumentStatusType.uploaded => const Color(0xFFEAF0FF),
      DocumentStatusType.cancelled => const Color(0xFFF3F4F6),
    };
  }

  Color get aiBackground => const Color(0xFFF0E2FF);
  Color get aiColor => const Color(0xFF8B3FF6);
}

class OySynDocumentColors {
  const OySynDocumentColors._();

  static const blue = Color(0xFF3F73F6);
}
