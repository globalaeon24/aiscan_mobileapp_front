import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../services/scan_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';

class PairChecksPanel extends StatefulWidget {
  const PairChecksPanel({super.key});

  @override
  State<PairChecksPanel> createState() => _PairChecksPanelState();
}

class _PairChecksPanelState extends State<PairChecksPanel> {
  late Future<PairChecksPage> _future;
  PairChecksPage? _latestPage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<PairChecksPage> _load() async {
    final page = await ScanService.getPairChecks();
    if (mounted) {
      _latestPage = page;
      _schedulePolling(
        page.items.any(_shouldPoll),
      );
    }
    return page;
  }

  void _schedulePolling(bool hasActiveChecks) {
    _pollTimer?.cancel();
    if (!hasActiveChecks) return;
    _pollTimer = Timer(const Duration(seconds: 15), _pollSilently);
  }

  Future<void> _pollSilently() async {
    try {
      final page = await ScanService.getPairChecks();
      if (!mounted) return;
      setState(() {
        _latestPage = page;
        _future = Future.value(page);
      });
      _schedulePolling(page.items.any(_shouldPoll));
    } catch (_) {
      if (mounted) _schedulePolling(true);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  static bool _isTerminalStatus(String status) {
    return const {'CH', 'FA', 'FAILED', 'ERROR', 'CANCELLED'}
        .contains(status.toUpperCase());
  }

  static bool _shouldPoll(PairCheckItem item) {
    return !_isTerminalStatus(item.status);
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PairCheckCreatePage()),
    );
    if (created == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PairChecksPage>(
      future: _future,
      builder: (context, snapshot) {
        final page = snapshot.data ?? _latestPage;
        final items = page?.items ?? const <PairCheckItem>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Создать парную проверку'),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting &&
                page == null)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError && page == null)
              _PairStateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Не удалось загрузить парные проверки',
                text: 'Проверьте соединение и повторите попытку.',
                action: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              )
            else if (items.isEmpty)
              _PairStateMessage(
                icon: Icons.compare_arrows_rounded,
                title: 'Парных проверок пока нет',
                text: 'Добавьте два документа, чтобы сравнить их между собой.',
                action: FilledButton(
                  onPressed: _create,
                  child: const Text('Добавить документы'),
                ),
              )
            else ...[
              Text(
                'Всего: ${page?.count ?? items.length}',
                style: const TextStyle(
                  color: OySynAuthTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items) ...[
                PairCheckCard(item: item),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class PairCheckCreatePage extends StatefulWidget {
  const PairCheckCreatePage({super.key});

  @override
  State<PairCheckCreatePage> createState() => _PairCheckCreatePageState();
}

class _PairCheckCreatePageState extends State<PairCheckCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstTitle = TextEditingController();
  final _firstAuthor = TextEditingController();
  final _secondTitle = TextEditingController();
  final _secondAuthor = TextEditingController();
  PlatformFile? _firstDocument;
  PlatformFile? _secondDocument;
  bool _saving = false;

  @override
  void dispose() {
    _firstTitle.dispose();
    _firstAuthor.dispose();
    _secondTitle.dispose();
    _secondAuthor.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(bool first) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
      withData: true,
    );
    final file = selected != null && selected.files.isNotEmpty
        ? selected.files.first
        : null;
    if (file == null || !mounted) return;
    setState(() {
      if (first) {
        _firstDocument = file;
        if (_firstTitle.text.trim().isEmpty) {
          _firstTitle.text = _fileTitle(file.name);
        }
      } else {
        _secondDocument = file;
        if (_secondTitle.text.trim().isEmpty) {
          _secondTitle.text = _fileTitle(file.name);
        }
      }
    });
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_firstDocument == null || _secondDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте оба документа для сравнения.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ScanService.createPairCheck(
        firstDocument: _firstDocument!,
        secondDocument: _secondDocument!,
        firstTitle: _firstTitle.text,
        firstAuthor: _firstAuthor.text,
        secondTitle: _secondTitle.text,
        secondAuthor: _secondAuthor.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        title: const Text('Парная проверка'),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                24 + oysynSystemBottomInset(context),
              ),
              children: [
                const Text(
                  'Сравните два документа',
                  style: OySynTextStyles.sectionTitle,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Для каждого документа укажите название, автора и прикрепите файл.',
                  style: TextStyle(
                    color: OySynAuthTokens.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _DocumentInputCard(
                  number: 1,
                  file: _firstDocument,
                  titleController: _firstTitle,
                  authorController: _firstAuthor,
                  onSelect: () => _pickDocument(true),
                  onClear: () => setState(() => _firstDocument = null),
                ),
                const SizedBox(height: 12),
                _DocumentInputCard(
                  number: 2,
                  file: _secondDocument,
                  titleController: _secondTitle,
                  authorController: _secondAuthor,
                  lastField: true,
                  onSelect: () => _pickDocument(false),
                  onClear: () => setState(() => _secondDocument = null),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_saving ? 'Запуск...' : 'Запустить проверку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fileTitle(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _DocumentInputCard extends StatelessWidget {
  final int number;
  final PlatformFile? file;
  final TextEditingController titleController;
  final TextEditingController authorController;
  final VoidCallback onSelect;
  final VoidCallback onClear;
  final bool lastField;

  const _DocumentInputCard({
    required this.number,
    required this.file,
    required this.titleController,
    required this.authorController,
    required this.onSelect,
    required this.onClear,
    this.lastField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Документ $number', style: _pairCardTitle),
          const SizedBox(height: 12),
          _RequiredField(
            controller: titleController,
            label: 'Название',
          ),
          const SizedBox(height: 10),
          _RequiredField(
            controller: authorController,
            label: 'Автор',
            hint: 'Фамилия, имя, отчество',
            textInputAction:
                lastField ? TextInputAction.done : TextInputAction.next,
            onSubmitted: lastField
                ? (_) => FocusManager.instance.primaryFocus?.unfocus()
                : null,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(file == null ? 'Выбрать файл' : file!.name),
          ),
          if (file != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Убрать'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _RequiredField({
    required this.controller,
    required this.label,
    this.hint,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Заполните поле' : null,
    );
  }
}

class PairCheckCard extends StatelessWidget {
  final PairCheckItem item;

  const PairCheckCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final resultReady = _isPairResultReady(item.status);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('pair-check-${item.id}'),
        onTap: resultReady
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PairCheckDetailsPage(item: item),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    color: OySynAuthTokens.primaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.firstTitle.isEmpty || item.secondTitle.isEmpty
                          ? 'Парная проверка №${item.id}'
                          : '${item.firstTitle} / ${item.secondTitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _pairCardTitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PairStatusBadge(status: item.status),
                  if (resultReady) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: OySynAuthTokens.textMuted,
                      size: 20,
                    ),
                  ],
                ],
              ),
              if (resultReady) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PairSimilarityBadge(
                      label: 'A → B',
                      value: item.firstToSecondSimilarity,
                      color: OySynAuthTokens.primaryBlue,
                      background: const Color(0xFFEEF4FF),
                    ),
                    _PairSimilarityBadge(
                      label: 'B → A',
                      value: item.secondToFirstSimilarity,
                      color: const Color(0xFF159447),
                      background: const Color(0xFFE9F8EF),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PairStatusBadge extends StatelessWidget {
  final String status;

  const _PairStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final error = const {'FA', 'FAILED', 'ERROR'}.contains(normalized);
    final checked = _isPairResultReady(normalized);
    final color = error
        ? const Color(0xFFCF3540)
        : checked
            ? const Color(0xFF159447)
            : const Color(0xFFB47100);
    final background = error
        ? const Color(0xFFFFEDEF)
        : checked
            ? const Color(0xFFE9F8EF)
            : const Color(0xFFFFF4D8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _pairStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PairSimilarityBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color background;

  const _PairSimilarityBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(color: color.withValues(alpha: 0.8)),
            ),
            TextSpan(
              text: '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class PairCheckDetailsPage extends StatefulWidget {
  final PairCheckItem item;

  const PairCheckDetailsPage({super.key, required this.item});

  @override
  State<PairCheckDetailsPage> createState() => _PairCheckDetailsPageState();
}

class _PairCheckDetailsPageState extends State<PairCheckDetailsPage> {
  String? _loadingReportType;

  Future<void> _shareReport(String reportType) async {
    if (_loadingReportType != null) return;
    setState(() => _loadingReportType = reportType);

    try {
      final bytes = await ScanService.getPairReportPdf(
        widget.item.id,
        reportType: reportType,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'pair_check_${widget.item.id}_$reportType.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loadingReportType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(title: const Text('Парная проверка')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + oysynSystemBottomInset(context),
          ),
          children: [
            Row(
              children: [
                _PairDocumentSummary(
                  marker: 'A',
                  markerColor: OySynAuthTokens.primaryBlue,
                  title: item.firstTitle,
                  author: item.firstAuthor,
                ),
                const SizedBox(width: 10),
                _PairDocumentSummary(
                  marker: 'B',
                  markerColor: const Color(0xFFF44347),
                  title: item.secondTitle,
                  author: item.secondAuthor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _pairPanelDecoration,
              child: Column(
                children: [
                  _PairResultRow(
                    label: 'A → B',
                    value: item.firstToSecondSimilarity,
                  ),
                  const Divider(height: 22),
                  _PairResultRow(
                    label: 'B → A',
                    value: item.secondToFirstSimilarity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _pairPanelDecoration,
              child: Column(
                children: [
                  _PairInfoRow(
                    icon: Icons.task_alt_rounded,
                    label: 'Статус',
                    value: _pairStatus(item.status),
                  ),
                  if (item.createdAt != null) ...[
                    const Divider(height: 22),
                    _PairInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Дата проверки',
                      value: _formatPairDate(item.createdAt!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Отчёты', style: OySynTextStyles.sectionTitle),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loadingReportType == null
                  ? () => _shareReport('full')
                  : null,
              icon: _loadingReportType == 'full'
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Полный отчёт PDF'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadingReportType == null
                  ? () => _shareReport('short')
                  : null,
              icon: _loadingReportType == 'short'
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),
              label: const Text('Краткий отчёт PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairDocumentSummary extends StatelessWidget {
  final String marker;
  final Color markerColor;
  final String title;
  final String author;

  const _PairDocumentSummary({
    required this.marker,
    required this.markerColor,
    required this.title,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(14),
        decoration: _pairPanelDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                marker,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title.isEmpty ? 'Без названия' : title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _pairCardTitle,
            ),
            const SizedBox(height: 3),
            Text(
              author.isEmpty ? 'Автор не указан' : 'Автор: $author',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: OySynAuthTokens.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairResultRow extends StatelessWidget {
  final String label;
  final double value;

  const _PairResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OySynAuthTokens.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F8EF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF159447),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PairInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PairInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: OySynAuthTokens.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: OySynAuthTokens.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: OySynAuthTokens.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

final _pairPanelDecoration = BoxDecoration(
  color: Colors.white,
  border: Border.all(color: OySynAuthTokens.divider),
  borderRadius: BorderRadius.circular(14),
);

class _PairStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget action;

  const _PairStateMessage({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: OySynAuthTokens.primaryBlue),
          const SizedBox(height: 10),
          Text(title, style: _pairCardTitle),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: OySynAuthTokens.textMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          action,
        ],
      ),
    );
  }
}

const _pairCardTitle = TextStyle(
  color: OySynAuthTokens.textDark,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

String _pairStatus(String status) => switch (status.toUpperCase()) {
      'CH' || 'COMPLETED' || 'DONE' || 'SUCCESS' => 'Проверен',
      'PR' || 'PROCESSING' || 'PENDING' => 'Проверка',
      'UP' || 'UPLOADED' || 'SUBMITTED' => 'Проверка',
      'FA' || 'FAILED' || 'ERROR' => 'Ошибка',
      'CANCELLED' || 'CANCELED' => 'Отменен',
      _ => 'В обработке',
    };

bool _isPairResultReady(String status) {
  return const {'CH', 'COMPLETED', 'DONE', 'SUCCESS'}
      .contains(status.toUpperCase());
}

String _formatPairDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}, '
      '${two(local.hour)}:${two(local.minute)}';
}
