import 'package:flutter/material.dart';

import 'pages/check_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/documents_page.dart';
import 'pages/qr_page.dart';
import 'pages/user_profile_page.dart';
import 'widgets/main_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _pages = [
    DashboardPage(),
    DocumentsPage(),
    QrPage(),
    CheckPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
