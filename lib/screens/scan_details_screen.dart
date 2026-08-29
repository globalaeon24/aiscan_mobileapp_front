import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:printing/printing.dart';

import '../models/check_report.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../theme/app_theme.dart';

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
  ScanResult? _detail;
  CheckReport? _report;
  bool _loading = true;
  bool _sharing = false;
  String? _reportMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    ScanResult detail = widget.result;
    CheckReport? report;
    String? reportMessage;

    try {
      if (widget.loadFromBackend || widget.result.status != 'CH') {
        detail = await ScanService.getScanById(widget.result.id);
      }
    } catch (error) {
      reportMessage = 'Не удалось обновить данные проверки: $error';
    }

    try {
      report = await ScanService.getReport(widget.result.id);
    } catch (_) {
      reportMessage ??= 'Отчёт формируется. Обновите страницу немного позже.';
    }

    if (!mounted) return;
    setState(() {
      _detail = detail;
      _report = report;
      _reportMessage = reportMessage;
      _loading = false;
    });
  }

  Future<void> _sharePdf(String type, String fileName) async {
    setState(() => _sharing = true);
    try {
      final bytes = await ScanService.getReportPdf(
        widget.result.id,
        reportType: type,
      );
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось получить отчёт: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.result;
    final report = _report;
    final date = detail.createdAt;
    final subtitle = [
      detail.documentType,
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
    ].whereType<String>().join(' · ');

    return Scaffold(
      backgroundColor: OySynAuthTokens.appBackground,
      appBar: AppBar(
        toolbarHeight: 62,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 7, bottom: 7),
          child: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: OySynAuthTokens.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
        titleSpacing: 11,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Отчёт',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              '${detail.title ?? detail.fileName ?? 'Документ'} · $subtitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A94A6),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: !_loading,
            onSelected: (value) {
              if (value == 'refresh') _load();
            },
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Обновить отчёт')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            _MetricsCard(detail: detail, report: report),
            if (_reportMessage != null) ...[
              const SizedBox(height: 12),
              _InfoBanner(message: _reportMessage!),
            ],
            if (report != null && report.fraud.isNotEmpty) ...[
              const SizedBox(height: 13),
              _FraudBanner(items: report.fraud),
            ],
            const SizedBox(height: 13),
            _ReportTabs(
                sourceCount:
                    report?.sources.where((item) => item.active).length ?? 0),
            const SizedBox(height: 13),
            if (report != null && report.sources.isNotEmpty)
              for (final source
                  in report.sources.where((item) => item.active)) ...[
                _ReportSourceCard(source: source),
                const SizedBox(height: 10),
              ]
            else if (!_loading)
              const _InfoBanner(message: 'Источники совпадений не обнаружены.'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: OySynAuthTokens.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sharing
                      ? null
                      : () => _sharePdf(
                            'certificate',
                            'oysyn-certificate-${detail.id}.pdf',
                          ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Скачать справку'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _sharing
                    ? null
                    : () => _sharePdf(
                          'full_report',
                          'oysyn-report-${detail.id}.pdf',
                        ),
                tooltip: 'Полный отчёт',
                icon: const Icon(Icons.description_outlined),
                style: IconButton.styleFrom(
                  minimumSize: const Size(52, 52),
                  foregroundColor: OySynAuthTokens.primaryBlue,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD9FB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final ScanResult detail;
  final CheckReport? report;

  const _MetricsCard({required this.detail, required this.report});

  @override
  Widget build(BuildContext context) {
    final originality = report?.originality ?? detail.originalityPercentage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _reportCardDecoration(),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 59,
            lineWidth: 11,
            percent: (originality / 100).clamp(0, 1),
            progressColor: const Color(0xFF22A45D),
            backgroundColor: const Color(0xFFEEF1F6),
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${originality.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF148A4E),
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'оригинальность',
                  style: TextStyle(color: Color(0xFF8A94A6), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _MetricRow(
                    label: 'Оригинальность',
                    value: originality,
                    color: const Color(0xFF148A4E)),
                _MetricRow(
                    label: 'Совпадения',
                    value: report?.plagiarism,
                    color: const Color(0xFFD23B41)),
                _MetricRow(label: 'Цитирования', value: report?.citation),
                _MetricRow(
                    label: 'Самоцитирования', value: report?.selfCitation),
                const Divider(height: 15),
                _MetricRow(
                    label: 'ИИ-контент',
                    value: report?.aiGenerated,
                    color: const Color(0xFF6D4EF0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _MetricRow(
      {required this.label,
      required this.value,
      this.color = const Color(0xFF6A7590)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF46506A), fontSize: 12.5))),
          Text(value == null ? '—' : '${value!.toStringAsFixed(2)}%',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF1DE),
        border: Border.all(color: const Color(0xFFF6E3C0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFC67F09), size: 19),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFF8A6414), fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _ReportTabs extends StatelessWidget {
  final int sourceCount;

  const _ReportTabs({required this.sourceCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReportTab(label: 'Источники · $sourceCount', selected: true),
        const SizedBox(width: 8),
        const _ReportTab(label: 'Текст'),
        const SizedBox(width: 8),
        const _ReportTab(label: 'ИИ-текст'),
      ],
    );
  }
}

class _ReportTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _ReportTab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? OySynAuthTokens.primaryBlue : Colors.white,
        border: Border.all(
            color: selected
                ? OySynAuthTokens.primaryBlue
                : OySynAuthTokens.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5A6577),
              fontSize: 12.5,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _FraudBanner extends StatelessWidget {
  final List<ReportFraud> items;

  const _FraudBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF1DE),
        border: Border.all(color: const Color(0xFFF1D69D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFC67F09), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Подозрительная активность: ${items.map((item) => item.label.toLowerCase()).join(', ')}',
              style: const TextStyle(color: Color(0xFF8A6414), fontSize: 12.5),
            ),
          ),
          Text('${items.fold<int>(0, (sum, item) => sum + item.count)}',
              style: const TextStyle(
                  color: Color(0xFFC67F09),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReportSourceCard extends StatelessWidget {
  final ReportSource source;

  const _ReportSourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final host = source.url == null ? null : Uri.tryParse(source.url!)?.host;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _reportCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SourceBadge(
                  text: '${source.moduleLabel} · #${source.id}',
                  color: const Color(0xFF5A6577),
                  background: const Color(0xFFEEF1F7)),
              const _SourceBadge(
                  text: 'Совпадение',
                  color: Color(0xFFD23B41),
                  background: Color(0xFFFCEAEA)),
            ],
          ),
          const SizedBox(height: 10),
          Text(source.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: host == null
                      ? const Color(0xFF12203E)
                      : const Color(0xFF2B5CE0),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (host != null && host.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(host,
                style:
                    const TextStyle(color: Color(0xFF8A94A6), fontSize: 11.5)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _SourceMetric(
                  value: source.scoreReport,
                  label: 'доля',
                  color: const Color(0xFFD23B41)),
              const SizedBox(width: 18),
              _SourceMetric(
                  value: source.scoreSource,
                  label: 'поиск',
                  color: const Color(0xFF12203E)),
              const Spacer(),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Исключение источников доступно в полном веб-отчёте.'))),
                style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F5FA),
                    foregroundColor: const Color(0xFF5A6577)),
                child: const Text('Исключить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _SourceBadge(
      {required this.text, required this.color, required this.background});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _SourceMetric extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _SourceMetric(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '${value.toStringAsFixed(2)}% ',
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w800)),
            TextSpan(
                text: label,
                style: const TextStyle(
                    color: Color(0xFF8A94A6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

BoxDecoration _reportCardDecoration() => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: OySynAuthTokens.divider),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF142350).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
