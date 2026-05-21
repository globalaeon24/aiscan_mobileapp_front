import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/demo_dashboard_data.dart';

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: OySynAuthTokens.primaryBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сводка за месяц',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: _SummaryMetric(
                  value: '${DemoDashboardData.totalDocuments}',
                  label: 'Всего',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  value: '${DemoDashboardData.averageOriginality}%',
                  label: 'Средний %',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  value: '${DemoDashboardData.completedWorks}',
                  label: 'Прошедших\nработ',
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
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
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
              fontSize: 22,
              height: 0.95,
              fontWeight: FontWeight.w800,
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
