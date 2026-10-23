import 'package:ai_scan_text/storage/token_storage.dart';
import 'package:ai_scan_text/models/scan_result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    TokenStorage.userListenable.value = null;
  });

  test('legacy access token migrates out of shared preferences', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'legacy-token'});

    expect(await TokenStorage.getToken(), 'legacy-token');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('access_token'), isFalse);
    expect(
      await const FlutterSecureStorage().read(key: 'access_token'),
      'legacy-token',
    );
  });

  test('cached history excludes document text', () async {
    await TokenStorage.saveHistory([
      ScanResult(
        id: 1,
        originalityPercentage: 80,
        scannedText: 'sensitive full text',
        highlightedText: 'sensitive highlighted text',
        createdAt: DateTime.utc(2026),
        aiFragments: const [],
      ),
    ]);

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_check_history') ?? '';
    expect(cached, isNot(contains('sensitive')));
  });

  test('saving profile immediately publishes name and balance changes',
      () async {
    var notifications = 0;
    void listener() => notifications++;

    TokenStorage.userListenable.addListener(listener);
    addTearDown(() => TokenStorage.userListenable.removeListener(listener));

    await TokenStorage.saveUser({
      'full_name': 'Новый Пользователь',
      'checks_available': 17,
    });

    expect(notifications, 1);
    expect(
      TokenStorage.userListenable.value,
      containsPair('full_name', 'Новый Пользователь'),
    );
    expect(
      TokenStorage.userListenable.value,
      containsPair('checks_available', 17),
    );
  });
}
