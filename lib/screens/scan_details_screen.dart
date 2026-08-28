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
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh_rounded),
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
            const SizedBox(height: 13),
            const _ReportTabs(),
            const SizedBox(height: 13),
            _ReportModuleCard(
              icon: Icons.public_rounded,
              title: 'Интернет-модуль',
              primaryLabel: 'Оригинальность',
              primaryValue: report?.internetOriginality,
              secondaryLabel: 'Совпадения',
              secondaryValue: report?.internetPlagiarism,
            ),
            const SizedBox(height: 10),
            _ReportModuleCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Проверка ИИ-контента',
              primaryLabel: 'Человек',
              primaryValue: report?.humanWritten,
              secondaryLabel: 'ИИ-контент',
              secondaryValue: report?.aiGenerated,
              accent: const Color(0xFF6D4EF0),
            ),
            const SizedBox(height: 13),
            const _FullReportHint(),
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
  const _ReportTabs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ReportTab(label: 'Показатели', selected: true),
        SizedBox(width: 8),
        _ReportTab(label: 'Источники'),
        SizedBox(width: 8),
        _ReportTab(label: 'ИИ-текст'),
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

class _ReportModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String primaryLabel;
  final double? primaryValue;
  final String secondaryLabel;
  final double? secondaryValue;
  final Color accent;

  const _ReportModuleCard(
      {required this.icon,
      required this.title,
      required this.primaryLabel,
      required this.primaryValue,
      required this.secondaryLabel,
      required this.secondaryValue,
      this.accent = const Color(0xFF3972FE)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _reportCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700))),
          _CompactMetric(
              label: primaryLabel,
              value: primaryValue,
              color: const Color(0xFF148A4E)),
          const SizedBox(width: 12),
          _CompactMetric(
              label: secondaryLabel, value: secondaryValue, color: accent),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _CompactMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value == null ? '—' : '${value!.toStringAsFixed(1)}%',
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 9.5)),
      ],
    );
  }
}

class _FullReportHint extends StatelessWidget {
  const _FullReportHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _reportCardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.description_outlined, color: OySynAuthTokens.primaryBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Подробный список источников и размеченный текст доступны в полном PDF-отчёте.',
              style: TextStyle(
                  color: Color(0xFF5A6577), fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
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
