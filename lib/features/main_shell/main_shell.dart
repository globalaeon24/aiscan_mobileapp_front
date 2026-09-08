import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/documents_page.dart';
import 'pages/qr_page.dart';
import 'pages/organization_page.dart';
import 'pages/user_profile_page.dart';
import 'widgets/main_bottom_nav.dart';
import '../../services/profile_service.dart';
import '../../screens/scan_screen.dart';
import '../../theme/app_theme.dart';
import '../../storage/token_storage.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int? _organizationId;

  @override
  void initState() {
    super.initState();
    _loadNavigationAccess();
  }

  Future<void> _loadNavigationAccess() async {
    var user = await TokenStorage.getUser();
    try {
      final fresh = await ProfileService.getProfile();
      if (fresh.isNotEmpty) {
        user = fresh;
        await TokenStorage.saveUser(fresh);
      }
    } catch (_) {}
    final value = user?['organization_id'] ?? user?['core_organization_id'];
    final organizationId =
        value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    if (mounted) setState(() => _organizationId = organizationId);
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openCheck() async {
    try {
      final profile = await ProfileService.getProfile();
      final rawBalance = profile['checks_available'];
      if (rawBalance == null) return _navigateToCheck();
      final balance = rawBalance is num
          ? rawBalance.toInt()
          : int.tryParse(rawBalance?.toString() ?? '') ?? 0;
      if (!mounted) return;
      if (balance <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Лимит проверок исчерпан. Обратитесь к администратору организации.',
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // Форма и сервер выполнят повторную проверку лимита.
    }
    _navigateToCheck();
  }

  void _navigateToCheck() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onCheck: _openCheck,
        onDocuments: () => _selectPage(1),
      ),
      const DocumentsPage(),
      _organizationId == null
          ? const SizedBox.shrink()
          : OrganizationPage(initialOrganizationId: _organizationId),
      const QrPage(),
      const UserProfilePage(),
    ];

    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _selectedIndex,
        onChanged: _selectPage,
        showOrganization: _organizationId != null,
      ),
    );
  }
}
