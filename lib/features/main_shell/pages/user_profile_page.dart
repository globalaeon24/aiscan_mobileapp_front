import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../services/security_service.dart';
import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import 'organization_page.dart';

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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            _PageHeader(balance: _int(user['checks_available'])),
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
                    _AccountCard(user: user),
                    const SizedBox(height: 14),
                    _NavigationCard(
                      icon: Icons.business_outlined,
                      title: 'Организация',
                      subtitle: _text(
                        user['organization_name'],
                        'Данные и управление',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrganizationPage(
                            initialOrganizationId: _nullableInt(
                              user['organization_id'],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              1 => _InfoCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Статистика',
                  text:
                      'Всего завершено проверок: ${_int(user['checks_completed'])}'),
              2 => const _InfoCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Уведомления',
                  text:
                      'Настройки уведомлений будут подключены после расширения API Core.'),
              _ => Column(
                  children: [
                    const _InfoCard(
                      icon: Icons.shield_outlined,
                      title: 'Защита аккаунта',
                      text: 'PIN-код, биометрия и активные сессии.',
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
              TextButton.icon(
                onPressed: _logout,
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: const Color(0xFFDF3E48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Выйти из аккаунта'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int balance;
  const _PageHeader({required this.balance});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Text('Профиль', style: _pageTitle)),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: _card(radius: 14),
            child: Row(children: [
              const Icon(Icons.wallet_outlined, size: 19),
              const SizedBox(width: 8),
              Text('$balance',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      );
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
                Text(_text(user['email'], 'Email не указан'), style: _muted),
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
    const labels = ['Профиль', 'Статистика', 'Уведомл.', 'Защита'];
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
  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        decoration: _card(),
        child: Column(children: [
          const Row(children: [
            Expanded(child: Text('Учётные данные', style: _sectionTitle)),
            Icon(Icons.edit_outlined,
                color: OySynAuthTokens.primaryBlue, size: 19),
            SizedBox(width: 5),
            Text('Изменить',
                style: TextStyle(
                    color: OySynAuthTokens.primaryBlue,
                    fontWeight: FontWeight.w800)),
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
              last: true),
        ]),
      );
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _DataRow({required this.label, required this.value, this.last = false});

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
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: OySynAuthTokens.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800))),
        ]),
      );
}

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
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
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
