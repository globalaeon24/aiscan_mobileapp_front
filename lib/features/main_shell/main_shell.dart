import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/documents_page.dart';
import 'pages/qr_page.dart';
import 'pages/user_profile_page.dart';
import 'widgets/main_bottom_nav.dart';
import '../../screens/scan_screen.dart';
import '../../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _selectPage(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onCheck: () => _selectPage(2),
        onDocuments: () => _selectPage(1),
      ),
      const DocumentsPage(),
      const SizedBox.shrink(),
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
      ),
    );
  }
}
