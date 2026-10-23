import 'dart:convert';

import 'package:ai_scan_text/services/security_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('PIN is stored as a salted slow hash', () async {
    await SecurityService.savePin('1234');

    final storage = const FlutterSecureStorage();
    final hash = await storage.read(key: 'security_pin_hash');
    final salt = await storage.read(key: 'security_pin_salt');

    expect(hash, isNotNull);
    expect(hash, isNot(contains('1234')));
    expect(salt, isNotNull);
    expect(await SecurityService.verifyPin('1234'), isTrue);
    expect(await SecurityService.verifyPin('4321'), isFalse);
  });

  test('legacy PIN hash is upgraded after successful verification', () async {
    const salt = 'legacy-salt';
    final legacyHash = sha256.convert(utf8.encode('$salt:1234')).toString();
    FlutterSecureStorage.setMockInitialValues({
      'security_pin_salt': salt,
      'security_pin_hash': legacyHash,
    });

    expect(await SecurityService.verifyPin('1234'), isTrue);
    expect(
      await const FlutterSecureStorage().read(key: 'security_pin_algorithm'),
      'pbkdf2-sha256-v1',
    );
  });
}
