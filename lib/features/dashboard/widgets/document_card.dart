import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/dashboard_document.dart';

class DocumentCard extends StatelessWidget {
  final DashboardDocument document;

  const DocumentCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: OySynAuthTokens.primaryBlue,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
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
                    color: Colors.black,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  document.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DocumentStatuses(document: document),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Icon(Icons.circle, color: color, size: 10),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
