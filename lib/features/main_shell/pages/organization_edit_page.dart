import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationEditPage extends StatefulWidget {
  final int organizationId;
  final Map<String, dynamic> organization;

  const OrganizationEditPage({
    super.key,
    required this.organizationId,
    required this.organization,
  });

  @override
  State<OrganizationEditPage> createState() => _OrganizationEditPageState();
}

class _OrganizationEditPageState extends State<OrganizationEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _address;
  late final TextEditingController _description;
  late String _city;
  late Map<String, String> _savedValues;
  bool _saving = false;
  bool _dirty = false;
  bool _hasSavedChanges = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _value(widget.organization['title']));
    _address =
        TextEditingController(text: _value(widget.organization['address']));
    _description =
        TextEditingController(text: _value(widget.organization['description']));
    final existingCity = _value(widget.organization['city']);
    _city = _cities.any((city) => city.$1 == existingCity)
        ? existingCity
        : _cities.first.$1;
    _savedValues = _currentValues();
    _title.addListener(_detectChanges);
    _address.addListener(_detectChanges);
    _description.addListener(_detectChanges);
  }

  @override
  void dispose() {
    _title.removeListener(_detectChanges);
    _address.removeListener(_detectChanges);
    _description.removeListener(_detectChanges);
    _title.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_dirty || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ProfileService.updateOrganization(
        widget.organizationId,
        _currentValues(),
      );
      if (!mounted) return;
      setState(() {
        _savedValues = _currentValues();
        _dirty = false;
        _hasSavedChanges = true;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные организации сохранены')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, String> _currentValues() => {
        'title': _title.text.trim(),
        'city': _city,
        'address': _address.text.trim(),
        'description': _description.text.trim(),
      };

  void _detectChanges() {
    final changed = !_sameValues(_currentValues(), _savedValues);
    if (mounted && changed != _dirty) setState(() => _dirty = changed);
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    _title.text = _savedValues['title'] ?? '';
    _address.text = _savedValues['address'] ?? '';
    _description.text = _savedValues['description'] ?? '';
    setState(() {
      _city = _savedValues['city'] ?? _cities.first.$1;
      _dirty = false;
      _editing = false;
    });
  }

  void _startEditing() => setState(() => _editing = true);

  Future<void> _close() async {
    if (_editing && _dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Закрыть без сохранения?'),
          content: const Text(
            'Внесённые изменения будут потеряны.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Остаться'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (_editing) {
      _cancelEditing();
      return;
    }
    Navigator.of(context).pop(_hasSavedChanges);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: OySynAuthTokens.appBackground,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Назад',
            onPressed: _saving ? null : _close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Организация'),
          actions: [
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _StatusBadge(
                  text: _dirty ? 'Не сохранено' : 'Редактирование',
                  color: _dirty
                      ? const Color(0xFFC77B00)
                      : OySynAuthTokens.primaryBlue,
                  background: _dirty
                      ? const Color(0xFFFFF2D6)
                      : const Color(0xFFEAF0FF),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Изменить'),
                ),
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _OrganizationIdentity(title: _savedValues['title'] ?? ''),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _editing
                        ? _buildEditForm()
                        : _OrganizationInformation(values: _savedValues),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _editing ? _buildEditActions() : null,
      ),
    );
  }

  Widget _buildEditForm() => Column(
        key: const ValueKey('edit'),
        children: [
          _FormSection(
            title: 'Основные сведения',
            subtitle: 'Название и местоположение организации',
            children: [
              TextFormField(
                controller: _title,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Название организации',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_city),
                initialValue: _city,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: _cities
                    .map((city) => DropdownMenuItem(
                          value: city.$1,
                          child: Text(city.$2),
                        ))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _city = value);
                        _detectChanges();
                      },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormSection(
            title: 'Адрес и описание',
            subtitle: 'Информация, доступная сотрудникам организации',
            children: [
              TextFormField(
                controller: _address,
                keyboardType: TextInputType.streetAddress,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Адрес',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.place_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Закрыть клавиатуру',
                    onPressed: () => FocusScope.of(context).unfocus(),
                    icon: const Icon(Icons.keyboard_hide_rounded),
                  ),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Кратко опишите организацию',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 54),
                    child: Icon(Icons.notes_rounded),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Закрыть клавиатуру',
                    onPressed: () => FocusScope.of(context).unfocus(),
                    icon: const Icon(Icons.keyboard_hide_rounded),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildEditActions() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: OySynAuthTokens.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _dirty && !_saving ? _save : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  static String _value(dynamic value) => value?.toString() ?? '';
  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Заполните поле' : null;
  static String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  static bool _sameValues(
    Map<String, String> left,
    Map<String, String> right,
  ) =>
      left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

class _OrganizationIdentity extends StatelessWidget {
  final String title;

  const _OrganizationIdentity({required this.title});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.business_rounded,
                  color: OySynAuthTokens.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Организация' : title,
                    softWrap: true,
                    style: OySynTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Карточка организации',
                    style: OySynTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _OrganizationInformation extends StatelessWidget {
  final Map<String, String> values;

  const _OrganizationInformation({required this.values});

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('view'),
        children: [
          _FormSection(
            title: 'Основные сведения',
            subtitle: 'Название и местоположение организации',
            children: [
              _InformationRow(
                icon: Icons.business_outlined,
                label: 'Название организации',
                value: values['title'],
              ),
              const Divider(height: 24),
              _InformationRow(
                icon: Icons.location_city_outlined,
                label: 'Город',
                value: _cityName(values['city']),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormSection(
            title: 'Адрес и описание',
            subtitle: 'Информация, доступная сотрудникам организации',
            children: [
              _InformationRow(
                icon: Icons.place_outlined,
                label: 'Адрес',
                value: values['address'],
              ),
              const Divider(height: 24),
              _InformationRow(
                icon: Icons.notes_rounded,
                label: 'Описание',
                value: values['description'],
              ),
            ],
          ),
        ],
      );
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: OySynAuthTokens.primaryBlue, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: OySynTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  value?.trim().isNotEmpty == true ? value! : 'Не указано',
                  softWrap: true,
                  style: const TextStyle(
                    color: OySynAuthTokens.textDark,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OySynAuthTokens.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: OySynTextStyles.cardTitle),
            const SizedBox(height: 3),
            Text(subtitle, style: OySynTextStyles.caption),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _StatusBadge({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );
}

String _cityName(String? code) {
  for (final city in _cities) {
    if (city.$1 == code) return city.$2;
  }
  return code?.trim().isNotEmpty == true ? code! : 'Не указан';
}

const _cities = <(String, String)>[
  ('ALA', 'Алматы'),
  ('NQZ', 'Астана'),
  ('SCO', 'Актау'),
  ('AKX', 'Актобе'),
  ('GUW', 'Атырау'),
  ('AYK', 'Аркалык'),
  ('BXH', 'Балхаш'),
  ('BXY', 'Байконур'),
  ('DMB', 'Тараз'),
  ('HSA', 'Туркестан'),
  ('DZN', 'Жезказган'),
  ('KGF', 'Караганда'),
  ('KOV', 'Кокшетау'),
  ('KSN', 'Костанай'),
  ('KZO', 'Кызылорда'),
  ('PWQ', 'Павлодар'),
  ('PPK', 'Петропавловск'),
  ('TSE', 'Талдыкорган'),
  ('TTT', 'Темиртау'),
  ('UKK', 'Усть-Каменогорск'),
  ('URA', 'Уральск'),
  ('PLX', 'Семей'),
  ('CIT', 'Шымкент'),
  ('CAY', 'Зайсан'),
];
