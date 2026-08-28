import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final orgCtrl = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Регистрация",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: "Имя")),
            TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: "Email")),
            TextField(
                controller: orgCtrl,
                decoration: InputDecoration(labelText: "Организация")),
            TextField(
                controller: passCtrl,
                decoration: InputDecoration(labelText: "Пароль"),
                obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);

                final ok = await AuthService.register(
                  emailCtrl.text,
                  passCtrl.text,
                  nameCtrl.text,
                  orgCtrl.text,
                );

                if (!mounted) return;
                setState(() => loading = false);

                if (ok && context.mounted) Navigator.pop(context);
              },
              child: loading
                  ? CircularProgressIndicator()
                  : Text("Создать аккаунт"),
            )
          ],
        ),
      ),
    );
  }
}
