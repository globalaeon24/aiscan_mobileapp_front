import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';

class ScanDetailsScreen extends StatefulWidget {
  final ScanResult result;
  final bool loadFromBackend;

  const ScanDetailsScreen({
    super.key,
    required this.result,
    this.loadFromBackend = false,
  });

  @override
  State<ScanDetailsScreen> createState() => _ScanDetailsScreenState();
}

class _ScanDetailsScreenState extends State<ScanDetailsScreen> {
  ScanResult? _fullResult;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.loadFromBackend || widget.result.scannedText.isEmpty) {
      _loadDetail();
    } else {
      _fullResult = widget.result;
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ScanService.getScanById(widget.result.id);
      setState(() {
        _fullResult = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _fullResult ?? widget.result;

    // ✅ СТРОГО double
    final double aiPercent = data.aiPercentage.toDouble().clamp(0.0, 100.0);
    final double humanPercent = (100.0 - aiPercent).clamp(0.0, 100.0);
    final double progress = (aiPercent / 100.0).clamp(0.0, 1.0);

    final date = data.createdAt;
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    final scanIndex = data.userScanIndex ?? data.id;

    return Scaffold(
      appBar: AppBar(title: const Text("Результат проверки")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================== ЗАГОЛОВОК ===================
            Text(
              "Проверка №$scanIndex",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "$dateStr · $timeStr",
              style: Theme.of(context).textTheme.bodySmall,
            ),

            if (data.fileName != null) Text("Файл: ${data.fileName}"),
            if (data.authorName != null) Text("Автор: ${data.authorName}"),

            const SizedBox(height: 20),

            // =================== ИНДИКАТОР + ПОЯСНЕНИЯ ===================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 52,
                  lineWidth: 10,
                  percent: progress,
                  animation: true,
                  center: Text(
                    "${aiPercent.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: aiPercent >= 50.0 ? Colors.red : Colors.green,
                  backgroundColor: Colors.grey.shade300,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PercentRow(
                        label: "Вероятно ИИ",
                        value: aiPercent,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 6),
                      _PercentRow(
                        label: "Вероятно человек",
                        value: humanPercent,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        aiPercent >= 50.0
                            ? "Текст по стилю и структуре ближе к генерации ИИ."
                            : "Текст по стилю и структуре ближе к человеческому написанию.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =================== ТЕКСТ ===================
            Text(
              "Распознанный текст:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),

            Expanded(child: _buildHighlightedText(context, data)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, ScanResult data) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          "Ошибка загрузки:\n$_error",
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (data.scannedText.isEmpty) {
      return const Center(child: Text("Текст проверки отсутствует."));
    }

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final f in data.aiFragments) {
      if (f.start > cursor) {
        spans.add(TextSpan(
          text: data.scannedText.substring(cursor, f.start),
        ));
      }

      spans.add(
        TextSpan(
          text: data.scannedText.substring(f.start, f.end),
          style: TextStyle(
            backgroundColor: Colors.red.withOpacity(0.25),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      cursor = f.end;
    }

    if (cursor < data.scannedText.length) {
      spans.add(TextSpan(
        text: data.scannedText.substring(cursor),
      ));
    }

    return SingleChildScrollView(
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: spans,
        ),
      ),
    );
  }
}

class _PercentRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PercentRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          "${value.toStringAsFixed(1)}%",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}