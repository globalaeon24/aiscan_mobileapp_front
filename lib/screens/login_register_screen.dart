import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginKey = GlobalKey<FormState>();

  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regOrg = TextEditingController();
  final _regPass = TextEditingController();
  final _regPassRepeat = TextEditingController();
  final _regKey = GlobalKey<FormState>();

  bool _loginLoading = false;
  bool _regLoading = false;
  bool _passVisible = false;
  bool _registrationMode = false;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regOrg.dispose();
    _regPass.dispose();
    _regPassRepeat.dispose();
    super.dispose();
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
            stops: [0, 0.36, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 760;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: OySynAuthTokens.contentMaxWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OySynAuthTokens.screenHorizontalPadding,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: compact ? 28 : 70),
                            const _OySynBrand(),
                            SizedBox(height: compact ? 36 : 48),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _registrationMode
                                  ? _buildRegisterForm()
                                  : _buildLoginForm(),
                            ),
                            SizedBox(height: compact ? 44 : 120),
                            const Text(
                              'OySyn · v1.0.0',
                              style: TextStyle(
                                color: OySynAuthTokens.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AuthLabel('Email или логин'),
          const SizedBox(height: 10),
          _AuthField(
            controller: _loginEmail,
            icon: Icons.mail_outline_rounded,
            hintText: 'oysyn@gmail.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Введите email' : null,
          ),
          const SizedBox(height: 14),
          const _AuthLabel('Пароль'),
          const SizedBox(height: 10),
          _AuthField(
            controller: _loginPass,
            icon: Icons.lock_outline_rounded,
            hintText: '••••••••••',
            obscureText: !_passVisible,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _passVisible = !_passVisible),
              icon: Icon(
                _passVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: OySynAuthTokens.iconGrey,
                size: 24,
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Введите пароль' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: OySynAuthTokens.linkBlue,
              ),
              child: const Text(
                'Забыли пароль?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 42),
          _PrimaryAuthButton(
            text: 'Войти',
            loading: _loginLoading,
            onPressed: _tryLogin,
          ),
          const SizedBox(height: 30),
          const _OrDivider(),
          const SizedBox(height: 30),
          _SecondaryAuthButton(
            text: 'Зарегистрироваться',
            onPressed: () => setState(() => _registrationMode = true),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _regKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AuthLabel('Имя'),
          const SizedBox(height: 8),
          _AuthField(
            controller: _regName,
            icon: Icons.person_outline_rounded,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Введите имя' : null,
          ),
          const SizedBox(height: 10),
          const _AuthLabel('Email'),
          const SizedBox(height: 8),
          _AuthField(
            controller: _regEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || !value.contains('@')
                ? 'Введите корректный email'
                : null,
          ),
          const SizedBox(height: 10),
          const _AuthLabel('Организация'),
          const SizedBox(height: 8),
          _AuthField(
            controller: _regOrg,
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 10),
          const _AuthLabel('Пароль'),
          const SizedBox(height: 8),
          _AuthField(
            controller: _regPass,
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (value) =>
                value == null || value.length < 6 ? 'Минимум 6 символов' : null,
          ),
          const SizedBox(height: 10),
          const _AuthLabel('Повторите пароль'),
          const SizedBox(height: 8),
          _AuthField(
            controller: _regPassRepeat,
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (value) =>
                value != _regPass.text ? 'Пароли не совпадают' : null,
          ),
          const SizedBox(height: 22),
          _PrimaryAuthButton(
            text: 'Создать аккаунт',
            loading: _regLoading,
            onPressed: _tryRegister,
          ),
          const SizedBox(height: 18),
          _SecondaryAuthButton(
            text: 'Назад ко входу',
            onPressed: () => setState(() => _registrationMode = false),
          ),
        ],
      ),
    );
  }

  Future<void> _tryLogin() async {
    if (!_loginKey.currentState!.validate()) return;

    setState(() => _loginLoading = true);
    try {
      final ok = await AuthService.login(
        _loginEmail.text.trim(),
        _loginPass.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, '/security-setup');
      } else {
        _showError(
            AuthService.lastLoginError ?? 'Ошибка входа. Проверьте данные.');
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _tryRegister() async {
    if (!_regKey.currentState!.validate()) return;

    setState(() => _regLoading = true);
    try {
      final ok = await AuthService.register(
        _regEmail.text.trim(),
        _regPass.text.trim(),
        _regName.text.trim(),
        _regOrg.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, '/security-setup');
      } else {
        _showError('Ошибка регистрации.');
      }
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _OySynBrand extends StatelessWidget {
  const _OySynBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: OySynAuthTokens.logoSize,
          height: OySynAuthTokens.logoSize,
          child: Image(
            image: AssetImage(OySynAuthTokens.logoAsset),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'OySynmobile',
          style: OySynTextStyles.authLogo,
        ),
        const SizedBox(height: 8),
        Text(
          'Вход в аккаунт',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: OySynAuthTokens.textDark,
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _AuthLabel extends StatelessWidget {
  final String text;

  const _AuthLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: OySynAuthTokens.textDark,
        fontSize: 14,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: OySynAuthTokens.fieldHeight,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          color: OySynAuthTokens.textMuted,
          fontSize: 16,
          height: 1.1,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: OySynAuthTokens.textMuted,
            fontSize: 16,
            height: 1.1,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(
              icon,
              color: OySynAuthTokens.iconGrey,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56),
          suffixIcon: suffixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: suffixIcon,
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 54),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: OySynAuthTokens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OySynAuthTokens.buttonRadius),
          boxShadow: const [
            BoxShadow(
              color: OySynAuthTokens.shadowBlue,
              blurRadius: 42,
              offset: Offset(0, 25),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: OySynAuthTokens.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                OySynAuthTokens.primaryBlue.withValues(alpha: 0.72),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OySynAuthTokens.buttonRadius),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SecondaryAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SecondaryAuthButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: OySynAuthTokens.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: OySynAuthTokens.primaryBlue,
          side: const BorderSide(
            color: OySynAuthTokens.primaryBlue,
            width: 1.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OySynAuthTokens.buttonRadius),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: Divider(color: OySynAuthTokens.divider, thickness: 1.2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'или',
            style: TextStyle(
              color: OySynAuthTokens.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
            child: Divider(color: OySynAuthTokens.divider, thickness: 1.2)),
      ],
    );
  }
}
