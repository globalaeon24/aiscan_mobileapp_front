import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../services/scan_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../models/scan_result.dart';
import '../../../screens/scan_details_screen.dart';
import '../../dashboard/models/dashboard_document.dart';
import '../../dashboard/widgets/dashboard_header.dart';
import '../../dashboard/widgets/document_card.dart';
import '../../dashboard/widgets/month_summary_card.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onCheck;
  final VoidCallback onDocuments;

  const DashboardPage({
    super.key,
    required this.onCheck,
    required this.onDocuments,
  });

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
      results: results,
      documents: docs,
      totalDocuments: docs.length,
      averageOriginality: avg,
      checksAvailable: _asInt(user?['checks_available']),
      monthlyDocuments: results.where(_isCurrentMonth).length,
    );
  }

  static bool _isCurrentMonth(ScanResult result) {
    final now = DateTime.now();
    return result.createdAt.year == now.year &&
        result.createdAt.month == now.month;
  }

  void _openResult(BuildContext context, ScanResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ScanDetailsScreen(result: result, loadFromBackend: true),
      ),
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
              SliverToBoxAdapter(
                child: DashboardHeader(
                  checksAvailable: data?.checksAvailable ?? 0,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'Привет, ${TokenStorage.displayName(data?.user)}',
                      style: OySynTextStyles.welcomeTitle,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Проверь работу на уникальность за 30 секунд',
                      style: TextStyle(
                        color: Color(0xFF6A7590),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _UploadAction(onTap: widget.onCheck),
                    const SizedBox(height: 14),
                    MonthSummaryCard(
                      totalDocuments: data?.totalDocuments ?? 0,
                      averageOriginality: data?.averageOriginality ?? 0,
                      monthlyDocuments: data?.monthlyDocuments ?? 0,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Последние документы',
                            style: OySynTextStyles.recentDocumentsTitle,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onDocuments,
                          child: const Text('Все'),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                      for (final result
                          in (data?.results ?? const <ScanResult>[])
                              .take(2)) ...[
                        DocumentCard(
                          document: DashboardDocument.fromScanResult(result),
                          onTap: () => _openResult(context, result),
                        ),
                        const SizedBox(height: 10),
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
  final List<ScanResult> results;
  final List<DashboardDocument> documents;
  final int totalDocuments;
  final int averageOriginality;
  final int checksAvailable;
  final int monthlyDocuments;

  const _DashboardData({
    required this.user,
    required this.results,
    required this.documents,
    required this.totalDocuments,
    required this.averageOriginality,
    required this.checksAvailable,
    required this.monthlyDocuments,
  });
}

class _UploadAction extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFD0F5), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3E7BFF), Color(0xFF2F5FE0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          OySynAuthTokens.primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.file_upload_outlined,
                    color: Colors.white, size: 27),
              ),
              const SizedBox(height: 12),
              const Text(
                'Проверить документ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Выберите файл · PDF, DOCX, DOC',
                style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
