import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../screens/scan_details_screen.dart';
import '../../../services/scan_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';
import '../../dashboard/models/dashboard_document.dart';
import '../../dashboard/widgets/document_card.dart';
import '../utils/document_list_filter.dart';
import 'deleted_documents_page.dart';
import 'pair_checks_panel.dart';

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
  final ScanResult? pendingResult;

  const DocumentsPage({super.key, this.pendingResult});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  late Future<List<ScanResult>> _future;
  _PeriodFilter _period = _PeriodFilter.all;
  String? _statusFilter;
  bool _newestFirst = true;
  int _page = 1;
  String _query = '';
  int _documentTab = 0;
  int? _folderId;
  final Set<int> _deletingDocumentIds = <int>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _page = 1;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<ScanResult>> _load() async {
    try {
      final items = await ScanService.getAllHistory(folderId: _folderId);
      final pending = widget.pendingResult;
      if (_folderId == null &&
          pending != null &&
          !items.any((item) => item.id == pending.id)) {
        items.insert(0, pending);
      }
      _scheduleRefresh(items);
      if (_folderId == null) await TokenStorage.saveHistory(items);
      return items;
    } catch (_) {
      if (_folderId == null) {
        final cached = await TokenStorage.getHistory();
        final pending = widget.pendingResult;
        if (pending != null && !cached.any((item) => item.id == pending.id)) {
          cached.insert(0, pending);
        }
        if (cached.isNotEmpty) {
          _scheduleRefresh(cached);
          return cached;
        }
      }
      rethrow;
    }
  }

  void _scheduleRefresh(List<ScanResult> items) {
    _refreshTimer?.cancel();
    final hasPending = items
        .map(DashboardDocument.fromScanResult)
        .any((document) => !document.isTerminal);
    if (!hasPending) return;
    _refreshTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _goToPage(int page, int totalPages) {
    if (page < 1 || page > totalPages || page == _page) return;
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _deleteDocument(ScanResult result) async {
    final confirmed = await showOySynActionDialog(
      context,
      title: 'Удалить документ?',
      message:
          '«${result.title ?? result.fileName ?? 'Документ'}» будет перемещён в раздел удалённых документов.',
      confirmLabel: 'Удалить',
      icon: Icons.delete_outline_rounded,
      confirmIcon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingDocumentIds.add(result.id));

    try {
      await ScanService.deleteCheck(result.id);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Документ удалён')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingDocumentIds.remove(result.id));
      }
    }
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoldersSheet(
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

  Future<void> _assignDocumentToFolder(ScanResult result) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FoldersSheet(selectedId: null),
    );
    if (selected == null || !mounted) return;
    try {
      await ScanService.assignCheckFolder(
        result.id,
        selected < 0 ? null : selected,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Папка документа изменена.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _openDeletedDocuments(Map<String, dynamic>? user) {
    if (user == null || user['role']?.toString().toUpperCase() != 'ADM') return;
    final rawId = user['organization_id'] ?? user['core_organization_id'];
    final organizationId =
        rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
    if (organizationId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeletedDocumentsPage(organizationId: organizationId),
      ),
    );
  }

  List<ScanResult> _filteredItems(List<ScanResult> items) {
    return DocumentListFilter.apply(
      items: items,
      query: _query,
      status: _statusFilter,
      period: _period.duration,
      newestFirst: _newestFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScanResult>>(
      future: _future,
      builder: (context, snapshot) {
        final filtered = _filteredItems(snapshot.data ?? const []);
        final totalPages =
            filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
        final effectivePage = _page.clamp(1, totalPages);
        final visible = DocumentListFilter.page(
          items: filtered,
          page: effectivePage,
          pageSize: _pageSize,
        );
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
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
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: TokenStorage.userListenable,
                    builder: (context, user, _) {
                      final rawId = user?['organization_id'] ??
                          user?['core_organization_id'];
                      final isAdmin =
                          user?['role']?.toString().toUpperCase() == 'ADM' &&
                              rawId != null;
                      if (!isAdmin) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () => _openDeletedDocuments(user),
                          tooltip: 'Удалённые документы',
                          icon: const Icon(Icons.delete_outline_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: OySynAuthTokens.divider,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                onPeriodChanged: (period) => setState(() {
                  _period = period;
                  _page = 1;
                }),
                statusFilter: _statusFilter,
                onStatusChanged: (status) => setState(() {
                  _statusFilter = status;
                  _page = 1;
                }),
                newestFirst: _newestFirst,
                onSortChanged: () => setState(() {
                  _newestFirst = !_newestFirst;
                  _page = 1;
                }),
              ),
              const SizedBox(height: 12),
              if (_documentTab == 1)
                const PairChecksPanel()
              else if (snapshot.hasError)
                const _DocumentsMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Не удалось загрузить документы',
                  text:
                      'Проверьте соединение и потяните экран вниз, чтобы повторить загрузку.',
                )
              else if (!isLoading && filtered.isEmpty)
                const _DocumentsMessage(
                  icon: Icons.search_off_rounded,
                  title: 'Проверки не найдены',
                  text:
                      'Измени поиск или период, чтобы увидеть больше проверок.',
                )
              else
                for (final result in visible) ...[
                  Builder(builder: (context) {
                    final document = DashboardDocument.fromScanResult(result);
                    return DocumentCard(
                      document: document,
                      detailed: true,
                      onTap:
                          document.canOpen ? () => _openResult(result) : null,
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _assignDocumentToFolder(result),
                            tooltip: 'Переместить в папку',
                            icon: const Icon(Icons.drive_file_move_outlined),
                            color: OySynAuthTokens.primaryBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: _deletingDocumentIds.contains(result.id)
                                ? null
                                : () => _deleteDocument(result),
                            tooltip: 'Удалить документ',
                            icon: _deletingDocumentIds.contains(result.id)
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline_rounded),
                            color: const Color(0xFFDF3E48),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              if (_documentTab == 0 &&
                  snapshot.data != null &&
                  !snapshot.hasError) ...[
                const SizedBox(height: 10),
                _PaginationControls(
                  page: effectivePage,
                  totalPages: totalPages,
                  totalItems: filtered.length,
                  onPrevious: effectivePage > 1
                      ? () => _goToPage(effectivePage - 1, totalPages)
                      : null,
                  onNext: effectivePage < totalPages
                      ? () => _goToPage(effectivePage + 1, totalPages)
                      : null,
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

class _FoldersSheet extends StatefulWidget {
  final int? selectedId;

  const _FoldersSheet({required this.selectedId});

  @override
  State<_FoldersSheet> createState() => _FoldersSheetState();
}

class _FoldersSheetState extends State<_FoldersSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ScanService.getFolders();
  }

  Future<void> _createFolder() async {
    final name = await showOySynTextInputDialog(
      context,
      title: 'Новая папка',
      label: 'Название папки',
      confirmLabel: 'Создать',
      icon: Icons.create_new_folder_outlined,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final folder = await ScanService.createFolder(name.trim());
      final id = folder['id'] is num
          ? (folder['id'] as num).toInt()
          : int.tryParse('${folder['id']}');
      if (!mounted) return;
      if (id != null) {
        Navigator.of(context).pop(id);
        return;
      }
      setState(() {
        _future = ScanService.getFolders();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _renameFolder(Map<String, dynamic> folder) async {
    final id = folder['id'] is num
        ? (folder['id'] as num).toInt()
        : int.tryParse('${folder['id']}');
    if (id == null) return;
    final currentName = folder['name']?.toString() ?? '';
    final name = await showOySynTextInputDialog(
      context,
      title: 'Переименовать папку',
      label: 'Название папки',
      confirmLabel: 'Сохранить',
      initialValue: currentName,
      icon: Icons.drive_file_rename_outline_rounded,
    );
    if (name == null || name.trim().isEmpty || name.trim() == currentName) {
      return;
    }
    try {
      await ScanService.renameFolder(id, name.trim());
      if (!mounted) return;
      setState(() {
        _future = ScanService.getFolders();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Папка переименована')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + oysynSystemBottomInset(context),
        ),
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
            Row(
              children: [
                const Expanded(
                  child: Text('Папки', style: OySynTextStyles.sectionTitle),
                ),
                IconButton(
                  onPressed: _createFolder,
                  tooltip: 'Создать папку',
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
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
                          tileColor: widget.selectedId == null
                              ? const Color(0xFFEAF0FF)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: const BorderSide(
                                  color: OySynAuthTokens.divider)),
                          leading: const Icon(Icons.folder_open_rounded,
                              color: OySynAuthTokens.primaryBlue),
                          title: const Text('Все документы'),
                          trailing: widget.selectedId == null
                              ? const Icon(Icons.check_circle_rounded,
                                  color: OySynAuthTokens.primaryBlue)
                              : null,
                        );
                      }
                      final folder = folders[index - 1];
                      final id = folder['id'] is num
                          ? (folder['id'] as num).toInt()
                          : int.tryParse('${folder['id']}');
                      final active = id != null && id == widget.selectedId;
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (active)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: OySynAuthTokens.primaryBlue,
                                size: 21,
                              )
                            else
                              Text(
                                '${folder['documents_count'] ?? 0}',
                                style: OySynTextStyles.caption,
                              ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _renameFolder(folder),
                              tooltip: 'Переименовать папку',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
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
  final int page;
  final int totalPages;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label = 'Страница $page из $totalPages · $totalItems документов';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Назад'),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
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
