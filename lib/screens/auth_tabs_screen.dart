import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthTabsScreen extends StatefulWidget {
  const AuthTabsScreen({super.key});

  @override
  State<AuthTabsScreen> createState() => _AuthTabsScreenState();
}

class _AuthTabsScreenState extends State<AuthTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final emailLoginCtrl = TextEditingController();
  final passLoginCtrl = TextEditingController();

  final emailRegCtrl = TextEditingController();
  final passRegCtrl = TextEditingController();
  final passReg2Ctrl = TextEditingController();
  bool agreePrivacy = false;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(vsync: this, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("ScanAI",
                  style: theme.textTheme.headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // ---------- ВКЛАДКИ ----------
              TabBar(
                controller: _tabCtrl,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Вход"),
                  Tab(text: "Регистрация"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // ---------- LOGIN ----------
                    _buildLoginTab(context),

                    // ---------- REGISTER ----------
                    _buildRegisterTab(context),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  //                          LOGIN
  // ===============================================================
  Widget _buildLoginTab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: emailLoginCtrl,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passLoginCtrl,
          decoration: const InputDecoration(labelText: "Пароль"),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : () async {
            setState(() => loading = true);
            final ok = await AuthService.login(
              emailLoginCtrl.text,
              passLoginCtrl.text,
            );
            setState(() => loading = false);

            if (ok && mounted) {
              Navigator.pushReplacementNamed(context, "/home");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ошибка входа")),
              );
            }
          },
          child: loading
              ? const CircularProgressIndicator()
              : const Text("Войти"),
        ),
      ],
    );
  }

  // ===============================================================
  //                       REGISTRATION
  // ===============================================================
  Widget _buildRegisterTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          TextField(
            controller: emailRegCtrl,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passRegCtrl,
            decoration: const InputDecoration(labelText: "Пароль"),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passReg2Ctrl,
            decoration: const InputDecoration(labelText: "Повторите пароль"),
            obscureText: true,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: agreePrivacy,
                onChanged: (v) {
                  setState(() => agreePrivacy = v!);
                },
              ),
              Expanded(
                child: Text(
                  "Я соглашаюсь с политикой конфиденциальности",
                  style: theme.textTheme.bodyMedium,
                ),
              )
            ],
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: loading
                ? null
                : () async {
                    if (passRegCtrl.text != passReg2Ctrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Пароли не совпадают")),
                      );
                      return;
                    }
                    if (!agreePrivacy) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Нужно согласиться")),
                      );
                      return;
                    }

                    setState(() => loading = true);
                    final ok = await AuthService.register(
                      emailRegCtrl.text,
                      passRegCtrl.text,
                      "Пользователь",
                      "",
                    );
                    setState(() => loading = false);

                    if (ok && mounted) {
                      Navigator.pushReplacementNamed(context, "/home");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ошибка регистрации")),
                      );
                    }
                  },
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Создать аккаунт"),
          ),
        ],
      ),
    );
  }
}