import 'package:flutter/material.dart';
import '../services/scan_service.dart';
import '../models/scan_result.dart';
import 'scan_details_screen.dart';

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = "Введите текст!");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ScanResult result = await ScanService.createScan(text);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanDetailsScreen(
            result: result,
            loadFromBackend: false,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Вставить текст")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "Вставьте текст для проверки...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _send,
                    child: const Text("Проверить текст"),
                  ),
          ],
        ),
      ),
    );
  }
}