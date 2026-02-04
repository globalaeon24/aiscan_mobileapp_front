import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class HistoryCard extends StatelessWidget {
  final ScanResult result;
  final void Function()? onDelete;

  const HistoryCard({
    super.key,
    required this.result,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aiColor =
        result.aiPercentage >= 50 ? Colors.red : Colors.green;

    final date = result.createdAt;
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    final titleIndex = result.userScanIndex ?? result.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        title: Text(
          "Проверка №$titleIndex",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Text("$dateStr · $timeStr"),

        trailing: Text(
          "${result.aiPercentage.toStringAsFixed(1)}%",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: aiColor,
          ),
        ),
      ),
    );
  }
}