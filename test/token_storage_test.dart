import 'package:ai_scan_text/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.userListenable.value = null;
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
