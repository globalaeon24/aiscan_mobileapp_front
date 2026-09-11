import 'package:ai_scan_text/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('development builds use Stage by default', () {
    expect(ApiConfig.environment, 'stage');
    expect(ApiConfig.isStage, isTrue);
    expect(ApiConfig.isProduction, isFalse);
    expect(ApiConfig.baseUrl, ApiConfig.stageBaseUrl);
  });
}
