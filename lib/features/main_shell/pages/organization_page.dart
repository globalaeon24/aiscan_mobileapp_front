import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';
import 'organization_billing_page.dart';
import 'organization_billing_journal_page.dart';
import 'organization_reports_page.dart';
import '../../../widgets/oysyn_controls.dart';
import 'organization_users_page.dart';

class OrganizationPage extends StatefulWidget {
  final int? initialOrganizationId;

  const OrganizationPage({super.key, this.initialOrganizationId});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  late Future<List<Map<String, dynamic>>> _future;
  int? _selectedOrganizationId;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.getOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () {
                  setState(() => _future = ProfileService.getOrganizations());
                },
              );
            }

            final organizations = snapshot.data ?? const [];
            if (organizations.isEmpty) {
              return const _EmptyState();
            }
            final selected = _selectOrganization(organizations);
            return _OrganizationDetails(
              organization: selected,
              organizations: organizations,
              onSelected: (id) => setState(() => _selectedOrganizationId = id),
            );
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _selectOrganization(
      List<Map<String, dynamic>> organizations) {
    final wanted = _selectedOrganizationId ?? widget.initialOrganizationId;
    if (wanted != null) {
      for (final organization in organizations) {
        if (_asInt(organization['id']) == wanted) return organization;
      }
    }
    return organizations.first;
  }
}

class _OrganizationDetails extends StatelessWidget {
  final Map<String, dynamic> organization;
  final List<Map<String, dynamic>> organizations;
  final ValueChanged<int> onSelected;

  const _OrganizationDetails({
    required this.organization,
    required this.organizations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final id = _asInt(organization['id']);
    final title = _text(organization['title'], 'Организация');
    final city = _text(
      organization['city_display'] ?? organization['city'],
      'Город не указан',
    );
    final created = _date(organization['created_at']);
    final users = _asInt(organization['users_count']) ?? 0;
    final reports = _asInt(organization['reports_count']) ?? 0;
    final apiSettings = _asInt(organization['api_settings_count']) ?? 0;
    final organizationBalance = _asInt(organization['checks_available']) ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Row(
          children: [
            _SquareButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Text('Организация', style: _Styles.pageTitle),
            ),
            if (organizations.length > 1)
              IconButton(
                tooltip: 'Выбрать организацию',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () async {
                  final selected = await showOySynChoiceSheet<int>(
                    context,
                    title: 'Выберите организацию',
                    selected: id ?? -1,
                    choices: organizations
                        .where((item) => _asInt(item['id']) != null)
                        .map((item) => OySynChoice(
                              _asInt(item['id'])!,
                              _text(item['title'], 'Организация'),
                              icon: Icons.business_outlined,
                            ))
                        .toList(),
                  );
                  if (selected != null) onSelected(selected);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        _OrganizationHeader(
          title: title,
          subtitle: [city, if (created.isNotEmpty) 'с $created'].join(' · '),
        ),
        const SizedBox(height: 20),
        _MenuGroup(
          children: [
            _OrganizationMenuItem(
              icon: Icons.business_rounded,
              title: 'Данные организации',
              subtitle: 'Название, город, адрес и статус',
              onTap: () => _showInfo(context, title, organization),
            ),
            _OrganizationMenuItem(
              icon: Icons.bar_chart_rounded,
              title: 'Отчёты',
              subtitle: 'Проверки и результаты организации',
              badge: reports > 0 ? '$reports' : null,
              onTap: id == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrganizationReportsPage(
                            organizationId: id,
                            organizationName: title,
                          ),
                        ),
                      ),
            ),
          ],
        ),
        const _SectionLabel('УПРАВЛЕНИЕ'),
        _MenuGroup(
          children: [
            _OrganizationMenuItem(
              icon: Icons.group_outlined,
              title: 'Пользователи',
              subtitle: '$users сотрудников · роли и доступ',
              onTap: id == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrganizationUsersPage(
                            organizationId: id,
                            organizationName: title,
                          ),
                        ),
                      ),
            ),
            _OrganizationMenuItem(
              icon: Icons.tune_rounded,
              title: 'Администрирование',
              subtitle: 'Пороги, эксперты, индексация, API',
              badge: apiSettings > 0 ? '$apiSettings' : null,
              onTap: id == null ? null : () => _showApiSettings(context, id),
            ),
          ],
        ),
        const _SectionLabel('БИЛЛИНГ'),
        _MenuGroup(
          children: [
            _OrganizationMenuItem(
              icon: Icons.credit_card_rounded,
              title: 'Биллинг',
              subtitle: 'Распределение квот сотрудникам',
              onTap: id == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrganizationBillingPage(
                            organizationId: id,
                            organizationName: title,
                            organizationBalance: organizationBalance,
                          ),
                        ),
                      ),
            ),
            _OrganizationMenuItem(
              icon: Icons.history_rounded,
              title: 'Журнал биллинга',
              subtitle: 'История операций и аналитика',
              onTap: id == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrganizationBillingJournalPage(
                            organizationId: id,
                            organizationName: title,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfo(
    BuildContext context,
    String title,
    Map<String, dynamic> organization,
  ) {
    _showDataSheet(
      context,
      title,
      [
        ('Город', _text(organization['city_display'], 'Не указан')),
        ('Адрес', _text(organization['address'], 'Не указан')),
        (
          'Проверок доступно',
          '${_asInt(organization['checks_available']) ?? 0}'
        ),
      ],
    );
  }

  Future<void> _showApiSettings(BuildContext context, int id) async {
    final data = await ProfileService.getOrganizationApiSettings(id);
    if (!context.mounted) return;
    final tokens = data['api_tokens'] as List<dynamic>? ?? const [];
    _showDataSheet(
      context,
      'API организации',
      tokens
          .whereType<Map<String, dynamic>>()
          .map((token) => (
                _text(token['name'], 'API-токен'),
                token['is_active'] == true ? 'Активен' : 'Отключен',
              ))
          .toList(),
    );
  }
}

void _showDataSheet(
  BuildContext context,
  String title,
  List<(String, String)> rows,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _Styles.cardTitle),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text('Данные отсутствуют', style: _Styles.subtitle)
            else
              ...rows.map((row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.$1, style: _Styles.body)),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            row.$2,
                            textAlign: TextAlign.right,
                            style: _Styles.subtitle,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    ),
  );
}

class _OrganizationHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _OrganizationHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _Styles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: OySynAuthTokens.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.radar_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _Styles.cardTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: _Styles.subtitle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F8EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Активна',
                style: TextStyle(
                    color: Color(0xFF168A4C), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_OrganizationMenuItem> children;

  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _Styles.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: OySynAuthTokens.divider),
          ],
        ],
      ),
    );
  }
}

class _OrganizationMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _OrganizationMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: OySynAuthTokens.primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _Styles.menuTitle),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _Styles.subtitle),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(badge!,
                    style: const TextStyle(
                        color: OySynAuthTokens.primaryBlue,
                        fontWeight: FontWeight.w800)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5BECE)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 20, 0, 10),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF99A4B8),
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      );
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 20)),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorState({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SquareButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 18),
                const Text('Организация', style: _Styles.pageTitle),
              ],
            ),
            const Spacer(),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(20),
                decoration: _Styles.cardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: OySynAuthTokens.primaryBlue,
                      size: 38,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Не удалось загрузить организацию',
                      textAlign: TextAlign.center,
                      style: _Styles.cardTitle,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _Styles.subtitle,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 210,
                      child: FilledButton(
                        onPressed: onRetry,
                        child: const Text('Повторить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _SquareButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop()),
            ),
          ),
          const Expanded(
              child: Center(
                  child:
                      Text('Организации не найдены', style: _Styles.subtitle))),
        ],
      );
}

class _Styles {
  static const pageTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 25,
      fontWeight: FontWeight.w800);
  static const cardTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 18,
      fontWeight: FontWeight.w800);
  static const menuTitle = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 17,
      fontWeight: FontWeight.w800);
  static const body = TextStyle(
      color: OySynAuthTokens.textDark,
      fontSize: 15,
      fontWeight: FontWeight.w700);
  static const subtitle = TextStyle(
      color: OySynAuthTokens.textMuted,
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w600);
  static final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OySynAuthTokens.divider));
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
