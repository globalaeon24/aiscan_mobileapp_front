import 'package:flutter/material.dart';

import 'features/main_shell/main_shell.dart';
import 'theme/app_theme.dart';
import 'screens/login_register_screen.dart';
import 'screens/mobile_intro_screen.dart';
import 'storage/token_storage.dart';

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
        '/mobile-intro': (_) => const MobileIntroScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}
