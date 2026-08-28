import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MonthSummaryCard extends StatelessWidget {
  final int totalDocuments;
  final int averageOriginality;
  final int monthlyDocuments;

  const MonthSummaryCard({
    super.key,
    required this.totalDocuments,
    required this.averageOriginality,
    required this.monthlyDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OySynAuthTokens.divider),
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
          Expanded(
              child: _SummaryMetric(
                  value: '$totalDocuments', label: 'Всего проверок')),
          const _Divider(),
          Expanded(
            child: _SummaryMetric(
              value: '$averageOriginality%',
              label: 'Средняя ориг.',
              valueColor: const Color(0xFF148A4E),
            ),
          ),
          const _Divider(),
          Expanded(
              child: _SummaryMetric(
                  value: '$monthlyDocuments', label: 'За месяц')),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 42,
      child: VerticalDivider(color: Color(0xFFEEF1F8), width: 1),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _SummaryMetric({
    required this.value,
    required this.label,
    this.valueColor = OySynAuthTokens.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF7A8399), fontSize: 11),
        ),
      ],
    );
  }
}
