import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../services/scan_service.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/models/dashboard_document.dart';
import '../../dashboard/widgets/document_card.dart';

enum _PeriodFilter {
  all('Все', null),
  week('7 дней', Duration(days: 7)),
  month('30 дней', Duration(days: 30)),
  quarter('90 дней', Duration(days: 90));

  final String label;
  final Duration? duration;

  const _PeriodFilter(this.label, this.duration);
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  late Future<CheckHistoryPage> _future;
  _PeriodFilter _period = _PeriodFilter.all;
  int _page = 1;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CheckHistoryPage> _load() {
    return ScanService.getHistoryPage(page: _page, pageSize: _pageSize);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _goToPage(int page) {
    if (page < 1 || page == _page) return;
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  List<ScanResult> _filteredItems(List<ScanResult> items) {
    final now = DateTime.now();
    final from =
        _period.duration == null ? null : now.subtract(_period.duration!);

    return items.where((item) {
      final matchesPeriod = from == null || !item.createdAt.isBefore(from);
      final haystack = [
        item.title,
        item.fileName,
        item.authorName,
        item.documentType,
      ].whereType<String>().join(' ').toLowerCase();
      final matchesSearch = _query.isEmpty || haystack.contains(_query);
      return matchesPeriod && matchesSearch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CheckHistoryPage>(
      future: _future,
      builder: (context, snapshot) {
        final pageData = snapshot.data;
        final filtered = _filteredItems(pageData?.items ?? const []);
        final documents =
            filtered.map(DashboardDocument.fromScanResult).toList();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Документы',
                      style: OySynTextStyles.sectionTitle,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _DocumentFilters(
                controller: _searchController,
                selectedPeriod: _period,
                onPeriodChanged: (period) => setState(() => _period = period),
              ),
              const SizedBox(height: 12),
              _PageSummary(
                page: _page,
                pageData: pageData,
                visibleCount: documents.length,
              ),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                _DocumentsMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Не удалось загрузить документы',
                  text: snapshot.error.toString(),
                )
              else if (!isLoading && documents.isEmpty)
                const _DocumentsMessage(
                  icon: Icons.search_off_rounded,
                  title: 'Проверки не найдены',
                  text:
                      'Измени поиск или период, чтобы увидеть больше проверок.',
                )
              else
                for (final document in documents) ...[
                  DocumentCard(document: document),
                  const SizedBox(height: 8),
                ],
              if (pageData != null && !snapshot.hasError) ...[
                const SizedBox(height: 10),
                _PaginationControls(
                  pageData: pageData,
                  onPrevious:
                      pageData.hasPrevious ? () => _goToPage(_page - 1) : null,
                  onNext: pageData.hasNext ? () => _goToPage(_page + 1) : null,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DocumentFilters extends StatelessWidget {
  final TextEditingController controller;
  final _PeriodFilter selectedPeriod;
  final ValueChanged<_PeriodFilter> onPeriodChanged;

  const _DocumentFilters({
    required this.controller,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Поиск по названию или автору',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final period in _PeriodFilter.values) ...[
                  ChoiceChip(
                    label: Text(period.label),
                    selected: selectedPeriod == period,
                    onSelected: (_) => onPeriodChanged(period),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: selectedPeriod == period
                          ? OySynAuthTokens.primaryBlue
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: const Color(0xFFEAF0FF),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selectedPeriod == period
                          ? OySynAuthTokens.primaryBlue.withValues(alpha: 0.32)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageSummary extends StatelessWidget {
  final int page;
  final CheckHistoryPage? pageData;
  final int visibleCount;

  const _PageSummary({
    required this.page,
    required this.pageData,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = pageData?.total;
    final totalText = total == null ? '' : ' из $total';
    return Text(
      'Страница $page · показано $visibleCount$totalText · сначала новые',
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final CheckHistoryPage pageData;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.pageData,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = pageData.totalPages;
    final label = totalPages == null
        ? 'Страница ${pageData.page}'
        : 'Страница ${pageData.page} из $totalPages';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Назад'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Дальше'),
          ),
        ),
      ],
    );
  }
}

class _DocumentsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _DocumentsMessage({
    required this.icon,
    required this.title,
    required this.text,
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
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
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
