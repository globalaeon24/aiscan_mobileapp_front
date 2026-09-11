import 'package:flutter/material.dart';

import '../../../services/scan_service.dart';
import '../../../theme/app_theme.dart';

class DeletedDocumentsPage extends StatefulWidget {
  final int organizationId;

  const DeletedDocumentsPage({
    super.key,
    required this.organizationId,
  });

  @override
  State<DeletedDocumentsPage> createState() => _DeletedDocumentsPageState();
}

class _DeletedDocumentsPageState extends State<DeletedDocumentsPage> {
  static const _pageSize = 20;
  int _page = 1;
  late Future<DeletedChecksPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DeletedChecksPage> _load() => ScanService.getDeletedChecks(
        widget.organizationId,
        page: _page,
        pageSize: _pageSize,
      );

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _changePage(int value) async {
    setState(() {
      _page = value;
      _future = _load();
    });
  }

  Future<void> _restore(DeletedCheck item) async {
    final title = item.document.title ?? item.document.fileName ?? 'Документ';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить документ?'),
        content:
            Text('«$title» снова появится в списке документов пользователя.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ScanService.restoreDeletedCheck(
        widget.organizationId,
        item.document.id,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Документ восстановлен')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<DeletedChecksPage>(
            future: _future,
            builder: (context, snapshot) {
              final data = snapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Navigator.of(context).pop,
                        tooltip: 'Назад',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side:
                              const BorderSide(color: OySynAuthTokens.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Удалённые документы',
                          style: OySynTextStyles.sectionTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    _Message(
                      icon: Icons.cloud_off_rounded,
                      title: 'Не удалось загрузить документы',
                      text: snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                    )
                  else if (data == null || data.items.isEmpty)
                    const _Message(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Удалённых документов пока нет',
                      text: 'Удалённые проверки организации появятся здесь.',
                    )
                  else ...[
                    Text(
                      '${data.count} ${_documentWord(data.count)}',
                      style: const TextStyle(
                        color: OySynAuthTokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in data.items) ...[
                      _DeletedDocumentRow(
                        item: item,
                        onRestore: () => _restore(item),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (data.pages > 1)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: data.page > 1
                                  ? () => _changePage(data.page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('Назад'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${data.page} из ${data.pages}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: data.page < data.pages
                                  ? () => _changePage(data.page + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                              label: const Text('Дальше'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _documentWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'документ';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'документа';
    }
    return 'документов';
  }
}

class _DeletedDocumentRow extends StatelessWidget {
  final DeletedCheck item;
  final VoidCallback onRestore;

  const _DeletedDocumentRow({required this.item, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final document = item.document;
    final owner = item.createdByName.trim().isNotEmpty
        ? item.createdByName
        : item.createdByEmail;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFFDF3E48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title ?? document.fileName ?? 'Документ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (owner.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: OySynAuthTokens.textMuted),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  'Удалён ${_date(item.deletedAt)}',
                  style: const TextStyle(
                    color: OySynAuthTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRestore,
            tooltip: 'Восстановить',
            icon: const Icon(Icons.restore_rounded),
            color: OySynAuthTokens.primaryBlue,
            style: IconButton.styleFrom(
              side: const BorderSide(color: OySynAuthTokens.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime? value) {
    if (value == null) return 'недавно';
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} в '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Message({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: OySynAuthTokens.primaryBlue),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OySynAuthTokens.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
