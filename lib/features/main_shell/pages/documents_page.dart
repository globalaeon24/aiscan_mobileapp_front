import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../dashboard/data/demo_dashboard_data.dart';
import '../../dashboard/widgets/document_card.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Text(
          'Документы',
          style: OySynTextStyles.sectionTitle,
        ),
        const SizedBox(height: 18),
        for (final document in DemoDashboardData.documents) ...[
          DocumentCard(document: document),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
