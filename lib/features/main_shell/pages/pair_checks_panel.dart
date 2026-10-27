import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _future = ScanService.getPairChecks();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ScanService.getPairChecks();
    });
    await _future;
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
        final items = snapshot.data?.items ?? const <PairCheckItem>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Создать парную проверку'),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
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
                'Всего: ${snapshot.data?.count ?? items.length}',
                style: const TextStyle(
                  color: OySynAuthTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items) ...[
                _PairCheckCard(item: item),
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
        child: Form(
          key: _formKey,
          child: ListView(
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
                style:
                    TextStyle(color: OySynAuthTokens.textMuted, height: 1.35),
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

  const _DocumentInputCard({
    required this.number,
    required this.file,
    required this.titleController,
    required this.authorController,
    required this.onSelect,
    required this.onClear,
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

  const _RequiredField({
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Заполните поле' : null,
    );
  }
}

class _PairCheckCard extends StatelessWidget {
  final PairCheckItem item;

  const _PairCheckCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows_rounded,
              color: OySynAuthTokens.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.firstTitle.isEmpty || item.secondTitle.isEmpty
                      ? 'Парная проверка №${item.id}'
                      : '${item.firstTitle} / ${item.secondTitle}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _pairCardTitle,
                ),
                if (item.status == 'CH') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Совпадения: ${item.firstToSecondSimilarity.toStringAsFixed(1)}% и ${item.secondToFirstSimilarity.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: OySynAuthTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(_pairStatus(item.status),
              style: TextStyle(
                color: item.status == 'FA'
                    ? const Color(0xFFDF3E48)
                    : OySynAuthTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

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

String _pairStatus(String status) => switch (status) {
      'UP' => 'Загружена',
      'PR' => 'Проверяется',
      'CH' => 'Готова',
      'FA' => 'Ошибка',
      _ => 'Создана',
    };
