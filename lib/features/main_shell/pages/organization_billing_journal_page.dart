import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationBillingJournalPage extends StatelessWidget {
  final int organizationId;
  final String organizationName;

  const OrganizationBillingJournalPage({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OySynAuthTokens.appBackground,
        appBar: AppBar(
          title: const Text('Журнал биллинга'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: ProfileService.getOrganizationBillingJournal(organizationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Не удалось загрузить журнал'));
            }
            final rows = snapshot.data ?? const [];
            final added = rows.fold<int>(0, (sum, row) {
              final delta = _int(row['org_delta_checks']);
              return sum + (delta < 0 ? -delta : 0);
            });
            final returned = rows.fold<int>(0, (sum, row) {
              final delta = _int(row['org_delta_checks']);
              return sum + (delta > 0 ? delta : 0);
            });
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(organizationName,
                    style: const TextStyle(
                        color: OySynAuthTokens.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    final compact = constraints.maxWidth < 390;
                    final width = compact
                        ? (constraints.maxWidth - spacing) / 2
                        : (constraints.maxWidth - spacing * 2) / 3;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _JournalMetric(
                          width: width,
                          label: 'Операций',
                          value: rows.length,
                          color: const Color(0xFF315FE8),
                        ),
                        _JournalMetric(
                          width: width,
                          label: 'Выдано',
                          value: added,
                          color: const Color(0xFFC67F09),
                        ),
                        _JournalMetric(
                          width: compact ? constraints.maxWidth : width,
                          label: 'Возвращено',
                          value: returned,
                          color: const Color(0xFF168A4C),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                if (rows.isEmpty)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Операций пока нет',
                        style: TextStyle(color: OySynAuthTokens.textMuted)),
                  ))
                else
                  for (final row in rows) ...[
                    _JournalRow(row: row),
                    const SizedBox(height: 9),
                  ],
              ],
            );
          },
        ),
      );
}

class _JournalMetric extends StatelessWidget {
  final double width;
  final String label;
  final int value;
  final Color color;
  const _JournalMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Container(
          height: 86,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: OySynAuthTokens.divider),
              borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 23, fontWeight: FontWeight.w900)),
            Text(label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: OySynAuthTokens.textMuted,
                    fontSize: 11,
                    height: 1.1)),
          ]),
        ),
      );
}

class _JournalRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _JournalRow({required this.row});
  @override
  Widget build(BuildContext context) {
    final delta = _int(row['org_delta_checks']);
    final target = row['target_user'] as Map<String, dynamic>?;
    final actor = row['actor_user'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: OySynAuthTokens.divider),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(
                  row['transaction_type_display']?.toString() ??
                      row['description']?.toString() ??
                      'Операция',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(delta > 0 ? '+$delta' : '$delta',
              style: TextStyle(
                  color: delta > 0
                      ? const Color(0xFF168A4C)
                      : const Color(0xFFD23B41),
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 7),
        Text('Получатель: ${_name(target)}',
            style: const TextStyle(
                color: OySynAuthTokens.textMuted, fontSize: 12.5)),
        Text('Автор: ${_name(actor)} · ${_date(row['time'])}',
            style: const TextStyle(
                color: OySynAuthTokens.textMuted, fontSize: 12.5)),
      ]),
    );
  }
}

String _name(Map<String, dynamic>? user) =>
    user?['full_name']?.toString().trim().isNotEmpty == true
        ? user!['full_name'].toString()
        : user?['email']?.toString() ?? 'Система';
String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
