import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_code_input.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final _pinKey = GlobalKey<PinCodeInputState>();
  String? _firstPin;
  String? _error;
  bool _saving = false;

  bool get _confirming => _firstPin != null;

  Future<void> _onPinCompleted(String pin) async {
    if (_saving) return;

    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      _pinKey.currentState?.clear();
      return;
    }

    if (pin != _firstPin) {
      setState(() => _error = 'Коды не совпадают. Введите повторно.');
      _pinKey.currentState?.clear();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    await SecurityService.savePin(pin);
    final biometricAvailable = await SecurityService.canUseBiometrics();
    if (biometricAvailable) {
      final ok = await SecurityService.authenticateWithBiometrics(
        reason: 'Включите быстрый вход в OySyn',
      );
      await SecurityService.setBiometricEnabled(ok);
    } else {
      await SecurityService.setBiometricEnabled(false);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/mobile-intro');
  }

  void _reset() {
    setState(() {
      _firstPin = null;
      _error = null;
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
            stops: [0, 0.42, 1],
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
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: OySynAuthTokens.shadowBlue,
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: OySynAuthTokens.primaryBlue,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _confirming ? 'Повторите код' : 'Создайте код входа',
                      textAlign: TextAlign.center,
                      style: OySynTextStyles.welcomeTitle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _confirming
                          ? 'Введите тот же 4-значный код еще раз.'
                          : 'Он понадобится, если Face ID или биометрия не распознает вас.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: OySynAuthTokens.textMuted,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 34),
                    PinCodeInput(
                      key: _pinKey,
                      enabled: !_saving,
                      errorText: _error,
                      onCompleted: _onPinCompleted,
                    ),
                    const SizedBox(height: 12),
                    if (_confirming && !_saving)
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Изменить первый код'),
                      ),
                    if (_saving) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                    const SizedBox(height: 36),
                    const _BiometricNote(),
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

class _BiometricNote extends StatelessWidget {
  const _BiometricNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OySynAuthTokens.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.face_retouching_natural_rounded,
            color: OySynAuthTokens.primaryBlue,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'После подтверждения кода приложение предложит быстрый вход через Face ID, Touch ID или биометрию Android.',
              style: TextStyle(
                color: OySynAuthTokens.textMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
