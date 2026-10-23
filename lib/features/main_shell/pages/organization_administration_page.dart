import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';

class OrganizationAdministrationPage extends StatefulWidget {
  final int organizationId;

  const OrganizationAdministrationPage({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationAdministrationPage> createState() =>
      _OrganizationAdministrationPageState();
}

class _OrganizationAdministrationPageState
    extends State<OrganizationAdministrationPage> {
  late Future<_AdministrationData> _future;
  Map<String, int> _thresholds = const {};
  Map<String, int> _initialThresholds = const {};
  bool _savingThresholds = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdministrationData> _load() async {
    final values = await Future.wait<dynamic>([
      ProfileService.getOrganizationThresholds(widget.organizationId),
      ProfileService.getOrganizationApiSettings(widget.organizationId),
      ProfileService.getOrganizationUsers(widget.organizationId),
    ]);
    final thresholdPayload = values[0] as Map<String, dynamic>;
    final rawThresholds = thresholdPayload['thresholds'] is Map
        ? Map<String, dynamic>.from(thresholdPayload['thresholds'] as Map)
        : const <String, dynamic>{};
    final thresholds = rawThresholds.map(
      (key, value) => MapEntry(key, _asInt(value)),
    );
    final apiPayload = values[1] as Map<String, dynamic>;
    final rawTokens = apiPayload['api_tokens'] is List
        ? apiPayload['api_tokens'] as List
        : const <dynamic>[];
    final users = values[2] as List<Map<String, dynamic>>;
    if (_thresholds.isEmpty) {
      _initialThresholds = thresholds;
      _thresholds = Map<String, int>.from(thresholds);
    }
    return _AdministrationData(
      thresholds: thresholds,
      apiTokens: rawTokens
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      users: users,
    );
  }

  Future<void> _refresh() async {
    _thresholds = const {};
    _initialThresholds = const {};
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _saveThresholds() async {
    final updated = <String, int>{};
    for (final entry in _thresholds.entries) {
      if (_initialThresholds[entry.key] != entry.value) {
        updated[entry.key] = entry.value;
      }
    }
    if (updated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменений порогов нет.')),
      );
      return;
    }
    setState(() => _savingThresholds = true);
    try {
      final response = await ProfileService.updateOrganizationThresholds(
        widget.organizationId,
        updated,
      );
      final raw = response['thresholds'];
      if (raw is Map) {
        _initialThresholds = raw.map(
          (key, value) => MapEntry('$key', _asInt(value)),
        );
        _thresholds = Map<String, int>.from(_initialThresholds);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пороговые значения сохранены.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _savingThresholds = false);
    }
  }

  Future<void> _createApiToken(_AdministrationData data) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApiTokenSheet(users: data.users),
    );
    if (result == null || !mounted) return;
    try {
      final token = await ProfileService.createOrganizationApiToken(
        widget.organizationId,
        result,
      );
      if (!mounted) return;
      await _showCreatedToken(token);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  Future<void> _showCreatedToken(Map<String, dynamic> token) async {
    final value = token['token']?.toString() ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API-ключ создан'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сохраните ключ сейчас. В дальнейшем приложение не показывает значения существующих ключей.',
            ),
            const SizedBox(height: 12),
            SelectableText(value.isEmpty ? 'Ключ не получен' : value),
          ],
        ),
        actions: [
          if (value.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Скопировать'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        title: const Text(
          'Администрирование',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _savingThresholds ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_AdministrationData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AdministrationError(onRetry: _refresh);
          }
          final data = snapshot.data!;
          final fields = data.thresholds.keys.toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _AdministrationTabs(
                  selected: _tab,
                  onChanged: (value) => setState(() => _tab = value),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_tab) {
                    0 => _ThresholdsList(
                        key: const ValueKey('originality'),
                        title: 'Пороги оригинальности',
                        icon: Icons.verified_outlined,
                        fields: fields
                            .where((field) => !field.startsWith('ai_'))
                            .toList(),
                        values: _thresholds,
                        description:
                            'Минимальный процент оригинального текста по типам документов.',
                        saving: _savingThresholds,
                        onChanged: (field, value) => setState(
                          () => _thresholds[field] = value,
                        ),
                        onSave: _saveThresholds,
                      ),
                    1 => _ThresholdsList(
                        key: const ValueKey('ai'),
                        title: 'Пороги ИИ-контента',
                        icon: Icons.auto_awesome_outlined,
                        fields: fields
                            .where((field) => field.startsWith('ai_'))
                            .toList(),
                        values: _thresholds,
                        description:
                            'Максимально допустимая доля ИИ-контента по типам документов.',
                        saving: _savingThresholds,
                        onChanged: (field, value) => setState(
                          () => _thresholds[field] = value,
                        ),
                        onSave: _saveThresholds,
                      ),
                    _ => _ApiTokensTab(
                        key: const ValueKey('api'),
                        tokens: data.apiTokens,
                        onCreate: () => _createApiToken(data),
                      ),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThresholdsList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> fields;
  final Map<String, int> values;
  final String description;
  final bool saving;
  final void Function(String field, int value) onChanged;
  final VoidCallback onSave;

  const _ThresholdsList({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
    required this.values,
    required this.description,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + oysynSystemBottomInset(context),
      ),
      children: [
        _AdministrationHeader(
          title: title,
          description: description,
          icon: icon,
          saving: saving,
          onSave: onSave,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < fields.length; index++) ...[
          _ThresholdSlider(
            field: fields[index],
            value: values[fields[index]] ?? 0,
            onChanged: (value) => onChanged(fields[index], value),
          ),
          if (index != fields.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AdministrationTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _AdministrationTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_outlined, 'Оригинальность'),
      (Icons.auto_awesome_outlined, 'ИИ-контент'),
      (Icons.key_outlined, 'API'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E2FB)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = selected == index;
          return Expanded(
            child: Material(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].$1,
                        size: 18,
                        color: active
                            ? OySynAuthTokens.primaryBlue
                            : OySynAuthTokens.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          items[index].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? OySynAuthTokens.deepBlue
                                : OySynAuthTokens.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AdministrationHeader extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool saving;
  final VoidCallback onSave;

  const _AdministrationHeader({
    required this.title,
    required this.description,
    required this.icon,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: OySynAuthTokens.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OySynTextStyles.cardTitle),
                const SizedBox(height: 3),
                Text(description, style: OySynTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 13),
            ),
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String field;
  final int value;
  final ValueChanged<int> onChanged;

  const _ThresholdSlider({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _thresholdLabel(field),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OySynTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value%',
                  style: const TextStyle(
                    color: OySynAuthTokens.deepBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              inactiveTrackColor: const Color(0xFFDCE4F2),
            ),
            child: Slider(
              value: value.toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$value%',
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiTokensTab extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final VoidCallback onCreate;

  const _ApiTokensTab({
    super.key,
    required this.tokens,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + oysynSystemBottomInset(context),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OySynAuthTokens.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.key_outlined,
                  color: OySynAuthTokens.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ключи для интеграций',
                        style: OySynTextStyles.cardTitle),
                    SizedBox(height: 3),
                    Text(
                      'Отдельный ключ для каждой интеграции.',
                      style: OySynTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onCreate,
                tooltip: 'Создать API-ключ',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (tokens.isEmpty)
          const _EmptyTokenState()
        else
          for (final token in tokens) ...[
            _ApiTokenCard(token: token),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ApiTokenCard extends StatelessWidget {
  final Map<String, dynamic> token;

  const _ApiTokenCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final active = token['is_active'] == true;
    final balance = token['use_organization_balance'] == true;
    final limit = _asInt(token['api_checks_available']);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.key_outlined,
              color: active
                  ? OySynAuthTokens.primaryBlue
                  : OySynAuthTokens.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(token['name']?.toString() ?? 'API-ключ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  balance
                      ? 'Использует баланс организации'
                      : 'Лимит: $limit проверок',
                  style: const TextStyle(
                      color: OySynAuthTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(active ? 'Активен' : 'Отключён',
              style: TextStyle(
                color: active
                    ? const Color(0xFF168B5B)
                    : OySynAuthTokens.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

class _ApiTokenSheet extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const _ApiTokenSheet({required this.users});

  @override
  State<_ApiTokenSheet> createState() => _ApiTokenSheetState();
}

class _ApiTokenSheetState extends State<_ApiTokenSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _checks = TextEditingController(text: '0');
  int? _userId;
  bool _useOrganizationBalance = false;

  @override
  void initState() {
    super.initState();
    _userId =
        widget.users.isEmpty ? null : _asNullableInt(widget.users.first['id']);
  }

  @override
  void dispose() {
    _name.dispose();
    _checks.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || _userId == null) {
      return;
    }
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'user_id': _userId,
      'use_organization_balance': _useOrganizationBalance,
      'api_checks_available': int.tryParse(_checks.text) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        22 + oysynInteractiveBottomInset(context),
      ),
      decoration: const BoxDecoration(
        color: OySynAuthTokens.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                  child: SizedBox(width: 42, child: Divider(thickness: 4))),
              const SizedBox(height: 12),
              const Text('Новый API-ключ', style: OySynTextStyles.sectionTitle),
              const SizedBox(height: 16),
              if (widget.users.isEmpty)
                const Text('В организации нет доступных пользователей.')
              else ...[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Наименование'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Заполните поле'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _userId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Пользователь'),
                  items: widget.users
                      .map((user) {
                        final id = _asNullableInt(user['id']);
                        if (id == null) return null;
                        final name = user['full_name']?.toString().trim();
                        final email = user['email']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child:
                              Text(name == null || name.isEmpty ? email : name),
                        );
                      })
                      .whereType<DropdownMenuItem<int>>()
                      .toList(),
                  onChanged: (value) => setState(() => _userId = value),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Использовать баланс организации'),
                  value: _useOrganizationBalance,
                  onChanged: (value) =>
                      setState(() => _useOrganizationBalance = value),
                ),
                if (!_useOrganizationBalance) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _checks,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Количество проверок'),
                    validator: (value) => int.tryParse(value ?? '') == null
                        ? 'Укажите целое число'
                        : null,
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('Создать ключ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdministrationError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _AdministrationError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 42, color: OySynAuthTokens.textMuted),
              const SizedBox(height: 12),
              const Text('Не удалось загрузить настройки'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyTokenState extends StatelessWidget {
  const _EmptyTokenState();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: OySynAuthTokens.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Активных API-ключей пока нет.',
          textAlign: TextAlign.center,
          style: TextStyle(color: OySynAuthTokens.textMuted),
        ),
      );
}

class _AdministrationData {
  final Map<String, int> thresholds;
  final List<Map<String, dynamic>> apiTokens;
  final List<Map<String, dynamic>> users;

  const _AdministrationData({
    required this.thresholds,
    required this.apiTokens,
    required this.users,
  });
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _asNullableInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');
String _message(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

String _thresholdLabel(String field) {
  final normalized = field.replaceFirst('ai_', '').replaceAll('_threshold', '');
  const labels = <String, String>{
    'article': 'Статья',
    'course_work': 'Курсовая работа',
    'doctoral': 'Докторская диссертация',
    'diploma_thesis': 'Дипломная работа',
    'diploma_project': 'Дипломный проект',
    'masters_thesis': 'Магистерская диссертация',
    'study_guide': 'Учебное пособие',
    'textbook': 'Учебник',
    'book': 'Книга',
    'research': 'Исследовательская работа',
    'monograph': 'Монография',
    'abstract': 'Реферат',
    'other': 'Другое',
    'project': 'Проект',
    'essay': 'Эссе',
    'scientific_work': 'Научная работа',
    'teaching_aid': 'Методическое пособие',
    'methodological_aid': 'Методическое пособие',
    'methodological_recommendations': 'Методические рекомендации',
    'author_program': 'Авторская программа',
  };
  return labels[normalized] ?? normalized;
}
