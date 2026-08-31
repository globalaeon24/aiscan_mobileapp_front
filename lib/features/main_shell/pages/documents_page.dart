import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../screens/scan_details_screen.dart';
import '../../../services/scan_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';
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
  String? _statusFilter;
  bool _newestFirst = true;
  int _page = 1;
  String _query = '';
  int _documentTab = 0;
  int? _folderId;

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
    return ScanService.getHistoryPage(
      page: _page,
      pageSize: _pageSize,
      folderId: _folderId,
    );
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

  void _openResult(ScanResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanDetailsScreen(
          result: result,
          loadFromBackend: true,
        ),
      ),
    );
  }

  Future<void> _showFolders() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoldersSheet(
        future: ScanService.getFolders(),
        selectedId: _folderId,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _folderId = selected < 0 ? null : selected;
      _page = 1;
      _future = _load();
    });
  }

  List<ScanResult> _filteredItems(List<ScanResult> items) {
    final now = DateTime.now();
    final from =
        _period.duration == null ? null : now.subtract(_period.duration!);

    return items.where((item) {
      final matchesPeriod = from == null || !item.createdAt.isBefore(from);
      final matchesStatus =
          _statusFilter == null || item.status == _statusFilter;
      final haystack = [
        item.title,
        item.fileName,
        item.authorName,
        item.documentType,
      ].whereType<String>().join(' ').toLowerCase();
      final matchesSearch = _query.isEmpty || haystack.contains(_query);
      return matchesPeriod && matchesStatus && matchesSearch;
    }).toList()
      ..sort((a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CheckHistoryPage>(
      future: _future,
      builder: (context, snapshot) {
        final pageData = snapshot.data;
        final filtered = _filteredItems(pageData?.items ?? const []);
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
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _showFolders,
                    tooltip: 'Папки',
                    icon: Icon(
                      _folderId == null
                          ? Icons.folder_outlined
                          : Icons.folder_rounded,
                      color: _folderId == null
                          ? null
                          : OySynAuthTokens.primaryBlue,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: OySynAuthTokens.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DocumentTabs(
                selected: _documentTab,
                onChanged: (value) => setState(() => _documentTab = value),
              ),
              const SizedBox(height: 12),
              _DocumentFilters(
                controller: _searchController,
                selectedPeriod: _period,
                onPeriodChanged: (period) => setState(() => _period = period),
                statusFilter: _statusFilter,
                onStatusChanged: (status) =>
                    setState(() => _statusFilter = status),
                newestFirst: _newestFirst,
                onSortChanged: () =>
                    setState(() => _newestFirst = !_newestFirst),
              ),
              const SizedBox(height: 12),
              if (_documentTab == 1)
                const _PairChecksState()
              else if (snapshot.hasError)
                _DocumentsMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Не удалось загрузить документы',
                  text: snapshot.error.toString(),
                )
              else if (!isLoading && filtered.isEmpty)
                const _DocumentsMessage(
                  icon: Icons.search_off_rounded,
                  title: 'Проверки не найдены',
                  text:
                      'Измени поиск или период, чтобы увидеть больше проверок.',
                )
              else
                for (final result in filtered) ...[
                  DocumentCard(
                    document: DashboardDocument.fromScanResult(result),
                    detailed: true,
                    onTap: () => _openResult(result),
                  ),
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
  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;
  final bool newestFirst;
  final VoidCallback onSortChanged;

  const _DocumentFilters({
    required this.controller,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.newestFirst,
    required this.onSortChanged,
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
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final value = await showOySynChoiceSheet<_PeriodFilter>(
                    context,
                    title: 'Период',
                    selected: selectedPeriod,
                    choices: _PeriodFilter.values
                        .map((item) => OySynChoice(item, item.label))
                        .toList(),
                  );
                  if (value != null) onPeriodChanged(value);
                },
                borderRadius: BorderRadius.circular(10),
                child: _FilterButton(
                    icon: Icons.calendar_today_outlined,
                    label: selectedPeriod == _PeriodFilter.all
                        ? 'Период'
                        : selectedPeriod.label),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final value = await showOySynChoiceSheet<String?>(
                    context,
                    title: 'Статус',
                    selected: statusFilter,
                    choices: const [
                      OySynChoice(null, 'Все статусы'),
                      OySynChoice('CH', 'Проверено'),
                      OySynChoice('PR', 'Проверяется'),
                      OySynChoice('FA', 'Ошибка'),
                    ],
                  );
                  onStatusChanged(value);
                },
                borderRadius: BorderRadius.circular(10),
                child: _FilterButton(
                    icon: Icons.filter_list_rounded,
                    label: statusFilter == null
                        ? 'Статус'
                        : _statusLabel(statusFilter!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onSortChanged,
                borderRadius: BorderRadius.circular(10),
                child: _FilterButton(
                    icon: Icons.sort_rounded,
                    label: newestFirst ? 'Новые' : 'Старые'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'CH' => 'Проверено',
        'PR' => 'Проверяется',
        'FA' => 'Ошибка',
        _ => 'Статус',
      };
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FilterButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF5A6577)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF5A6577),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DocumentTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DocumentTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab('Мои документы', 0)),
        const SizedBox(width: 8),
        Expanded(child: _tab('Парные проверки', 1)),
      ],
    );
  }

  Widget _tab(String label, int value) => InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected == value ? OySynAuthTokens.primaryBlue : Colors.white,
            border: Border.all(
                color: selected == value
                    ? OySynAuthTokens.primaryBlue
                    : OySynAuthTokens.divider),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected == value
                      ? Colors.white
                      : const Color(0xFF5A6577),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _PairChecksState extends StatelessWidget {
  const _PairChecksState();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: OySynAuthTokens.divider),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: 36, color: OySynAuthTokens.primaryBlue),
            SizedBox(height: 12),
            Text('Парные проверки',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'Core пока не предоставляет список парных проверок через мобильный API.',
              textAlign: TextAlign.center,
              style: TextStyle(color: OySynAuthTokens.textMuted, height: 1.4),
            ),
          ],
        ),
      );
}

class _FoldersSheet extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final int? selectedId;

  const _FoldersSheet({required this.future, required this.selectedId});

  @override
  Widget build(BuildContext context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: OySynAuthTokens.appBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: SizedBox(width: 42, child: Divider(thickness: 4))),
            const SizedBox(height: 10),
            const Text('Папки', style: OySynTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Не удалось загрузить папки',
                          style: TextStyle(color: OySynAuthTokens.textMuted)),
                    );
                  }
                  final folders = snapshot.data ?? const [];
                  if (folders.isEmpty) {
                    return const Center(
                      child: Text('Папок пока нет',
                          style: TextStyle(color: OySynAuthTokens.textMuted)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: folders.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(-1),
                          tileColor: selectedId == null
                              ? const Color(0xFFEAF0FF)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: const BorderSide(
                                  color: OySynAuthTokens.divider)),
                          leading: const Icon(Icons.folder_open_rounded,
                              color: OySynAuthTokens.primaryBlue),
                          title: const Text('Все документы'),
                          trailing: selectedId == null
                              ? const Icon(Icons.check_circle_rounded,
                                  color: OySynAuthTokens.primaryBlue)
                              : null,
                        );
                      }
                      final folder = folders[index - 1];
                      final id = folder['id'] is num
                          ? (folder['id'] as num).toInt()
                          : int.tryParse('${folder['id']}');
                      final active = id != null && id == selectedId;
                      return ListTile(
                        onTap: id == null
                            ? null
                            : () => Navigator.of(context).pop(id),
                        tileColor:
                            active ? const Color(0xFFEAF0FF) : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                            side: const BorderSide(
                                color: OySynAuthTokens.divider)),
                        leading: const Icon(Icons.folder_rounded,
                            color: OySynAuthTokens.primaryBlue),
                        title: Text(folder['name']?.toString() ?? 'Папка'),
                        trailing: active
                            ? const Icon(Icons.check_circle_rounded,
                                color: OySynAuthTokens.primaryBlue)
                            : Text('${folder['documents_count'] ?? 0}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
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
