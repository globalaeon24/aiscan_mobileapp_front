import 'package:flutter/material.dart';

import '../models/dashboard_document.dart';

class DocumentCard extends StatelessWidget {
  final DashboardDocument document;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7ECF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF142350).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 44,
                decoration: BoxDecoration(
                  color: _fileBackground(document.title),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  _fileType(document.title),
                  style: TextStyle(
                    color: _fileColor(document.title),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _DocumentStatuses(document: document),
            ],
          ),
        ),
      ),
    );
  }

  static String _fileType(String title) {
    final value = title.toLowerCase();
    if (value.endsWith('.pdf') || value.contains('pdf')) return 'PDF';
    if (value.endsWith('.docx') || value.contains('word')) return 'DOCX';
    return 'DOC';
  }

  static Color _fileBackground(String title) => _fileType(title) == 'PDF'
      ? const Color(0xFFFDEBEA)
      : const Color(0xFFE8EEFF);

  static Color _fileColor(String title) => _fileType(title) == 'PDF'
      ? const Color(0xFFE0463A)
      : const Color(0xFF2F5FE0);
}

class _DocumentStatuses extends StatelessWidget {
  final DashboardDocument document;

  const _DocumentStatuses({required this.document});

  @override
  Widget build(BuildContext context) {
    if (document.statusText != null) {
      return _StatusPill(
        text: document.statusText!,
        color: document.statusColor,
        backgroundColor: document.statusBackground,
      );
    }

    return Wrap(
      spacing: 6,
      children: [
        if (document.originalityPercent != null)
          _StatusPill(
            text: '${document.originalityPercent}%',
            color: document.statusColor,
            backgroundColor: document.statusBackground,
          ),
        if (document.aiPercent != null)
          _StatusPill(
            text: 'AI ${document.aiPercent}%',
            color: document.aiColor,
            backgroundColor: document.aiBackground,
            showDot: false,
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;
  final bool showDot;

  const _StatusPill({
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
