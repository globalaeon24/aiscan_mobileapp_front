import 'package:flutter/material.dart';

enum DocumentStatusType {
  success,
  processing,
  error,
}

class DashboardDocument {
  final String title;
  final String subtitle;
  final int? originalityPercent;
  final int? aiPercent;
  final String? statusText;
  final DocumentStatusType statusType;

  const DashboardDocument({
    required this.title,
    required this.subtitle,
    this.originalityPercent,
    this.aiPercent,
    this.statusText,
    required this.statusType,
  });

  Color get statusColor {
    return switch (statusType) {
      DocumentStatusType.success => const Color(0xFF16A34A),
      DocumentStatusType.processing => const Color(0xFFF59E0B),
      DocumentStatusType.error => const Color(0xFFEF4444),
    };
  }

  Color get statusBackground {
    return switch (statusType) {
      DocumentStatusType.success => const Color(0xFFE8F8EF),
      DocumentStatusType.processing => const Color(0xFFFFF3DE),
      DocumentStatusType.error => const Color(0xFFFFEAEA),
    };
  }

  Color get aiBackground => const Color(0xFFF0E2FF);
  Color get aiColor => const Color(0xFF8B3FF6);
}
