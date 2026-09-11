import 'package:ai_scan_text/models/check_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the Stage Core report metrics', () {
    final report = CheckReport.fromJson({
      'id': 6779,
      'originality_percentage': 81.25,
      'plagiarism_percentage': 12.5,
      'citation_percentage': 4.75,
      'selfcitation_percentage': 1.5,
      'internet_originality_percentage': 78.0,
      'internet_plagiarism_percentage': 22.0,
      'human_written_percentage': 63.25,
      'chatgpt_generated_percentage': 36.75,
      'uniqueness': 1,
      'sources': [
        {
          'id': 41,
          'name': 'Test Organization',
          'module_label': 'univers',
          'score_source': 12.5,
          'score_report': 10.56,
          'active': true,
        },
      ],
      'fraud': [
        {
          'type': 'character_replacement',
          'label': 'Замена символов',
          'count': 2
        },
      ],
      'document_text': 'Проверяемый текст',
      'ai_detected_texts': [
        {'text': 'Фрагмент с признаками ИИ'},
      ],
    });

    expect(report.id, 6779);
    expect(report.originality, 81.25);
    expect(report.plagiarism, 12.5);
    expect(report.citation, 4.75);
    expect(report.selfCitation, 1.5);
    expect(report.humanWritten, 63.25);
    expect(report.aiGenerated, 36.75);
    expect(report.sources.single.scoreReport, 10.56);
    expect(report.fraud.single.count, 2);
    expect(report.aiDetectedTexts.single, 'Фрагмент с признаками ИИ');
  });
}
