import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/profile_service.dart';
import '../../../services/security_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/oysyn_controls.dart';
import '../../../widgets/pin_code_input.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>?> _profile;
  late Future<Map<String, dynamic>> _statistics;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
    _statistics = ProfileService.getStatistics();
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

  Future<bool> _saveNotifications(
    Map<String, dynamic> user,
    bool enabled,
  ) async {
    try {
      final updated = await ProfileService.updateProfile({
        'notification': enabled,
      });
      final merged = <String, dynamic>{...user, ...updated};
      await TokenStorage.saveUser(merged);
      if (mounted) setState(() => _profile = Future.value(merged));
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: TokenStorage.userListenable,
      builder: (context, currentUser, _) =>
          FutureBuilder<Map<String, dynamic>?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null &&
              currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final user =
              currentUser ?? snapshot.data ?? const <String, dynamic>{};
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
                1 => _StatisticsCard(
                    future: _statistics,
                    onRetry: () => setState(() {
                      _statistics = ProfileService.getStatistics();
                    }),
                  ),
                2 => _NotificationSettingsCard(
                    enabled: _bool(user['notification']),
                    onSave: (enabled) => _saveNotifications(user, enabled),
                  ),
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
                const SizedBox(height: 18),
                const _AppVersionLabel(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AppVersionLabel extends StatelessWidget {
  const _AppVersionLabel();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final package = snapshot.data;
          if (package == null) return const SizedBox.shrink();
          return Semantics(
            label:
                'Версия приложения ${package.version}, сборка ${package.buildNumber}',
            child: Center(
              child: Text(
                'Версия ${package.version} (${package.buildNumber})',
                style: const TextStyle(
                  color: OySynAuthTokens.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
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
    const items = [
      (Icons.person_outline_rounded, 'Профиль'),
      (Icons.query_stats_rounded, 'Статистика'),
      (Icons.notifications_none_rounded, 'Уведомления'),
      (Icons.shield_outlined, 'Защита'),
    ];
    return Row(
      children: List.generate(items.length, (index) {
        final active = selected == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : 6,
            ),
            child: Material(
              color: active ? OySynAuthTokens.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? OySynAuthTokens.primaryBlue
                          : OySynAuthTokens.divider,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[index].$1,
                          size: 16,
                          color:
                              active ? Colors.white : OySynAuthTokens.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          items[index].$2,
                          maxLines: 1,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : OySynAuthTokens.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
      final merged = <String, dynamic>{...widget.user, ...updated};
      final nameParts = [
        merged['last_name'],
        merged['first_name'],
        merged['middle_name'],
      ]
          .map((value) => value?.toString().trim() ?? '')
          .where((v) => v.isNotEmpty);
      merged['full_name'] = nameParts.join(' ');
      if (mounted) Navigator.of(context).pop(merged);
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
        20 + oysynInteractiveBottomInset(context),
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
        20 + oysynInteractiveBottomInset(context),
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

class _StatisticsCard extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final VoidCallback onRetry;

  const _StatisticsCard({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180,
            decoration: _card(),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: _card(),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: OySynAuthTokens.iconGrey,
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Не удалось загрузить статистику',
                  style: OySynTextStyles.cardTitle,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final folders = data['folders'] is List
            ? (data['folders'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : const <Map<String, dynamic>>[];
        final average = _double(data['average_originality']);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Статистика', style: OySynTextStyles.cardTitle),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: OySynAuthTokens.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatisticMetric(
                            icon: Icons.fact_check_outlined,
                            value: '${_int(data['total_checks'])}',
                            label: 'Всего',
                          ),
                        ),
                        const _MetricDivider(),
                        Expanded(
                          child: _StatisticMetric(
                            icon: Icons.calendar_month_outlined,
                            value: '${_int(data['checks_current_month'])}',
                            label: 'За месяц',
                          ),
                        ),
                        const _MetricDivider(),
                        Expanded(
                          child: _StatisticMetric(
                            icon: Icons.percent_rounded,
                            value:
                                average == null ? '—' : '${_number(average)}%',
                            label: 'Оригинальность',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: _card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Статистика по папкам',
                    style: OySynTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Документы, завершённые проверки и оригинальность.',
                    style: OySynTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  if (folders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text('Папок пока нет', style: _muted),
                      ),
                    )
                  else
                    for (var index = 0; index < folders.length; index++) ...[
                      _FolderStatisticRow(folder: folders[index]),
                      if (index != folders.length - 1)
                        const Divider(
                          height: 1,
                          color: OySynAuthTokens.divider,
                        ),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatisticMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatisticMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: OySynAuthTokens.primaryBlue),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: _cardTitle),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: OySynTextStyles.caption),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 70,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: OySynAuthTokens.divider,
        ),
      );
}

class _FolderStatisticRow extends StatelessWidget {
  final Map<String, dynamic> folder;

  const _FolderStatisticRow({required this.folder});

  @override
  Widget build(BuildContext context) {
    final average = _double(folder['average_originality']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              folder['id'] == null
                  ? Icons.folder_open_outlined
                  : Icons.folder_outlined,
              size: 18,
              color: OySynAuthTokens.primaryBlue,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder['name']?.toString() ?? 'Папка',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OySynTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_int(folder['documents'])} документов · '
                  '${_int(folder['checked'])} проверено',
                  style: OySynTextStyles.caption,
                ),
                if (average != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (average / 100).clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE1E8F5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            average == null ? '—' : '${_number(average)}%',
            style: const TextStyle(
              color: OySynAuthTokens.deepBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatefulWidget {
  final bool enabled;
  final Future<bool> Function(bool enabled) onSave;

  const _NotificationSettingsCard({
    required this.enabled,
    required this.onSave,
  });

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  late bool _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.enabled;
  }

  @override
  void didUpdateWidget(covariant _NotificationSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled && !_saving) {
      _value = widget.enabled;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await widget.onSave(_value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки уведомлений сохранены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Уведомления', style: OySynTextStyles.sectionTitle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: OySynAuthTokens.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.alternate_email_rounded,
                    color: OySynAuthTokens.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email-уведомления',
                          style: OySynTextStyles.cardTitle),
                      SizedBox(height: 4),
                      Text(
                        'Получать важные уведомления системы на электронную почту.',
                        style: OySynTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OySynSwitch(
                  value: _value,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _value = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Рассылку можно отключить в любой момент.',
            style: OySynTextStyles.caption,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving || _value == widget.enabled ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
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
double? _double(dynamic value) {
  if (value == null) return null;
  return value is num
      ? value.toDouble()
      : double.tryParse(value.toString().replaceAll(',', '.'));
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'true', '1', 'yes'}.contains(value?.toString().toLowerCase());
}

String _number(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

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
