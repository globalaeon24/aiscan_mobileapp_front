import 'package:flutter/material.dart';

import '../../../storage/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../services/profile_service.dart';
import '../../../services/security_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<Map<String, dynamic>?> _loadUser() async {
    final cached = await TokenStorage.getUser();
    try {
      final fresh = await ProfileService.getProfile();
      if (fresh.isNotEmpty) {
        final enriched = await _withOrganization(fresh);
        await TokenStorage.saveUser(enriched);
        return enriched;
      }
    } catch (_) {
      // Cached profile is enough for rendering this page.
    }
    return cached;
  }

  Future<Map<String, dynamic>> _withOrganization(
    Map<String, dynamic> user,
  ) async {
    final organizationId = _asInt(
      user['organization_id'] ??
          user['core_organization_id'] ??
          user['organization']?['id'],
    );
    if (organizationId == null) return user;

    try {
      final organization = await ProfileService.getOrganization(organizationId);
      if (organization.isEmpty) return user;

      return {
        ...user,
        'organization_name': organization['name'] ??
            organization['title'] ??
            organization['organization_name'] ??
            user['organization_name'],
        'organization': organization,
      };
    } catch (_) {
      return user;
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorage.clear();
    await SecurityService.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Text(
          'Профиль',
          style: OySynTextStyles.sectionTitle,
        ),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, dynamic>?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting &&
                user == null) {
              return const _ProfileSkeleton();
            }

            return _ProfileContent(user: user);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти'),
          ),
        ),
      ],
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic>? user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final fullName = TokenStorage.displayName(user);
    final email = _value(user, 'email');
    final role = _roleLabel(_value(user, 'role'));
    final organization = _organizationName(user);
    final checksAvailable = _value(user, 'checks_available');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Text(
                  TokenStorage.initials(user),
                  style: const TextStyle(
                    color: OySynAuthTokens.primaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFBFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCEBFF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: OySynAuthTokens.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Доступные проверки',
                  style: TextStyle(
                    color: Color(0xFF2F3B48),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                checksAvailable,
                style: const TextStyle(
                  color: OySynAuthTokens.primaryBlue,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _ProfileMenuItem(
            icon: Icons.devices_rounded,
            title: 'Связанные устройства',
            subtitle: 'Веб-сессии, открытые через QR',
            onTap: () => Navigator.of(context).pushNamed('/linked-devices'),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ProfileField(
                icon: Icons.badge_outlined,
                label: 'Роль',
                value: role,
              ),
              const _ProfileDivider(),
              _ProfileField(
                icon: Icons.business_outlined,
                label: 'Организация',
                value: organization,
              ),
              const _ProfileDivider(),
              _ProfileField(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: email,
              ),
              const _ProfileDivider(),
              _ProfileField(
                icon: Icons.person_outline_rounded,
                label: 'ФИО',
                value: fullName,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _value(Map<String, dynamic>? user, String key) {
    final value = user?[key];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? 'Не указано' : text;
  }

  static String _organizationName(Map<String, dynamic>? user) {
    final value = user?['organization_name'] ??
        user?['organization']?['name'] ??
        user?['organization']?['title'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? 'Не указано' : text;
  }

  static String _roleLabel(String role) {
    return switch (role) {
      'EXP' => 'Expert',
      'MOD' => 'Moderator',
      'SUP' => 'Supervisor',
      'ADM' => 'Administrator',
      _ => role,
    };
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: OySynAuthTokens.iconGrey, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: OySynAuthTokens.primaryBlue, size: 23),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: OySynAuthTokens.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: OySynAuthTokens.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: OySynAuthTokens.iconGrey,
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: OySynAuthTokens.divider,
      indent: 50,
      endIndent: 16,
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
