import 'package:ai_scan_text/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compares semantic versions by numeric components', () {
    expect(AppUpdateInfo.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(AppUpdateInfo.compareVersions('1.0', '1.0.0'), 0);
    expect(AppUpdateInfo.compareVersions('2.0.0', '2.0.1'), lessThan(0));
  });

  test('uses build number when release version is unchanged', () {
    final update = AppUpdateInfo.fromJson({
      'enabled': true,
      'latest_version': '1.0.8',
      'latest_build': 10,
      'title': 'Обновление',
      'message': 'Доступна новая версия',
      'store_url': 'https://example.com/app',
    });

    expect(update.isNewerThan('1.0.8', 9), isTrue);
    expect(update.isNewerThan('1.0.8', 10), isFalse);
  });
}
