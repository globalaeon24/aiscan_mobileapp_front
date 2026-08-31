import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_code_input.dart';

class SecurityUnlockScreen extends StatefulWidget {
  const SecurityUnlockScreen({super.key});

  @override
  State<SecurityUnlockScreen> createState() => _SecurityUnlockScreenState();
}

class _SecurityUnlockScreenState extends State<SecurityUnlockScreen> {
  final _pinKey = GlobalKey<PinCodeInputState>();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  Future<void> _tryBiometrics() async {
    if (_checking) return;
    final enabled = await SecurityService.isBiometricEnabled();
    if (!enabled) return;

    setState(() => _checking = true);
    final ok = await SecurityService.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _pinKey.currentState?.requestKeyboard(),
    );
  }

  Future<void> _onPinCompleted(String pin) async {
    if (_checking) return;

    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await SecurityService.verifyPin(pin);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    setState(() {
      _checking = false;
      _error = 'Неверный код. Попробуйте еще раз.';
    });
    _pinKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.surface,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              OySynAuthTokens.topWash,
              OySynAuthTokens.surface,
              OySynAuthTokens.surface,
            ],
            stops: [0, 0.38, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: OySynAuthTokens.shadowBlue,
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Image.asset(OySynAuthTokens.logoAsset),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Вход в OySyn',
                      textAlign: TextAlign.center,
                      style: OySynTextStyles.welcomeTitle,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Подтвердите вход через Face ID или введите 4-значный код.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: OySynAuthTokens.textMuted,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 34),
                    PinCodeInput(
                      key: _pinKey,
                      enabled: !_checking,
                      errorText: _error,
                      onCompleted: _onPinCompleted,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _checking ? null : _tryBiometrics,
                      icon: const Icon(Icons.face_rounded),
                      label: const Text('Использовать биометрию'),
                    ),
                    if (_checking) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
