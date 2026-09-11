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
import '../../models/scan_result.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int? _organizationId;
  int _documentsRevision = 0;
  ScanResult? _recentlyCreatedCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNavigationAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProfile();
    }
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
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final fresh = await ProfileService.getProfile();
      if (fresh.isEmpty) return;
      await TokenStorage.saveUser(fresh);
      final value = fresh['organization_id'] ?? fresh['core_organization_id'];
      final organizationId =
          value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
      if (mounted && organizationId != _organizationId) {
        setState(() => _organizationId = organizationId);
      }
    } catch (_) {}
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
    await _navigateToCheck();
  }

  Future<void> _navigateToCheck() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute<ScanResult>(builder: (_) => const ScanScreen()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _recentlyCreatedCheck = result;
      _documentsRevision++;
      _selectedIndex = 1;
    });
    await _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onCheck: _openCheck,
        onDocuments: () => _selectPage(1),
      ),
      DocumentsPage(
        key: ValueKey(_documentsRevision),
        pendingResult: _recentlyCreatedCheck,
      ),
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
