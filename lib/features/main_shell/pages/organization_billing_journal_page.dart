import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class OrganizationBillingJournalPage extends StatelessWidget {
  final int organizationId;

  const OrganizationBillingJournalPage({
    super.key,
    required this.organizationId,
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
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
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
                  _JournalTable(rows: rows),
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
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$value',
                    style: TextStyle(
                        color: color,
                        fontSize: 23,
                        fontWeight: FontWeight.w900)),
              ),
            ),
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

class _JournalTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _JournalTable({required this.rows});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border.symmetric(
            horizontal: BorderSide(color: OySynAuthTokens.divider),
          ),
        ),
        child: Column(
          children: [
            const _JournalTableHeader(),
            const Divider(height: 1),
            for (var index = 0; index < rows.length; index++) ...[
              _JournalTableRow(row: rows[index]),
              if (index != rows.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      );
}

class _JournalTableHeader extends StatelessWidget {
  const _JournalTableHeader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            SizedBox(width: 68, child: Text('Дата', style: _headerStyle)),
            SizedBox(width: 10),
            Expanded(child: Text('Операция', style: _headerStyle)),
            SizedBox(width: 12),
            SizedBox(
              width: 76,
              child: Text(
                'Проверки',
                textAlign: TextAlign.right,
                style: _headerStyle,
              ),
            ),
          ],
        ),
      );

  static const _headerStyle = TextStyle(
    color: OySynAuthTokens.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
}

class _JournalTableRow extends StatelessWidget {
  final Map<String, dynamic> row;

  const _JournalTableRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final delta = _int(row['org_delta_checks']);
    final target = row['target_user'] as Map<String, dynamic>?;
    final actor = row['actor_user'] as Map<String, dynamic>?;
    final date = _dateParts(row['time']);
    final title = row['transaction_type_display']?.toString() ??
        row['description']?.toString() ??
        'Операция';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.$1,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700)),
                Text(date.$2,
                    style: const TextStyle(
                        color: OySynAuthTokens.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  _name(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: OySynAuthTokens.textMuted, fontSize: 11),
                ),
                Text(
                  'Автор: ${_name(actor)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: OySynAuthTokens.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topRight,
              child: Text(
                delta > 0 ? '+$delta' : '$delta',
                style: TextStyle(
                  color: delta > 0
                      ? const Color(0xFF168A4C)
                      : const Color(0xFFD23B41),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _name(Map<String, dynamic>? user) =>
    user?['full_name']?.toString().trim().isNotEmpty == true
        ? user!['full_name'].toString()
        : user?['email']?.toString() ?? 'Система';
(String, String) _dateParts(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return ('—', '');
  return (
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
  );
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
