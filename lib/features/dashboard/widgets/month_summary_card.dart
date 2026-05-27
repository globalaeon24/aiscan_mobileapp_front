import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MonthSummaryCard extends StatelessWidget {
  final int totalDocuments;
  final int averageOriginality;
  final int checksAvailable;

  const MonthSummaryCard({
    super.key,
    required this.totalDocuments,
    required this.averageOriginality,
    required this.checksAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OySynAuthTokens.deepBlue,
            OySynAuthTokens.primaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: OySynAuthTokens.primaryBlue.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сводка проверок',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: '$totalDocuments',
                  label: 'Всего',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  value: '$averageOriginality%',
                  label: 'Средний %',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  value: '$checksAvailable',
                  label: 'Доступно\nпроверок',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
