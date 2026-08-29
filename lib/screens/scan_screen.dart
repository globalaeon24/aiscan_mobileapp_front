import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/profile_service.dart';
import '../services/scan_service.dart';
import '../theme/app_theme.dart';
import 'scan_details_screen.dart';

class ScanScreen extends StatefulWidget {
  final void Function(ScanResult)? onScanCompleted;

  const ScanScreen({super.key, this.onScanCompleted});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _documentTypes = <String, String>{
    'ARTICLE': 'Статья',
    'COURSE WORK': 'Курсовая работа',
    'DOCTORAL': 'Докторская диссертация',
    'DIPLOMA THESIS': 'Дипломная работа',
    'DIPLOMA PROJECT': 'Дипломный проект',
    'MASTERS': 'Магистерская диссертация',
    'RESEARCH': 'Исследовательская работа',
    'SCIENTIFIC WORK': 'Научная работа',
    'OTHER': 'Другое',
  };

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _departmentController = TextEditingController();

  File? _file;
  String _documentType = 'ARTICLE';
  bool _includeOcr = false;
  bool _aiCheck = true;
  bool _loading = false;
  bool _balanceLoading = true;
  int? _checksAvailable;
  bool _modulesLoading = true;
  String? _modulesError;
  List<CheckModule> _modules = const [];
  final Set<String> _selectedModules = {};

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final profile = await ProfileService.getProfile();
      if (!mounted) return;
      setState(() {
        _checksAvailable = _asInt(profile['checks_available']);
        _balanceLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _balanceLoading = false);
    }
  }

  Future<void> _loadModules() async {
    try {
      final modules = await ScanService.getCheckModules();
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _selectedModules
          ..clear()
          ..addAll(
              modules.where((item) => item.selected).map((item) => item.code));
        _modulesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _modulesError = error.toString();
        _modulesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'pptx', 'odt'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final file = File(path);
    if (file.lengthSync() > 50 * 1024 * 1024) {
      _showMessage('Размер файла не должен превышать 50 МБ.');
      return;
    }

    setState(() {
      _file = file;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = _nameWithoutExtension(file.path);
      }
    });
  }

  Future<void> _upload() async {
    try {
      final profile = await ProfileService.getProfile();
      final available = _asInt(profile['checks_available']);
      if (mounted) setState(() => _checksAvailable = available);
      if (available <= 0) {
        _showMessage(
          'Лимит проверок исчерпан. Обратитесь к администратору организации.',
        );
        return;
      }
    } catch (_) {
      // Сервер повторно проверит лимит перед созданием проверки.
    }
    final file = _file;
    if (file == null) {
      _showMessage('Сначала выберите документ.');
      return;
    }

    setState(() => _loading = true);
    try {
      final scan = await ScanService.uploadDocumentForScan(
        file,
        title: _titleController.text,
        author: _authorController.text,
        department: _departmentController.text,
        documentType: _documentType,
        includeOcr: _includeOcr,
        aiCheck: _aiCheck,
        modules: _modules
            .where((item) =>
                item.group == 'base' && _selectedModules.contains(item.code))
            .map((item) => item.code)
            .toList(),
        modulesKz: _modules
            .where((item) =>
                item.group == 'kz' && _selectedModules.contains(item.code))
            .map((item) => item.code)
            .toList(),
      );
      widget.onScanCompleted?.call(scan);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScanDetailsScreen(
            result: scan,
            loadFromBackend: true,
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Ошибка загрузки: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        toolbarHeight: 60,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 7, bottom: 7),
          child: _SquareButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: Navigator.of(context).pop,
          ),
        ),
        titleSpacing: 12,
        title: const Text(
          'Загрузить документ',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        children: [
          const _ModeSelector(),
          const SizedBox(height: 13),
          _SectionCard(
            title: 'Документ для проверки',
            child: _FileSelector(
              file: _file,
              onSelect: _pickDocument,
              onClear: () => setState(() => _file = null),
            ),
          ),
          const SizedBox(height: 13),
          _SectionCard(
            title: 'Информация о документе',
            child: Column(
              children: [
                _LabeledField(label: 'Название', controller: _titleController),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Автор',
                        controller: _authorController,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DocumentTypeField(
                        value: _documentType,
                        items: _documentTypes,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _documentType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                _LabeledField(
                  label: 'Подразделение',
                  hint: 'Например: Кафедра ИС',
                  controller: _departmentController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          _ModulesCard(
            loading: _modulesLoading,
            error: _modulesError,
            selectedCount: _selectedModules.length,
            onTap: _modulesLoading ? null : _openModules,
          ),
          const SizedBox(height: 13),
          _SettingsCard(
            includeOcr: _includeOcr,
            aiCheck: _aiCheck,
            onOcrChanged: (value) => setState(() => _includeOcr = value),
            onAiChanged: (value) => setState(() => _aiCheck = value),
          ),
          if (!_balanceLoading && (_checksAvailable ?? 1) <= 0) ...[
            const SizedBox(height: 13),
            const _LimitNotice(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: OySynAuthTokens.divider)),
          ),
          child: FilledButton.icon(
            onPressed:
                _loading || _balanceLoading || (_checksAvailable ?? 1) <= 0
                    ? null
                    : _upload,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_upload_outlined),
            label: Text(
              _loading
                  ? 'Загрузка...'
                  : (_checksAvailable ?? 1) <= 0
                      ? 'Лимит проверок исчерпан'
                      : 'Загрузить документ',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openModules() async {
    if (_modules.isEmpty) {
      _showMessage(_modulesError ?? 'Нет доступных модулей проверки.');
      return;
    }
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModulePickerSheet(
        modules: _modules,
        selected: _selectedModules,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedModules
          ..clear()
          ..addAll(selected);
      });
    }
  }
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD99B)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFFC87900), size: 21),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Лимит проверок исчерпан. Новая загрузка станет доступна после распределения проверок администратором организации.',
                style: TextStyle(
                  color: Color(0xFF8B5B10),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ModulePickerSheet extends StatefulWidget {
  final List<CheckModule> modules;
  final Set<String> selected;

  const _ModulePickerSheet({required this.modules, required this.selected});

  @override
  State<_ModulePickerSheet> createState() => _ModulePickerSheetState();
}

class _ModulePickerSheetState extends State<_ModulePickerSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final base = widget.modules.where((item) => item.group != 'kz').toList();
    final kz = widget.modules.where((item) => item.group == 'kz').toList();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      decoration: const BoxDecoration(
        color: OySynAuthTokens.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD3E2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    color: OySynAuthTokens.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Модули проверки',
                        style: TextStyle(
                          color: OySynAuthTokens.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Выберите источники для поиска совпадений',
                        style: TextStyle(
                          color: OySynAuthTokens.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 19, color: OySynAuthTokens.primaryBlue),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Выбрано ${_selected.length} из ${widget.modules.length}',
                    style: const TextStyle(
                      color: OySynAuthTokens.deepBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _selectRecommended,
                  child: const Text('Рекомендуемые'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                if (base.isNotEmpty) ...[
                  const _ModuleGroupTitle(
                    title: 'Основные источники',
                    icon: Icons.public_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...base.map(_moduleTile),
                ],
                if (kz.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const _ModuleGroupTitle(
                    title: 'Казахстанские источники',
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...kz.map(_moduleTile),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: OySynAuthTokens.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Применить · ${_selected.length}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleTile(CheckModule module) {
    final selected = _selected.contains(module.code);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFF1F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: module.required ? null : () => _toggle(module),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFB9CBFF)
                    : OySynAuthTokens.divider,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? OySynAuthTokens.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected
                          ? OySynAuthTokens.primaryBlue
                          : const Color(0xFFB9C2D3),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 17)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.label,
                        style: const TextStyle(
                          color: OySynAuthTokens.textDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (module.required) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Обязательный модуль',
                          style: TextStyle(
                            color: OySynAuthTokens.primaryBlue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (module.required)
                  const Icon(Icons.lock_outline_rounded,
                      size: 18, color: OySynAuthTokens.primaryBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(CheckModule module) {
    setState(() {
      if (!_selected.add(module.code)) _selected.remove(module.code);
    });
  }

  void _selectRecommended() {
    setState(() {
      _selected
        ..clear()
        ..addAll(widget.modules
            .where((module) => module.selected || module.required)
            .map((module) => module.code));
    });
  }
}

class _ModuleGroupTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ModuleGroupTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 17, color: OySynAuthTokens.textMuted),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5C677B),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Один документ',
                style: TextStyle(
                  color: Color(0xFF2B4CC0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Text(
                'Кросс-проверка',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6A7590), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  final File? file;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _FileSelector(
      {required this.file, required this.onSelect, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final selected = file;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFFF7F9FE),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE4E9F3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEFF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      selected == null ? '+' : _extension(selected.path),
                      style: const TextStyle(
                        color: Color(0xFF2F5FE0),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected == null
                              ? 'Выбрать документ'
                              : _fileName(selected.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected == null
                              ? 'Нажмите, чтобы выбрать файл'
                              : _fileSize(selected),
                          style: const TextStyle(
                              color: Color(0xFF8A94A6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (selected != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'DOCX, PDF, TXT, DOC, RTF, PPTX, ODT · до 50 МБ',
          style: TextStyle(color: Color(0xFFA2ABBE), fontSize: 11.5),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;

  const _LabeledField(
      {required this.label, required this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF3B475F),
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}

class _DocumentTypeField extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DocumentTypeField(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип документа *',
            style: TextStyle(
                color: Color(0xFF3B475F),
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items.entries
              .map((item) => DropdownMenuItem(
                  value: item.key,
                  child: Text(item.value, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ModulesCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final int selectedCount;
  final VoidCallback? onTap;

  const _ModulesCard(
      {required this.loading,
      required this.error,
      required this.selectedCount,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const _LeadingIcon(icon: Icons.layers_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Модули проверки',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      loading
                          ? 'Загрузка доступных модулей…'
                          : error != null
                              ? 'Не удалось загрузить модули'
                              : 'Выбрано модулей: $selectedCount',
                      style: TextStyle(
                          color: error != null
                              ? const Color(0xFFD23B41)
                              : const Color(0xFF8A94A6),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC3CAD8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool includeOcr;
  final bool aiCheck;
  final ValueChanged<bool> onOcrChanged;
  final ValueChanged<bool> onAiChanged;

  const _SettingsCard(
      {required this.includeOcr,
      required this.aiCheck,
      required this.onOcrChanged,
      required this.onAiChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _SettingRow(
              title: 'OCR',
              subtitle: 'Распознавать текст на сканах PDF',
              value: includeOcr,
              onChanged: onOcrChanged),
          const Divider(height: 1),
          _SettingRow(
              title: 'Проверка ИИ-контента',
              subtitle: 'Определять текст, написанный ИИ',
              value: aiCheck,
              onChanged: onAiChanged),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8A94A6), fontSize: 11.5)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;

  const _LeadingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: const Color(0xFF2B5CE0), size: 20),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SquareButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: OySynAuthTokens.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: OySynAuthTokens.divider),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF142350).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

String _fileName(String path) => path.split(Platform.pathSeparator).last;

String _nameWithoutExtension(String path) {
  final name = _fileName(path);
  final index = name.lastIndexOf('.');
  return index > 0 ? name.substring(0, index) : name;
}

String _extension(String path) {
  final name = _fileName(path);
  final index = name.lastIndexOf('.');
  return index > 0 ? name.substring(index + 1).toUpperCase() : 'FILE';
}

String _fileSize(File file) {
  final bytes = file.lengthSync();
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} КБ';
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
