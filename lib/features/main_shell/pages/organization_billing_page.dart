import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationBillingPage extends StatefulWidget {
  final int organizationId;
  final String organizationName;
  final int organizationBalance;

  const OrganizationBillingPage({
    super.key,
    required this.organizationId,
    required this.organizationName,
    required this.organizationBalance,
  });

  @override
  State<OrganizationBillingPage> createState() =>
      _OrganizationBillingPageState();
}

class _OrganizationBillingPageState extends State<OrganizationBillingPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchController = TextEditingController();
  final Map<int, int> _values = {};
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = ProfileService.getOrganizationBilling(widget.organizationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Организация · ${widget.organizationName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _Styles.eyebrow),
                        const Text('Биллинг', style: _Styles.pageTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Лимиты на проверки', style: _Styles.sectionTitle),
                  const SizedBox(height: 3),
                  Text(
                    'Распределяйте проверки из общего лимита между сотрудниками. Доступно: ${widget.organizationBalance}. Изменения сохраняются в журнале.',
                    style: _Styles.subtitle,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени или email...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: OutlinedButton(
                            onPressed: () => setState(_reload),
                            child: const Text('Повторить загрузку')));
                  }
                  final users = _filtered(snapshot.data ?? const []);
                  if (users.isEmpty) {
                    return const Center(
                        child: Text('Сотрудники не найдены',
                            style: _Styles.subtitle));
                  }
                  for (final user in users) {
                    final id = _int(user['id']);
                    _values.putIfAbsent(
                        id, () => _int(user['checks_available']));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(_reload),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final id = _int(user['id']);
                        return _BillingCard(
                          user: user,
                          value: _values[id] ?? 0,
                          saving: _saving.contains(id),
                          changed: (_values[id] ?? 0) !=
                              _int(user['checks_available']),
                          onMinus: () => setState(() => _values[id] =
                              ((_values[id] ?? 0) - 1).clamp(0, 999999999)),
                          onPlus: () => setState(
                              () => _values[id] = (_values[id] ?? 0) + 1),
                          onApply: () => _apply(user),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> users) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((user) => [
              user['full_name'],
              user['first_name'],
              user['last_name'],
              user['email']
            ].whereType<Object>().join(' ').toLowerCase().contains(query))
        .toList();
  }

  Future<void> _apply(Map<String, dynamic> user) async {
    final id = _int(user['id']);
    final value = _values[id] ?? 0;
    setState(() => _saving.add(id));
    try {
      await ProfileService.updateOrganizationBilling(
          widget.organizationId, id, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Лимит сотрудника обновлён')));
      setState(() {
        _values.remove(id);
        _reload();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось изменить лимит: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving.remove(id));
      }
    }
  }
}

class _BillingCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int value;
  final bool saving;
  final bool changed;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onApply;
  const _BillingCard(
      {required this.user,
      required this.value,
      required this.saving,
      required this.changed,
      required this.onMinus,
      required this.onPlus,
      required this.onApply});

  @override
  Widget build(BuildContext context) {
    final quota = _int(user['quote']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _Styles.card,
      child: Column(children: [
        Row(children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFEFE8FF),
              child: Text(_initials(user),
                  style: const TextStyle(
                      color: Color(0xFF6D4EF0), fontWeight: FontWeight.w800))),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_name(user),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _Styles.title),
                const SizedBox(height: 2),
                Text(_value(user['email']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _Styles.subtitle)
              ])),
          const SizedBox(width: 10),
          Column(children: [
            Text('$quota',
                style: TextStyle(
                    color: quota > 0
                        ? const Color(0xFF168A4C)
                        : OySynAuthTokens.textMuted,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const Text('квота',
                style:
                    TextStyle(color: OySynAuthTokens.textMuted, fontSize: 11))
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OySynAuthTokens.divider)),
                  child: Text('$value',
                      style: const TextStyle(
                          color: OySynAuthTokens.textDark,
                          fontSize: 21,
                          fontWeight: FontWeight.w900)))),
          const SizedBox(width: 10),
          _StepButton(icon: Icons.add_rounded, onTap: onPlus),
          const SizedBox(width: 10),
          SizedBox(
              width: 126,
              height: 48,
              child: FilledButton(
                  onPressed: saving || !changed ? null : onApply,
                  child: Text(saving ? '...' : 'Применить'))),
        ]),
        const SizedBox(height: 9),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Осталось проверок · ${_roleLabel(user['role']?.toString())}',
                style: _Styles.subtitle)),
      ]),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: const Color(0xFFF6F8FE),
          side: const BorderSide(color: OySynAuthTokens.divider),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
}

class _Styles {
  static const pageTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 24,
      fontWeight: FontWeight.w800);
  static const eyebrow = TextStyle(
      color: OySynAuthTokens.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w700);
  static const sectionTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 18,
      fontWeight: FontWeight.w800);
  static const title = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 16,
      fontWeight: FontWeight.w800);
  static const subtitle = TextStyle(
      color: OySynAuthTokens.textMuted,
      fontSize: 13,
      height: 1.25,
      fontWeight: FontWeight.w600);
  static final card = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OySynAuthTokens.divider));
}

String _name(Map<String, dynamic> user) => _value(
    user['full_name'] ??
        [user['last_name'], user['first_name']].whereType<Object>().join(' '),
    _value(user['email']));
String _initials(Map<String, dynamic> user) {
  final parts = _name(user).split(RegExp(r'\s+'));
  return parts
      .take(2)
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _value(dynamic value, [String fallback = 'Не указано']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
String _roleLabel(String? role) => switch (role) {
      'MOD' => 'Модератор',
      'SUP' => 'Супервизор',
      'ADM' => 'Администратор',
      'AUT' => 'Автор',
      'DEC' => 'Деканат',
      _ => 'Эксперт'
    };
