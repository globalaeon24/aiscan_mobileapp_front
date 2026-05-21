import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../dashboard/data/demo_dashboard_data.dart';
import '../../dashboard/widgets/dashboard_header.dart';
import '../../dashboard/widgets/document_card.dart';
import '../../dashboard/widgets/month_summary_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: DashboardHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: SliverList.list(
            children: [
              Text(
                'Привет, ${DemoDashboardData.userName}',
                style: OySynTextStyles.welcomeTitle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Вот что происходит с твоими документами',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),
              const MonthSummaryCard(),
              const SizedBox(height: 34),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Последние документы',
                      style: OySynTextStyles.recentDocumentsTitle,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2F6BFF),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Все ->',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final document in DemoDashboardData.documents) ...[
                DocumentCard(document: document),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
