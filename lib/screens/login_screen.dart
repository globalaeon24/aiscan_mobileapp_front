import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // поля Login
  final loginEmailCtrl = TextEditingController();
  final loginPassCtrl = TextEditingController();

  // поля Register
  final regEmailCtrl = TextEditingController();
  final regPassCtrl = TextEditingController();
  final regPass2Ctrl = TextEditingController();
  final regNameCtrl = TextEditingController();
  final regOrgCtrl = TextEditingController();

  bool loading = false;
  bool agree = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _login() async {
    setState(() => loading = true);
    final ok = await AuthService.login(
      loginEmailCtrl.text.trim(),
      loginPassCtrl.text.trim(),
    );
    setState(() => loading = false);

    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, "/security-setup");
    } else {
      _showError(
          AuthService.lastLoginError ?? "Ошибка входа. Проверьте данные.");
    }
  }

  Future<void> _register() async {
    if (regPassCtrl.text != regPass2Ctrl.text) {
      _showError("Пароли не совпадают");
      return;
    }

    if (!agree) {
      _showError("Необходимо согласиться с политикой конфиденциальности");
      return;
    }

    setState(() => loading = true);

    final ok = await AuthService.register(
      regEmailCtrl.text.trim(),
      regPassCtrl.text.trim(),
      regNameCtrl.text.trim(),
      regOrgCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, "/security-setup");
    } else {
      _showError("Ошибка регистрации.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ScanAI"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Вход"),
            Tab(text: "Регистрация"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogin(),
          _buildRegister(),
        ],
      ),
    );
  }

  // ---------- LOGIN ----------
  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          TextField(
            controller: loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: loginPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Пароль"),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: loading ? null : _login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Войти"),
          ),
        ],
      ),
    );
  }

  // ---------- REGISTER ----------
  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          TextField(
            controller: regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: regNameCtrl,
            decoration: const InputDecoration(labelText: "Имя"),
          ),
          TextField(
            controller: regOrgCtrl,
            decoration: const InputDecoration(labelText: "Организация"),
          ),
          TextField(
            controller: regPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Пароль"),
          ),
          TextField(
            controller: regPass2Ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Повторите пароль"),
          ),
          const SizedBox(height: 12),

          // Согласие
          Row(
            children: [
              Checkbox(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
              ),
              const Expanded(
                child: Text("Я согласен с политикой конфиденциальности"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: loading ? null : _register,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Создать аккаунт"),
          ),
        ],
      ),
    );
  }
}
