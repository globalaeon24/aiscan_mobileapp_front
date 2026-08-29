class AiFragment {
  final int start;
  final int end;
  final String? text;
  final double confidence;

  AiFragment({
    required this.start,
    required this.end,
    this.text,
    required this.confidence,
  });

  factory AiFragment.fromJson(Map<String, dynamic> json) {
    return AiFragment(
      start: json['start'],
      end: json['end'],
      text: json['text'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ScanResult {
  final int id;
  final String? title;
  final String? status;
  final String? statusDisplay;
  final String? documentType;

  // 🔥 МЕТАДАННЫЕ
  final int? userScanIndex;
  final String? fileName;
  final String? authorName;
  final String? department;
  final int? fileSize;
  final List<String> modules;

  // 🔥 ОСНОВНОЕ
  final double originalityPercentage;
  final double? aiPercentage;
  final String scannedText;
  final String? highlightedText;
  final DateTime createdAt;

  // 🔥 AI-ФРАГМЕНТЫ
  final List<AiFragment> aiFragments;

  ScanResult({
    required this.id,
    required this.originalityPercentage,
    this.aiPercentage,
    required this.scannedText,
    required this.highlightedText,
    required this.createdAt,
    required this.aiFragments,
    this.title,
    this.status,
    this.statusDisplay,
    this.documentType,
    this.userScanIndex,
    this.fileName,
    this.authorName,
    this.department,
    this.fileSize,
    this.modules = const [],
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final fragmentsJson = json['ai_fragments'] as List<dynamic>? ?? [];
    final createdAtValue = json['created_at'] ??
        json['submitted_at'] ??
        json['completed_at'] ??
        json['received_at'];

    return ScanResult(
      id: _asInt(json['id'] ?? json['core_check_id']),
      title: json['title']?.toString(),
      status: json['status']?.toString(),
      statusDisplay: json['status_display']?.toString(),
      documentType: json['document_type_display']?.toString() ??
          json['document_type']?.toString(),
      userScanIndex: _asNullableInt(json['user_scan_index']),
      fileName: (json['file_name'] ?? json['document_name'] ?? json['title'])
          ?.toString(),
      authorName: (json['author_name'] ?? json['author'])?.toString(),
      department: json['department']?.toString(),
      fileSize: _asNullableInt(json['file_size']),
      modules: (json['modules'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      originalityPercentage: _asDouble(
        json['originality_percentage'] ?? json['originality_percent'] ?? 0,
      ),
      aiPercentage: _asNullableDouble(
        json['ai_percentage'] ??
            json['ai_probability_percent'] ??
            json['ai_percent'] ??
            json['chatgpt_generated_percentage'],
      ),
      scannedText:
          json['scanned_text'] ?? json['text'] ?? json['summary'] ?? "",
      highlightedText: json['highlighted_text']?.toString(),
      createdAt: createdAtValue == null
          ? DateTime.now()
          : (DateTime.tryParse(createdAtValue.toString()) ?? DateTime.now()),
      aiFragments: fragmentsJson
          .map((e) => AiFragment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    return _asInt(value);
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    return _asDouble(value);
  }
}
