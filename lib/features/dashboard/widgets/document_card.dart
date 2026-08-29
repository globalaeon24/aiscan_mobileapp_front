import 'package:flutter/material.dart';

import '../models/dashboard_document.dart';

class DocumentCard extends StatelessWidget {
  final DashboardDocument document;
  final VoidCallback? onTap;
  final bool detailed;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.detailed = false,
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
          constraints: BoxConstraints(minHeight: detailed ? 110 : 68),
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
          child: Column(
            children: [
              Row(
                children: [
                  _FileTypeIcon(type: document.fileType),
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
                            color: Color(0xFF12203E),
                            fontSize: 14,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detailed
                              ? document.detailSubtitle
                              : document.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8A94A6),
                            fontSize: 11.5,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _DocumentStatuses(document: document),
                ],
              ),
              if (detailed) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    _RecommendationPill(document: document),
                    const Spacer(),
                    Text(
                      document.dateLabel,
                      style: const TextStyle(
                        color: Color(0xFF9AA4B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTypeIcon extends StatelessWidget {
  final String type;

  const _FileTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final pdf = type == 'PDF';
    return Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        color: pdf ? const Color(0xFFFDEBEA) : const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        type,
        style: TextStyle(
          color: pdf ? const Color(0xFFE0463A) : const Color(0xFF2F5FE0),
          fontSize: type.length > 3 ? 8 : 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecommendationPill extends StatelessWidget {
  final DashboardDocument document;

  const _RecommendationPill({required this.document});

  @override
  Widget build(BuildContext context) {
    final low = (document.originalityPercent ?? 100) < 60;
    final color = low ? const Color(0xFFD23B41) : const Color(0xFFC67F09);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: low ? const Color(0xFFFCEAEA) : const Color(0xFFFCF1DE),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!low) ...[
            Icon(Icons.warning_amber_rounded, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            document.recommendationLabel,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (document.originalityPercent != null)
          _StatusPill(
            text: '${document.originalityPercent!.toStringAsFixed(1)}%',
            color: document.statusColor,
            backgroundColor: document.statusBackground,
          ),
        if (document.aiPercent != null) ...[
          const SizedBox(height: 4),
          _StatusPill(
            text: 'AI ${document.aiPercent!.toStringAsFixed(1)}%',
            color: document.aiColor,
            backgroundColor: document.aiBackground,
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _StatusPill(
      {required this.text, required this.color, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: backgroundColor, borderRadius: BorderRadius.circular(7)),
      child: Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: 11.5,
            height: 1,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
