import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  // LOGIN
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginKey = GlobalKey<FormState>();
  bool _loginLoading = false;

  // REGISTER
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regOrg = TextEditingController();
  final _regPass = TextEditingController();
  final _regPassRepeat = TextEditingController();
  final _regKey = GlobalKey<FormState>();
  bool _regLoading = false;
  bool _regAgree = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            // BACKGROUND
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff3b82f6), Color(0xff06b6d4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // LOGO + TITLE
                      Icon(Icons.document_scanner_rounded,
                          size: 90, color: Colors.white),
                      const SizedBox(height: 14),
                      Text(
                        "ScanAI",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "AI-анализ текста • OCR",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // MAIN CARD
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Column(
                          children: [
                            // NEW TABS STYLE (без овала!)
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                tabs: const [
                                  Tab(text: "Вход"),
                                  Tab(text: "Регистрация"),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            SizedBox(
                              height: 520,
                              child: TabBarView(
                                children: [
                                  _buildLogin(context),
                                  _buildRegister(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

      // =============== LOGIN TAB ===================
      Widget _buildLogin(BuildContext context) {
        return Form(
          key: _loginKey,
          child: Column(
            children: [
              _glassField(
                controller: _loginEmail,
                label: "Email",
                icon: Icons.email_outlined,
                validator: (v) => v!.isEmpty ? "Введите email" : null,
              ),
              const SizedBox(height: 16),
              _glassField(
                controller: _loginPass,
                label: "Пароль",
                icon: Icons.lock_outline,
                obscure: true,
                validator: (v) => v!.isEmpty ? "Введите пароль" : null,
              ),
              const SizedBox(height: 28),

              // Кнопка сразу под полем пароля
              _glassButton(
                text: "Войти",
                loading: _loginLoading,
                onTap: _tryLogin,
              ),
            ],
          ),
        );
      }

  // =============== REGISTER TAB ===================
  Widget _buildRegister(BuildContext context) {
    return Form(
      key: _regKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _glassField(
                    controller: _regName,
                    label: "Имя",
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? "Введите имя" : null,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _regEmail,
                    label: "Email",
                    icon: Icons.email_outlined,
                    validator: (v) =>
                        !v!.contains("@") ? "Введите корректный email" : null,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _regOrg,
                    label: "Организация (необязательно)",
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _regPass,
                    label: "Пароль",
                    obscure: true,
                    icon: Icons.lock_outline,
                    validator: (v) =>
                        v!.length < 6 ? "Минимум 6 символов" : null,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: _regPassRepeat,
                    label: "Повторите пароль",
                    obscure: true,
                    icon: Icons.lock_outline,
                    validator: (v) =>
                        v != _regPass.text ? "Пароли не совпадают" : null,
                  ),
                  const SizedBox(height: 16),

                  // CUSTOM CHECKBOX
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _regAgree,
                          onChanged: (v) => setState(() => _regAgree = v!),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.8),
                            width: 1.4,
                          ),
                          checkColor: Colors.white,
                          activeColor: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "Соглашаюсь с условиями и политикой",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _glassButton(
            text: "Зарегистрироваться",
            loading: _regLoading,
            onTap: _tryRegister,
          ),
        ],
      ),
    );
  }

  // =============================================================
  //                    BEAUTIFUL GLASS FIELD
  // =============================================================
  Widget _glassField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white70)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  // =============================================================
  //                    BEAUTIFUL GLASS BUTTON
  // =============================================================
  Widget _glassButton({
    required String text,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }

  // =============================================================
  //                      AUTH LOGIC
  // =============================================================

  Future<void> _tryLogin() async {
    if (!_loginKey.currentState!.validate()) return;

    setState(() => _loginLoading = true);

    try {
      final ok = await AuthService.login(
        _loginEmail.text.trim(),
        _loginPass.text.trim(),
      );

      if (!mounted) return;
      if (ok) Navigator.pushReplacementNamed(context, "/home");
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _tryRegister() async {
    if (!_regKey.currentState!.validate()) return;
    if (!_regAgree) return;

    setState(() => _regLoading = true);

    try {
      final ok = await AuthService.register(
        _regEmail.text.trim(),
        _regPass.text.trim(),
        _regName.text.trim(),
        _regOrg.text.trim(),
      );

      if (!mounted) return;
      if (ok) Navigator.pushReplacementNamed(context, "/home");
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }
}