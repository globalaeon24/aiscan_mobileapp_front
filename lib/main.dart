import 'package:flutter/material.dart';

import 'features/main_shell/main_shell.dart';
import 'features/main_shell/pages/linked_devices_page.dart';
import 'theme/app_theme.dart';
import 'screens/login_register_screen.dart';
import 'screens/mobile_intro_screen.dart';
import 'screens/security_setup_screen.dart';
import 'screens/security_unlock_screen.dart';
import 'services/security_service.dart';
import 'services/app_update_service.dart';
import 'storage/token_storage.dart';

/// 🔴 ГЛОБАЛЬНЫЙ navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Проверяем наличие токена при старте
  final token = await TokenStorage.getToken();
  final securityConfigured = await SecurityService.isSecurityConfigured();

  runApp(
    ScanAIApp(
      initialRoute: token == null
          ? '/login'
          : securityConfigured
              ? '/unlock'
              : '/security-setup',
    ),
  );
}

class ScanAIApp extends StatefulWidget {
  final String initialRoute;

  const ScanAIApp({super.key, required this.initialRoute});

  @override
  State<ScanAIApp> createState() => _ScanAIAppState();
}

class _ScanAIAppState extends State<ScanAIApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkForUpdate();
  }

  void _checkForUpdate() {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null) AppUpdateService.showIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 🔴 КЛЮЧЕВО
      title: 'ScanAI',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      routes: {
        '/login': (_) => const LoginRegisterScreen(),
        '/security-setup': (_) => const SecuritySetupScreen(),
        '/unlock': (_) => const SecurityUnlockScreen(),
        '/mobile-intro': (_) => const MobileIntroScreen(),
        '/home': (_) => const MainShell(),
        '/linked-devices': (_) => const LinkedDevicesPage(),
      },
    );
  }
}
