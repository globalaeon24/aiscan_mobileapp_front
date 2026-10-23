class CheckReport {
  final int id;
  final double originality;
  final double plagiarism;
  final double citation;
  final double selfCitation;
  final double internetOriginality;
  final double internetPlagiarism;
  final double humanWritten;
  final double aiGenerated;
  final int uniqueness;
  final List<ReportSource> sources;
  final List<ReportFraud> fraud;
  final String documentText;
  final List<String> aiDetectedTexts;

  const CheckReport({
    required this.id,
    required this.originality,
    required this.plagiarism,
    required this.citation,
    required this.selfCitation,
    required this.internetOriginality,
    required this.internetPlagiarism,
    required this.humanWritten,
    required this.aiGenerated,
    required this.uniqueness,
    this.sources = const [],
    this.fraud = const [],
    this.documentText = '',
    this.aiDetectedTexts = const [],
  });

  factory CheckReport.fromJson(Map<String, dynamic> json) {
    return CheckReport(
      id: _integer(json['id']),
      originality: _number(json['originality_percentage']),
      plagiarism: _number(json['plagiarism_percentage']),
      citation: _number(json['citation_percentage']),
      selfCitation: _number(json['selfcitation_percentage']),
      internetOriginality: _number(json['internet_originality_percentage']),
      internetPlagiarism: _number(json['internet_plagiarism_percentage']),
      humanWritten: _number(json['human_written_percentage']),
      aiGenerated: _number(json['chatgpt_generated_percentage']),
      uniqueness: _integer(json['uniqueness']),
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .map((item) => ReportSource.fromJson(item as Map<String, dynamic>))
          .toList(),
      fraud: (json['fraud'] as List<dynamic>? ?? const [])
          .map((item) => ReportFraud.fromJson(item as Map<String, dynamic>))
          .toList(),
      documentText: json['document_text']?.toString() ?? '',
      aiDetectedTexts: (json['ai_detected_texts'] as List<dynamic>? ?? const [])
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['text']?.toString() ?? '';
            }
            return item?.toString() ?? '';
          })
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReportSource {
  final String id;
  final String name;
  final String? url;
  final String? moduleName;
  final String moduleLabel;
  final double scoreSource;
  final double scoreReport;
  final bool active;
  final int? type;

  const ReportSource({
    required this.id,
    required this.name,
    this.url,
    this.moduleName,
    required this.moduleLabel,
    required this.scoreSource,
    required this.scoreReport,
    required this.active,
    this.type,
  });

  factory ReportSource.fromJson(Map<String, dynamic> json) => ReportSource(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Источник',
        url: json['url']?.toString(),
        moduleName: json['module_name']?.toString(),
        moduleLabel: json['module_label']?.toString() ?? 'Источник',
        scoreSource: CheckReport._number(json['score_source']),
        scoreReport: CheckReport._number(json['score_report']),
        active: json['active'] != false,
        type: json['type'] is num ? (json['type'] as num).toInt() : null,
      );
}

class ReportFraud {
  final String type;
  final String label;
  final int count;

  const ReportFraud(
      {required this.type, required this.label, required this.count});

  factory ReportFraud.fromJson(Map<String, dynamic> json) => ReportFraud(
        type: json['type']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Подозрительная активность',
        count: CheckReport._integer(json['count']),
      );
}
