import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/login_register_screen.dart';
import 'storage/token_storage.dart';
import 'models/scan_result.dart';

/// 🔴 ГЛОБАЛЬНЫЙ navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем наличие токена при старте
  final token = await TokenStorage.getToken();

  runApp(
    ScanAIApp(
      initialRoute: token == null ? '/login' : '/home',
    ),
  );
}

class ScanAIApp extends StatelessWidget {
  final String initialRoute;

  const ScanAIApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 🔴 КЛЮЧЕВО
      title: 'ScanAI',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginRegisterScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  Future<void> _openScanScreen() async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(
        builder: (_) => const ScanScreen(),
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body =
        _selectedIndex == 0 ? const HomeScreen() : const ProfileScreen();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanAI'),
        centerTitle: true,
        elevation: 0,
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: body,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanScreen,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('ScanAI'),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Главная',
                selected: _selectedIndex == 0,
                onTap: () => _onNavTap(0),
              ),
              const SizedBox(width: 48),
              _BottomNavItem(
                icon: Icons.person_outline,
                label: 'Профиль',
                selected: _selectedIndex == 1,
                onTap: () => _onNavTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    letterSpacing: 0.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}