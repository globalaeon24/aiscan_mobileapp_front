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
