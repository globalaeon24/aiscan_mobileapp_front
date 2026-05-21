import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../screens/scan_screen.dart';
import '../../../theme/app_theme.dart';

class CheckPage extends StatelessWidget {
  const CheckPage({super.key});

  Future<void> _openScanner(BuildContext context) async {
    await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Text(
          'Проверить',
          style: OySynTextStyles.sectionTitle,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.add_rounded,
                color: OySynAuthTokens.primaryBlue,
                size: 36,
              ),
              const SizedBox(height: 14),
              const Text(
                'Загрузить новый документ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Демо-раздел для будущей проверки документов через БД и OCR.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => _openScanner(context),
                  child: const Text(
                    'Начать проверку',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
