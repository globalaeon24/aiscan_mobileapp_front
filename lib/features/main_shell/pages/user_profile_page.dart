import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../services/security_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pin_code_input.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>?> _profile;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final cached = await TokenStorage.getUser();
    try {
      final fresh = await ProfileService.getProfile();
      if (fresh.isNotEmpty) {
        await TokenStorage.saveUser(fresh);
        return fresh;
      }
    } catch (_) {}
    return cached;
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    await SecurityService.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _editProfile(Map<String, dynamic> user) async {
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditor(user: user),
    );
    if (updated == null || !mounted) return;
    await TokenStorage.saveUser(updated);
    setState(() => _profile = Future.value(updated));
  }

  Future<void> _changePin() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePinSheet(),
    );
    if (changed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN-код успешно изменён')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data ?? const <String, dynamic>{};
        return ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            112 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const _PageHeader(),
            const SizedBox(height: 18),
            _IdentityCard(user: user),
            const SizedBox(height: 16),
            _Tabs(
                selected: _tab,
                onChanged: (value) => setState(() => _tab = value)),
            const SizedBox(height: 16),
            switch (_tab) {
              0 => Column(
                  children: [
                    _AccountCard(
                      user: user,
                      onEdit: () => _editProfile(user),
                    ),
                  ],
                ),
              1 => const _InfoCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Уведомления',
                  text:
                      'Здесь будут отображаться важные уведомления аккаунта.'),
              _ => Column(
                  children: [
                    _NavigationCard(
                      icon: Icons.shield_outlined,
                      title: 'Защита аккаунта',
                      subtitle: 'Изменить PIN-код входа',
                      onTap: _changePin,
                    ),
                    const SizedBox(height: 14),
                    _NavigationCard(
                      icon: Icons.devices_rounded,
                      title: 'Связанные устройства',
                      subtitle: 'Активные веб-сессии',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/linked-devices'),
                    ),
                  ],
                ),
            },
            if (_tab == 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDF3E48),
                    side: const BorderSide(color: Color(0xFFF1B7BC)),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Выйти из аккаунта'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) =>
      const Text('Профиль', style: _pageTitle);
}

class _IdentityCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final joined = _memberSince(user['date_joined']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: const Color(0xFF3263E6),
            child: Text(TokenStorage.initials(user),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(TokenStorage.displayName(user),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _cardTitle),
                const SizedBox(height: 3),
                Text(
                  _text(user['email'], 'Email не указан'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _muted,
                ),
                if (joined.isNotEmpty) Text(joined, style: _muted),
              ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _Metric(
                  value: '${_int(user['checks_available'])}',
                  label: 'проверок осталось',
                  blue: true)),
          const SizedBox(width: 10),
          Expanded(
              child: _Metric(
                  value: '${_int(user['checks_completed'])}',
                  label: 'всего проверено')),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final bool blue;
  const _Metric({required this.value, required this.label, this.blue = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 84,
        decoration: BoxDecoration(
            color: const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value,
              style: TextStyle(
                  color: blue
                      ? OySynAuthTokens.deepBlue
                      : OySynAuthTokens.textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w900)),
          Text(label, style: _muted),
        ]),
      );
}

class _Tabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Профиль', 'Уведомления', 'Защита'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = selected == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == labels.length - 1 ? 0 : 7,
            ),
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? OySynAuthTokens.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active
                          ? OySynAuthTokens.primaryBlue
                          : OySynAuthTokens.divider),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF5C677B),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  const _AccountCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        decoration: _card(),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text('Учётные данные', style: _sectionTitle)),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Изменить'),
              style: TextButton.styleFrom(
                foregroundColor: OySynAuthTokens.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const Divider(height: 22, color: OySynAuthTokens.divider),
          _DataRow(
              label: 'Фамилия', value: _text(user['last_name'], 'Не указано')),
          _DataRow(
              label: 'Имя', value: _text(user['first_name'], 'Не указано')),
          _DataRow(
              label: 'Отчество',
              value: _text(user['middle_name'], 'Не указано')),
          _DataRow(
              label: 'Телефон',
              value: _text(user['phone_number'], 'Не указано')),
          _DataRow(
              label: 'Эл. почта',
              value: _text(user['email'], 'Не указано'),
              singleLine: true,
              last: true),
        ]),
      );
}

class _ProfileEditor extends StatefulWidget {
  final Map<String, dynamic> user;

  const _ProfileEditor({required this.user});

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _middleName;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName =
        TextEditingController(text: widget.user['first_name']?.toString());
    _lastName =
        TextEditingController(text: widget.user['last_name']?.toString());
    _middleName =
        TextEditingController(text: widget.user['middle_name']?.toString());
    _phone =
        TextEditingController(text: widget.user['phone_number']?.toString());
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _middleName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ProfileService.updateProfile({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'middle_name': _middleName.text.trim(),
        'phone_number': _phone.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить данные: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: OySynAuthTokens.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9D1E2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Учётные данные', style: _pageTitle),
            const SizedBox(height: 16),
            _EditField(label: 'Фамилия', controller: _lastName),
            _EditField(label: 'Имя', controller: _firstName),
            _EditField(label: 'Отчество', controller: _middleName),
            _EditField(
              label: 'Телефон',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PinChangeStep { current, newPin, confirm }

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _pinKey = GlobalKey<PinCodeInputState>();
  _PinChangeStep _step = _PinChangeStep.current;
  String? _currentPin;
  String? _newPin;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final configured = await SecurityService.isSecurityConfigured();
    if (!mounted) return;
    setState(() {
      _step = configured ? _PinChangeStep.current : _PinChangeStep.newPin;
      _loading = false;
    });
  }

  Future<void> _onCompleted(String pin) async {
    if (_saving) return;
    setState(() => _error = null);

    switch (_step) {
      case _PinChangeStep.current:
        setState(() => _saving = true);
        final valid = await SecurityService.verifyPin(pin);
        if (!mounted) return;
        if (!valid) {
          setState(() {
            _saving = false;
            _error = 'Текущий PIN-код введён неверно.';
          });
          _pinKey.currentState?.clear();
          return;
        }
        _currentPin = pin;
        _moveTo(_PinChangeStep.newPin);
      case _PinChangeStep.newPin:
        if (pin == _currentPin) {
          setState(
              () => _error = 'Новый PIN-код должен отличаться от текущего.');
          _pinKey.currentState?.clear();
          return;
        }
        _newPin = pin;
        _moveTo(_PinChangeStep.confirm);
      case _PinChangeStep.confirm:
        if (pin != _newPin) {
          setState(() => _error = 'PIN-коды не совпадают. Повторите ввод.');
          _pinKey.currentState?.clear();
          return;
        }
        setState(() => _saving = true);
        await SecurityService.savePin(pin);
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _moveTo(_PinChangeStep step) {
    setState(() {
      _step = step;
      _saving = false;
      _error = null;
    });
    _pinKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _PinChangeStep.current => 'Введите текущий PIN',
      _PinChangeStep.newPin => 'Создайте новый PIN',
      _PinChangeStep.confirm => 'Повторите новый PIN',
    };
    final description = switch (_step) {
      _PinChangeStep.current => 'Подтвердите, что это действительно вы.',
      _PinChangeStep.newPin => 'Используйте новый 4-значный код для входа.',
      _PinChangeStep.confirm => 'Введите новый код ещё раз для подтверждения.',
    };
    final stepIndex = switch (_step) {
      _PinChangeStep.current => 0,
      _PinChangeStep.newPin => 1,
      _PinChangeStep.confirm => 2,
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: OySynAuthTokens.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D1E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: OySynAuthTokens.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Смена PIN-кода', style: _sectionTitle),
                ),
                IconButton(
                  onPressed: _saving ? null : Navigator.of(context).pop,
                  tooltip: 'Закрыть',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (index) {
                final active = index <= stepIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
                    decoration: BoxDecoration(
                      color: active
                          ? OySynAuthTokens.primaryBlue
                          : const Color(0xFFDCE3F1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: _cardTitle),
            const SizedBox(height: 7),
            Text(description, textAlign: TextAlign.center, style: _muted),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: CircularProgressIndicator(),
              )
            else
              PinCodeInput(
                key: _pinKey,
                enabled: !_saving,
                errorText: _error,
                onCompleted: _onCompleted,
              ),
            if (_saving) ...[
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.phonelink_lock_rounded,
                  size: 18,
                  color: OySynAuthTokens.textMuted,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PIN-код хранится только на этом устройстве и не передаётся в Core.',
                    style: TextStyle(
                      color: OySynAuthTokens.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: OySynAuthTokens.textMuted,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(controller: controller, keyboardType: keyboardType),
          ],
        ),
      );
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  final bool singleLine;
  const _DataRow({
    required this.label,
    required this.value,
    this.last = false,
    this.singleLine = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: OySynAuthTokens.divider))),
        child: Row(children: [
          Expanded(child: Text(label, style: _muted)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: singleLine
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(value, style: _dataValueStyle),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: _dataValueStyle,
                  ),
          ),
        ]),
      );
}

const _dataValueStyle = TextStyle(
  color: OySynAuthTokens.textDark,
  fontSize: 15,
  fontWeight: FontWeight.w800,
);

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard(
      {required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _card(),
        child: Row(children: [
          Icon(icon, color: OySynAuthTokens.primaryBlue, size: 30),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: _sectionTitle),
                const SizedBox(height: 4),
                Text(text, style: _muted)
              ])),
        ]),
      );
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavigationCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: OySynAuthTokens.primaryBlue)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _muted)
                  ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5BECE)),
            ]),
          ),
        ),
      );
}

const _pageTitle = TextStyle(
    color: OySynAuthTokens.textDark, fontSize: 26, fontWeight: FontWeight.w800);
const _cardTitle = TextStyle(
    color: OySynAuthTokens.textDark,
    fontSize: 19,
    height: 1.12,
    fontWeight: FontWeight.w800);
const _sectionTitle = TextStyle(
    color: OySynAuthTokens.textDark, fontSize: 17, fontWeight: FontWeight.w800);
const _muted = TextStyle(
    color: OySynAuthTokens.textMuted,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600);

BoxDecoration _card({double radius = 16}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: OySynAuthTokens.divider));

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
String _text(dynamic value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _memberSince(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря'
  ];
  return 'Участник с ${months[date.month - 1]} ${date.year}';
}
