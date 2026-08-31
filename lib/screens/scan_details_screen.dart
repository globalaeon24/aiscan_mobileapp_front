import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  int _reportTab = 0;

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
            tooltip: 'Обновить отчёт',
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
            if (report != null && report.fraud.isNotEmpty) ...[
              const SizedBox(height: 13),
              _FraudBanner(items: report.fraud),
            ],
            const SizedBox(height: 13),
            _ReportTabs(
              sourceCount:
                  report?.sources.where((item) => item.active).length ?? 0,
              selected: _reportTab,
              onChanged: (value) => setState(() => _reportTab = value),
            ),
            const SizedBox(height: 13),
            if (_reportTab == 0 && report != null && report.sources.isNotEmpty)
              for (final source
                  in report.sources.where((item) => item.active)) ...[
                _ReportSourceCard(source: source),
                const SizedBox(height: 10),
              ]
            else if (_reportTab == 0 && !_loading)
              const _InfoBanner(message: 'Источники совпадений не обнаружены.'),
            if (_reportTab == 1 && !_loading)
              _ReportTextCard(
                title: 'Текст документа',
                text: report?.documentText ?? '',
                emptyMessage: 'Текст документа пока не передан из Core.',
              ),
            if (_reportTab == 2 && !_loading)
              _AiTextCard(
                fragments: report?.aiDetectedTexts ?? const [],
                percentage: report?.aiGenerated ?? 0,
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
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
    final plagiarism = report?.plagiarism ?? 0;
    final citation = report?.citation ?? 0;
    final selfCitation = report?.selfCitation ?? 0;
    final aiGenerated = report?.aiGenerated ?? detail.aiPercentage ?? 0;
    final reportedHuman = report?.humanWritten;
    final humanWritten =
        reportedHuman != null && reportedHuman + aiGenerated > 0
            ? reportedHuman
            : (100 - aiGenerated).clamp(0, 100);
    const originalityColor = Color(0xFF22A45D);
    const plagiarismColor = Color(0xFFE75555);
    const citationColor = Color(0xFF71809E);
    const selfCitationColor = Color(0xFFF0A22E);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _reportCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 118,
                child: CustomPaint(
                  painter: _SegmentedReportRingPainter(
                    segments: [
                      (originality, originalityColor),
                      (plagiarism, plagiarismColor),
                      (citation, citationColor),
                      (selfCitation, selfCitationColor),
                    ],
                  ),
                  child: Center(
                    child: Column(
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
                          style: TextStyle(
                            color: Color(0xFF8A94A6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _MetricRow(
                      label: 'Оригинальность',
                      value: originality,
                      color: originalityColor,
                    ),
                    _MetricRow(
                      label: 'Совпадения',
                      value: plagiarism,
                      color: plagiarismColor,
                    ),
                    _MetricRow(
                      label: 'Цитирования',
                      value: citation,
                      color: citationColor,
                    ),
                    _MetricRow(
                      label: 'Самоцитирования',
                      value: selfCitation,
                      color: selfCitationColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ИИ-контент',
                  style: TextStyle(color: Color(0xFF46506A), fontSize: 12.5),
                ),
              ),
              Text(
                '${aiGenerated.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Color(0xFF6D4EF0),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  if (aiGenerated > 0)
                    Expanded(
                      flex: math.max(1, (aiGenerated * 10).round()),
                      child: const ColoredBox(color: Color(0xFF7454F5)),
                    ),
                  if (humanWritten > 0)
                    Expanded(
                      flex: math.max(1, (humanWritten * 10).round()),
                      child: const ColoredBox(color: Color(0xFFDDE4F3)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const _LegendDot(color: Color(0xFF7454F5)),
              const SizedBox(width: 5),
              const Text('ИИ',
                  style: TextStyle(color: Color(0xFF6D4EF0), fontSize: 11.5)),
              const Spacer(),
              const _LegendDot(color: Color(0xFFDDE4F3)),
              const SizedBox(width: 5),
              Text(
                'Текст человека ${humanWritten.toStringAsFixed(2)}%',
                style:
                    const TextStyle(color: Color(0xFF71809E), fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedReportRingPainter extends CustomPainter {
  final List<(double, Color)> segments;

  const _SegmentedReportRingPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    const width = 11.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(width / 2);
    final background = Paint()
      ..color = const Color(0xFFEEF1F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, background);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final value = segment.$1.clamp(0, 100);
      if (value <= 0) continue;
      final sweep = math.pi * 2 * value / 100;
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedReportRingPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
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
          _LegendDot(color: color),
          const SizedBox(width: 7),
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
  final int selected;
  final ValueChanged<int> onChanged;

  const _ReportTabs({
    required this.sourceCount,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReportTab(
            label: 'Источники · $sourceCount',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ReportTab(
            label: 'Текст',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ReportTab(
            label: 'ИИ-текст',
            selected: selected == 2,
            onTap: () => onChanged(2),
          ),
        ),
      ],
    );
  }
}

class _ReportTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? OySynAuthTokens.primaryBlue : Colors.white,
          border: Border.all(
              color: selected
                  ? OySynAuthTokens.primaryBlue
                  : OySynAuthTokens.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5A6577),
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReportTextCard extends StatelessWidget {
  final String title;
  final String text;
  final String emptyMessage;

  const _ReportTextCard({
    required this.title,
    required this.text,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final value = text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _reportCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: OySynAuthTokens.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SelectableText(
            value.isEmpty ? emptyMessage : value,
            style: TextStyle(
              color: value.isEmpty
                  ? OySynAuthTokens.textMuted
                  : OySynAuthTokens.textDark,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiTextCard extends StatelessWidget {
  final List<String> fragments;
  final double percentage;

  const _AiTextCard({required this.fragments, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _reportCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Фрагменты с признаками ИИ',
                    style: TextStyle(
                        color: OySynAuthTokens.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF7148E8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fragments.isEmpty)
            const Text(
              'ИИ-фрагменты не обнаружены или пока не переданы из Core.',
              style: TextStyle(color: OySynAuthTokens.textMuted, height: 1.4),
            )
          else
            for (var i = 0; i < fragments.length; i++) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FF),
                  border: Border.all(color: const Color(0xFFE1D5FF)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: SelectableText(
                  fragments[i],
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
              if (i != fragments.length - 1) const SizedBox(height: 9),
            ],
        ],
      ),
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
