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
  final String? fileName;
  final String? documentType;
  final int? fileSize;
  final double? originalityPercent;
  final double? aiPercent;
  final String? statusText;
  final DocumentStatusType statusType;
  final DateTime? createdAt;
  final int? id;

  const DashboardDocument({
    required this.title,
    required this.subtitle,
    this.fileName,
    this.documentType,
    this.fileSize,
    this.originalityPercent,
    this.aiPercent,
    this.statusText,
    required this.statusType,
    this.createdAt,
    this.id,
  });

  factory DashboardDocument.fromScanResult(ScanResult result) {
    final statusType =
        result.isStale ? DocumentStatusType.error : _statusType(result.status);
    final originality = result.originalityPercentage.clamp(0, 100).toDouble();
    final ai = result.aiPercentage?.clamp(0, 100).toDouble();
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
      fileName: result.fileName,
      documentType: result.documentType,
      fileSize: result.fileSize,
      originalityPercent:
          statusType == DocumentStatusType.success ? originality : null,
      aiPercent: statusType == DocumentStatusType.success ? ai : null,
      statusText: result.isStale
          ? 'Проверка не завершена'
          : statusType == DocumentStatusType.success
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

  String get fileType {
    final value = (fileName ?? title).toLowerCase();
    if (value.endsWith('.pdf')) return 'PDF';
    if (value.endsWith('.docx')) return 'DOCX';
    if (value.endsWith('.txt')) return 'TXT';
    return 'DOC';
  }

  String get detailSubtitle {
    final author = subtitle.split(' · ').firstWhere(
          (part) =>
              !part.contains(RegExp(r'^\d{2}\.\d{2}$')) && part != documentType,
          orElse: () => 'Автор не указан',
        );
    return [
      documentType?.trim().isNotEmpty == true ? documentType! : 'Документ',
      if (fileSize != null) _formatBytes(fileSize!),
      author.trim().isEmpty ? 'Автор не указан' : author,
    ].join(' · ');
  }

  String get dateLabel {
    final date = createdAt;
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String get recommendationLabel => (originalityPercent ?? 100) < 60
      ? 'Низкая оригинальность'
      : 'Рекомендация';

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  }
}

class OySynDocumentColors {
  const OySynDocumentColors._();

  static const blue = Color(0xFF3F73F6);
}
