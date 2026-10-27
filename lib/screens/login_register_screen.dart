import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/oysyn_logo.dart';

const _agreementUrl = 'https://oysyn.asia/ru/policy/';
const _passwordResetUrl = 'https://oysyn.asia/ru/accounts/password/reset/';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginKey = GlobalKey<FormState>();

  bool _loginLoading = false;
  bool _passVisible = false;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.surface,
      body: _AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;

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
                            SizedBox(height: compact ? 22 : 44),
                            _OySynBrand(compact: compact),
                            SizedBox(height: compact ? 24 : 34),
                            _buildLoginForm(),
                            SizedBox(height: compact ? 26 : 52),
                            const Text(
                              'OySyn · antiplagiat',
                              style: TextStyle(
                                color: OySynAuthTokens.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
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
          _AuthField(
            controller: _loginEmail,
            icon: Icons.mail_outline_rounded,
            hintText: 'Email или логин',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Введите email или логин'
                : null,
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _loginPass,
            icon: Icons.lock_outline_rounded,
            hintText: 'Пароль',
            obscureText: !_passVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _tryLogin(),
            suffixIcon: IconButton(
              tooltip: _passVisible ? 'Скрыть пароль' : 'Показать пароль',
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
              onPressed: () => _openWebPage(_passwordResetUrl),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: OySynAuthTokens.linkBlue,
              ),
              child: const Text(
                'Забыли пароль?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryAuthButton(
            text: 'Войти',
            loading: _loginLoading,
            onPressed: _tryLogin,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: OySynAuthTokens.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: _openRegistration,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('Зарегистрироваться'),
              style: OutlinedButton.styleFrom(
                foregroundColor: OySynAuthTokens.primaryBlue,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: OySynAuthTokens.primaryBlue,
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegistration() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _RegistrationScreen()),
    );
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _loginEmail.text = email;
      _loginPass.clear();
    });
  }

  Future<void> _tryLogin() async {
    if (_loginLoading || !_loginKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
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
          AuthService.lastLoginError ?? 'Ошибка входа. Проверьте данные.',
        );
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _openWebPage(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) {
      _showError('Не удалось открыть страницу. Попробуйте ещё раз.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RegistrationScreen extends StatefulWidget {
  const _RegistrationScreen();

  @override
  State<_RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<_RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  bool _acceptedAgreement = false;
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmationVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OySynAuthTokens.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Регистрация',
          style: TextStyle(
            color: OySynAuthTokens.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _AuthBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              OySynAuthTokens.screenHorizontalPadding,
              16,
              OySynAuthTokens.screenHorizontalPadding,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: OySynAuthTokens.contentMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: OySynLogo(size: 58)),
                        const SizedBox(height: 18),
                        const Text(
                          'Создайте аккаунт',
                          style: OySynTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Укажите email и придумайте пароль. После регистрации подтвердите адрес по ссылке из письма.',
                          style: TextStyle(
                            color: OySynAuthTokens.textMuted,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AuthField(
                          controller: _email,
                          icon: Icons.mail_outline_rounded,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        _AuthField(
                          controller: _password,
                          icon: Icons.lock_outline_rounded,
                          hintText: 'Пароль',
                          obscureText: !_passwordVisible,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          suffixIcon: _PasswordVisibilityButton(
                            visible: _passwordVisible,
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Не менее 8 символов',
                            style: OySynTextStyles.caption,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AuthField(
                          controller: _passwordConfirmation,
                          icon: Icons.lock_reset_rounded,
                          hintText: 'Повторите пароль',
                          obscureText: !_confirmationVisible,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: _PasswordVisibilityButton(
                            visible: _confirmationVisible,
                            onPressed: () => setState(
                              () =>
                                  _confirmationVisible = !_confirmationVisible,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Повторите пароль';
                            }
                            if (value != _password.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _AgreementControl(
                          value: _acceptedAgreement,
                          onChanged: _loading
                              ? null
                              : (value) => setState(
                                    () => _acceptedAgreement = value,
                                  ),
                          onOpenAgreement: _openAgreement,
                        ),
                        const SizedBox(height: 22),
                        _PrimaryAuthButton(
                          text: 'Зарегистрироваться',
                          loading: _loading,
                          onPressed: _acceptedAgreement ? _submit : null,
                        ),
                        const SizedBox(height: 12),
                        _ExistingAccountLink(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Введите email';
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(email) ? null : 'Введите корректный email';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Введите пароль';
    if (value.length < 8) return 'Пароль должен содержать не менее 8 символов';
    return null;
  }

  Future<void> _openAgreement() async {
    final opened = await launchUrl(
      Uri.parse(_agreementUrl),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) {
      _showSnackBar('Не удалось открыть соглашение. Попробуйте ещё раз.');
    }
  }

  Future<void> _submit() async {
    if (_loading || !_acceptedAgreement) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final email = _email.text.trim().toLowerCase();

    try {
      final result = await AuthService.register(
        email,
        _password.text,
        _passwordConfirmation.text,
      );
      if (!mounted) return;

      switch (result.code) {
        case RegistrationCode.created:
          await _showInfoDialog(
            icon: Icons.mark_email_read_outlined,
            title: 'Подтвердите email',
            message:
                'Аккаунт успешно создан. Мы отправили письмо для подтверждения на указанный адрес электронной почты. Перейдите по ссылке в письме, после чего вы сможете войти в приложение.',
          );
          if (mounted) Navigator.of(context).pop(email);
        case RegistrationCode.emailNotVerified:
          await _showInfoDialog(
            icon: Icons.mark_email_unread_outlined,
            title: 'Email не подтверждён',
            message:
                'Аккаунт с такой электронной почтой уже создан, но адрес ещё не подтверждён. Проверьте письмо, отправленное на указанную электронную почту, и подтвердите регистрацию.',
          );
          if (mounted) Navigator.of(context).pop(email);
        case RegistrationCode.accountAlreadyExists:
          await _showExistingAccountDialog(email);
        case RegistrationCode.error:
          await _showInfoDialog(
            icon: Icons.error_outline_rounded,
            title: 'Не удалось зарегистрироваться',
            message: result.message,
            accent: const Color(0xFFD9485F),
          );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showExistingAccountDialog(String email) async {
    final action = await showDialog<_ExistingAccountAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DialogIcon(
              icon: Icons.person_outline_rounded,
              color: OySynAuthTokens.primaryBlue,
            ),
            const SizedBox(height: 14),
            const Text(
              'Аккаунт уже существует',
              textAlign: TextAlign.center,
              style: OySynTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Аккаунт с таким адресом электронной почты уже существует. Войдите в приложение или восстановите пароль.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OySynAuthTokens.textMuted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext)
                    .pop(_ExistingAccountAction.login),
                child: const Text('Войти'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(dialogContext)
                    .pop(_ExistingAccountAction.resetPassword),
                child: const Text('Восстановить пароль'),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == _ExistingAccountAction.login) {
      Navigator.of(context).pop(email);
    } else if (action == _ExistingAccountAction.resetPassword) {
      final opened = await launchUrl(
        Uri.parse(_passwordResetUrl),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!opened && mounted) {
        _showSnackBar('Не удалось открыть восстановление пароля.');
      }
    }
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required String title,
    required String message,
    Color accent = OySynAuthTokens.primaryBlue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogIcon(icon: icon, color: accent),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: OySynTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OySynAuthTokens.textMuted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ExistingAccountAction { login, resetPassword }

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: child,
    );
  }
}

class _OySynBrand extends StatelessWidget {
  const _OySynBrand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OySynLogo(size: compact ? 64 : OySynAuthTokens.logoSize),
        const SizedBox(height: 10),
        const Text('OySyn', style: OySynTextStyles.authLogo),
        const SizedBox(height: 6),
        Text(
          'Вход в аккаунт',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: OySynAuthTokens.textDark,
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: OySynAuthTokens.fieldHeight),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !obscureText,
        style: const TextStyle(
          color: OySynAuthTokens.textDark,
          fontSize: 16,
          height: 1.1,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: OySynAuthTokens.textMuted,
            fontSize: 16,
            height: 1.1,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(icon, color: OySynAuthTokens.iconGrey, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56),
          suffixIcon: suffixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 48),
        ),
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? 'Скрыть пароль' : 'Показать пароль',
      onPressed: onPressed,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: OySynAuthTokens.iconGrey,
        size: 23,
      ),
    );
  }
}

class _AgreementControl extends StatelessWidget {
  const _AgreementControl({
    required this.value,
    required this.onChanged,
    required this.onOpenAgreement,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback onOpenAgreement;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final borderColor = value
        ? OySynAuthTokens.primaryBlue.withValues(alpha: .42)
        : OySynAuthTokens.fieldBorder;
    final backgroundColor = value
        ? OySynAuthTokens.primaryBlue.withValues(alpha: .045)
        : Colors.white;

    return Semantics(
      checked: value,
      enabled: enabled,
      label: 'Принять Пользовательское соглашение',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? () => onChanged!(!value) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: value ? OySynAuthTokens.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: value
                            ? OySynAuthTokens.primaryBlue
                            : const Color(0xFFB8C2D3),
                        width: 1.5,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: value
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('checked'),
                              size: 16,
                              color: Colors.white,
                            )
                          : const SizedBox(
                              key: ValueKey('unchecked'),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Согласие с условиями',
                          style: TextStyle(
                            color: OySynAuthTokens.textDark,
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          children: [
                            const Text(
                              'Принимаю ',
                              style: TextStyle(
                                color: OySynAuthTokens.textMuted,
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: onOpenAgreement,
                              child: const Text(
                                'Пользовательского соглашения',
                                style: TextStyle(
                                  color: OySynAuthTokens.linkBlue,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Text(
                              ' и обработку персональных данных.',
                              style: TextStyle(
                                color: OySynAuthTokens.textMuted,
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExistingAccountLink extends StatelessWidget {
  const _ExistingAccountLink({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          foregroundColor: OySynAuthTokens.textDark,
          backgroundColor: Colors.white.withValues(alpha: .82),
          side: const BorderSide(color: OySynAuthTokens.fieldBorder),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.login_rounded,
              size: 20,
              color: OySynAuthTokens.primaryBlue,
            ),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Войти в существующий аккаунт',
                style: TextStyle(
                  color: OySynAuthTokens.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 19,
              color: OySynAuthTokens.iconGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: OySynAuthTokens.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OySynAuthTokens.buttonRadius),
          boxShadow: onPressed == null
              ? null
              : const [
                  BoxShadow(
                    color: OySynAuthTokens.shadowBlue,
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: OySynAuthTokens.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD5DDED),
            disabledForegroundColor: const Color(0xFF7A869E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(OySynAuthTokens.buttonRadius),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 26,
                  height: 26,
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
                  ),
                ),
        ),
      ),
    );
  }
}
