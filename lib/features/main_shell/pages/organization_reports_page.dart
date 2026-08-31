import 'package:flutter/material.dart';

import '../../../models/scan_result.dart';
import '../../../screens/scan_details_screen.dart';
import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationReportsPage extends StatelessWidget {
  final int organizationId;
  final String organizationName;

  const OrganizationReportsPage({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OySynAuthTokens.appBackground,
        appBar: AppBar(
          title: const Text('Отчёты'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ProfileService.getOrganizationReports(organizationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Не удалось загрузить отчёты'));
            }
            final data = snapshot.data ?? const {};
            final raw = data['results'] as List<dynamic>? ?? const [];
            final items = raw
                .whereType<Map<String, dynamic>>()
                .map(ScanResult.fromJson)
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(organizationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: OySynAuthTokens.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  _Metric(
                      'Всего', _int(data['total']), const Color(0xFF315FE8)),
                  const SizedBox(width: 8),
                  _Metric(
                      'Готово', _int(data['checked']), const Color(0xFF168A4C)),
                  const SizedBox(width: 8),
                  _Metric('В работе', _int(data['processing']),
                      const Color(0xFFC67F09)),
                ]),
                const SizedBox(height: 18),
                const Text('Последние проверки',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const _EmptyState()
                else
                  for (final item in items) ...[
                    _ReportRow(
                      item: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScanDetailsScreen(
                            result: item,
                            loadFromBackend: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
              ],
            );
          },
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Metric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 86,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: OySynAuthTokens.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 1,
                style: const TextStyle(
                    color: OySynAuthTokens.textMuted, fontSize: 11.5)),
          ]),
        ),
      );
}

class _ReportRow extends StatelessWidget {
  final ScanResult item;
  final VoidCallback onTap;
  const _ReportRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: OySynAuthTokens.divider),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.description_outlined,
                  color: OySynAuthTokens.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title ?? item.fileName ?? 'Документ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                          item.statusDisplay ??
                              item.status ??
                              'Статус не указан',
                          style: const TextStyle(
                              color: OySynAuthTokens.textMuted, fontSize: 12)),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: OySynAuthTokens.textMuted),
            ]),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text('Отчётов пока нет',
                style: TextStyle(color: OySynAuthTokens.textMuted))),
      );
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
