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

  // 🔥 МЕТАДАННЫЕ
  final int? userScanIndex;
  final String? fileName;
  final String? authorName;

  // 🔥 ОСНОВНОЕ
  final double aiPercentage;
  final String scannedText;
  final String? highlightedText;
  final DateTime createdAt;

  // 🔥 AI-ФРАГМЕНТЫ
  final List<AiFragment> aiFragments;

  ScanResult({
    required this.id,
    required this.aiPercentage,
    required this.scannedText,
    required this.highlightedText,
    required this.createdAt,
    required this.aiFragments,
    this.userScanIndex,
    this.fileName,
    this.authorName,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final fragmentsJson = json['ai_fragments'] as List<dynamic>? ?? [];

    return ScanResult(
      id: json['id'],
      userScanIndex: json['user_scan_index'],
      fileName: json['file_name'],
      authorName: json['author_name'],
      aiPercentage: (json['ai_percentage'] as num).toDouble(),
      scannedText: json['scanned_text'] ?? "",
      highlightedText: json['highlighted_text'],
      createdAt: DateTime.parse(json['created_at']),
      aiFragments: fragmentsJson
          .map((e) => AiFragment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}