import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../services/scan_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/models/dashboard_document.dart';
import '../../dashboard/widgets/dashboard_header.dart';
import '../../dashboard/widgets/document_card.dart';
import '../../dashboard/widgets/month_summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await ScanService.getHistory();
    final user = await _loadUser();
    final docs = results.map(DashboardDocument.fromScanResult).toList();
    final completed = docs
        .where((doc) => doc.statusType == DocumentStatusType.success)
        .toList();
    final avg = completed.isEmpty
        ? 0
        : (completed
                    .map((doc) => doc.originalityPercent ?? 0)
                    .reduce((a, b) => a + b) /
                completed.length)
            .round();

    return _DashboardData(
      user: user,
      documents: docs,
      totalDocuments: docs.length,
      averageOriginality: avg,
      checksAvailable: _asInt(user?['checks_available']),
    );
  }

  Future<Map<String, dynamic>?> _loadUser() async {
    final cached = await TokenStorage.getUser();
    try {
      final fresh = await ProfileService.getProfile();
      if (fresh.isNotEmpty) {
        await TokenStorage.saveUser(fresh);
        return fresh;
      }
    } catch (_) {
      return cached;
    }
    return cached;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: DashboardHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                sliver: SliverList.list(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Привет, ',
                        children: [
                          TextSpan(
                            text: TokenStorage.displayName(data?.user),
                            style: const TextStyle(
                              color: OySynAuthTokens.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      style: OySynTextStyles.welcomeTitle,
                    ),
                    const SizedBox(height: 20),
                    MonthSummaryCard(
                      totalDocuments: data?.totalDocuments ?? 0,
                      averageOriginality: data?.averageOriginality ?? 0,
                      checksAvailable: data?.checksAvailable ?? 0,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Последние документы',
                            style: OySynTextStyles.recentDocumentsTitle,
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.hasError)
                      _DashboardMessage(
                        icon: Icons.wifi_off_rounded,
                        text: 'Не удалось загрузить документы',
                        detail: snapshot.error.toString(),
                      )
                    else if (data != null && data.documents.isEmpty)
                      const _DashboardMessage(
                        icon: Icons.description_outlined,
                        text: 'Документов пока нет',
                        detail: 'Загрузи первый документ для проверки',
                      )
                    else
                      for (final document
                          in (data?.documents ?? const <DashboardDocument>[])
                              .take(5)) ...[
                        DocumentCard(document: document),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardData {
  final Map<String, dynamic>? user;
  final List<DashboardDocument> documents;
  final int totalDocuments;
  final int averageOriginality;
  final int checksAvailable;

  const _DashboardData({
    required this.user,
    required this.documents,
    required this.totalDocuments,
    required this.averageOriginality,
    required this.checksAvailable,
  });
}

class _DashboardMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String detail;

  const _DashboardMessage({
    required this.icon,
    required this.text,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: OySynAuthTokens.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
